// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: fetch-meta
// Scrapes Open Graph / Twitter / oEmbed metadata for a given URL, for a
// signed-in user. Only public hosts are fetched (see _shared/guard.ts).
//
// Deploy: supabase functions deploy fetch-meta

import { requestUser } from "../_shared/auth.ts";
import { readText, safeFetch, UnsafeUrl } from "../_shared/guard.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36";

interface Meta {
  url: string;
  title: string | null;
  description: string | null;
  image: string | null;
  siteName: string | null;
  sourceType: string;
}

function detectSource(u: string): string {
  const l = u.toLowerCase();
  if (l.includes("youtube.com") || l.includes("youtu.be")) return "youtube";
  if (l.includes("tiktok.com")) return "tiktok";
  if (l.includes("instagram.com")) return "instagram";
  if (l.includes("twitter.com") || l.includes("x.com")) return "x";
  return "article";
}

function pickMeta(html: string, names: string[]): string | null {
  for (const name of names) {
    // <meta property="og:title" content="..."> or name="..."
    const re = new RegExp(
      `<meta[^>]+(?:property|name)=["']${name}["'][^>]+content=["']([^"']+)["']`,
      "i",
    );
    const m = html.match(re);
    if (m) return decodeEntities(m[1]);
    const re2 = new RegExp(
      `<meta[^>]+content=["']([^"']+)["'][^>]+(?:property|name)=["']${name}["']`,
      "i",
    );
    const m2 = html.match(re2);
    if (m2) return decodeEntities(m2[1]);
  }
  return null;
}

function pickTitle(html: string): string | null {
  const m = html.match(/<title[^>]*>([^<]+)<\/title>/i);
  return m ? decodeEntities(m[1]).trim() : null;
}

function decodeEntities(s: string): string {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, " ");
}

/// Microlink.io — free OG scraper that handles sites which block direct
/// requests (Instagram, TikTok, X, etc). Free tier: 50 req/day without key.
async function fetchViaMicrolink(url: string): Promise<Meta | null> {
  try {
    const apiUrl =
      `https://api.microlink.io/?url=${encodeURIComponent(url)}&audio=false&video=false`;
    const r = await fetch(apiUrl, { headers: { "User-Agent": UA } });
    if (!r.ok) {
      console.log(`microlink: status ${r.status} for ${url}`);
      return null;
    }
    const j = await r.json();
    if (j.status !== "success" || !j.data) {
      console.log(`microlink: status=${j.status} for ${url}`);
      return null;
    }
    const d = j.data;
    return {
      url,
      title: d.title ?? null,
      description: d.description ?? null,
      image: d.image?.url ?? d.logo?.url ?? null,
      siteName: d.publisher ?? null,
      sourceType: detectSource(url),
    };
  } catch (e) {
    console.log(`microlink error: ${e}`);
    return null;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    if (!(await requestUser(req))) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { url } = await req.json();
    if (!url || typeof url !== "string" || !url.startsWith("http")) {
      return new Response(JSON.stringify({ error: "Invalid url" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const sourceType = detectSource(url);

    // Try oEmbed for YouTube (more reliable, gives thumbnail)
    if (sourceType === "youtube") {
      try {
        const oembedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`;
        const r = await fetch(oembedUrl, { headers: { "User-Agent": UA } });
        if (r.ok) {
          const j = await r.json();
          const meta: Meta = {
            url,
            title: j.title ?? null,
            description: j.author_name ? `by ${j.author_name}` : null,
            image: j.thumbnail_url ?? null,
            siteName: "YouTube",
            sourceType,
          };
          return new Response(JSON.stringify(meta), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      } catch (_) {/* fall through */}
    }

    // Sites that block direct scraping — go straight to Microlink.
    const blocksDirect = ["instagram", "tiktok", "x"].includes(sourceType);
    if (blocksDirect) {
      const m = await fetchViaMicrolink(url);
      if (m) {
        return new Response(JSON.stringify(m), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      // Microlink failed too — fall through to generic so we at least
      // return SOMETHING useful (title from a login page is better than nothing).
    }

    // Generic: fetch HTML and parse OG tags
    const r = await safeFetch(url, {
      headers: { "User-Agent": UA, Accept: "text/html" },
    });
    if (!r.ok) {
      // Last-ditch: try Microlink for non-2xx responses (e.g. 401, 403).
      const m = await fetchViaMicrolink(url);
      return new Response(JSON.stringify(m ?? { error: `Upstream ${r.status}` }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const html = await readText(r, 250_000);

    const meta: Meta = {
      url,
      title: pickMeta(html, ["og:title", "twitter:title"]) ?? pickTitle(html),
      description: pickMeta(html, ["og:description", "twitter:description", "description"]),
      image: pickMeta(html, ["og:image", "twitter:image"]),
      siteName: pickMeta(html, ["og:site_name"]),
      sourceType,
    };

    // If the direct scrape didn't yield an image, try Microlink as a
    // last-resort enrichment — many WAF-protected sites send OG-less HTML.
    if (!meta.image) {
      const mm = await fetchViaMicrolink(url);
      if (mm) {
        meta.image = meta.image ?? mm.image;
        meta.title = meta.title ?? mm.title;
        meta.description = meta.description ?? mm.description;
        meta.siteName = meta.siteName ?? mm.siteName;
      }
    }

    return new Response(JSON.stringify(meta), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const unsafe = e instanceof UnsafeUrl;
    if (!unsafe) console.error("[fetch-meta]", e);
    return new Response(JSON.stringify({ error: unsafe ? "URL not allowed" : "Fetch failed" }), {
      status: unsafe ? 400 : 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
