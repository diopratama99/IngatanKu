// @ts-nocheck — runs on Deno, not Node. IDE TS warnings are safe to ignore.
// Supabase Edge Function: auto-summarize
// Fetches the source content from a URL (article HTML, YouTube transcript, or
// OG-meta fallback) and streams an LLM-generated personal note summary back
// to the client via Server-Sent Events.
//
// Deploy: supabase functions deploy auto-summarize
// Secrets (shared with ask-brain — no extra setup needed):
//   supabase secrets set OPENAI_API_KEY=<key>
//   supabase secrets set OPENAI_BASE_URL=<your-router-url>/v1
//   supabase secrets set OPENAI_CHAT_MODEL=<model-name>

import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const _baseURL = Deno.env.get("OPENAI_BASE_URL");
const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY")!,
  ...(_baseURL ? { baseURL: _baseURL } : {}),
});

const CHAT_MODEL = Deno.env.get("OPENAI_CHAT_MODEL") ?? Deno.env.get("OPENAI_MODEL") ?? (() => { throw new Error("Missing OPENAI_CHAT_MODEL env var"); })();

// Spoof a desktop browser UA so news sites don't serve a paywall/cookie
// banner. Same UA as fetch-meta for consistency.
const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/124 Safari/537.36";

// Cap content sent to the LLM so a 50-paragraph article doesn't blow the
// prompt budget. ~8000 chars ≈ 2000 tokens — plenty for a 200-word summary.
const MAX_CONTENT_CHARS = 8000;

// ───────────────────────────────────────────────────────────────────
// Source detection
// ───────────────────────────────────────────────────────────────────
type SourceType =
  | "youtube"
  | "twitter"
  | "tiktok"
  | "instagram"
  | "article";

function detectSource(url: string): SourceType {
  const u = url.toLowerCase();
  if (u.includes("youtube.com") || u.includes("youtu.be")) return "youtube";
  if (u.includes("twitter.com") || u.includes("x.com")) return "twitter";
  if (u.includes("tiktok.com")) return "tiktok";
  if (u.includes("instagram.com")) return "instagram";
  return "article";
}

function getYoutubeVideoId(url: string): string | null {
  const patterns = [
    /youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/,
    /youtu\.be\/([a-zA-Z0-9_-]{11})/,
    /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/,
    /youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/,
  ];
  for (const p of patterns) {
    const m = url.match(p);
    if (m) return m[1];
  }
  return null;
}

// ───────────────────────────────────────────────────────────────────
// HTML helpers — pure regex, no DOM dependency.
// We deliberately avoid `linkedom`/`@mozilla/readability` because their
// Deno builds can break with esm.sh resolution issues. The stripped-down
// regex extractor is "good enough" for personal-scale notes.
// ───────────────────────────────────────────────────────────────────
function decodeEntities(s: string): string {
  return s
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&hellip;/g, "…")
    .replace(/&mdash;/g, "—")
    .replace(/&ndash;/g, "–")
    .replace(/&rsquo;/g, "'")
    .replace(/&lsquo;/g, "'")
    .replace(/&rdquo;/g, '"')
    .replace(/&ldquo;/g, '"')
    .replace(/&#x([0-9a-f]+);/gi, (_, hex) =>
      String.fromCodePoint(parseInt(hex, 16)),
    )
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(parseInt(dec, 10)));
}

function stripTags(html: string): string {
  // Drop everything that is not visible body content.
  const cleaned = html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, " ")
    .replace(/<svg[\s\S]*?<\/svg>/gi, " ")
    .replace(/<iframe[\s\S]*?<\/iframe>/gi, " ")
    .replace(/<nav[\s\S]*?<\/nav>/gi, " ")
    .replace(/<footer[\s\S]*?<\/footer>/gi, " ")
    .replace(/<aside[\s\S]*?<\/aside>/gi, " ")
    .replace(/<header[\s\S]*?<\/header>/gi, " ")
    .replace(/<form[\s\S]*?<\/form>/gi, " ");
  // Convert block-level closing tags to newlines so the LLM sees paragraph
  // structure instead of one giant run-on line.
  const blocked = cleaned.replace(/<\/(p|div|li|h[1-6]|br|tr)>/gi, "\n");
  // Drop remaining tags.
  const text = blocked.replace(/<[^>]+>/g, " ");
  return decodeEntities(text)
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

// ───────────────────────────────────────────────────────────────────
// Source-specific fetchers
// ───────────────────────────────────────────────────────────────────

/** Try the public timedtext endpoint, then fall back to scraping the watch
 * page for the captionTracks JSON — covers ~95% of YouTube videos that
 * have human or auto-generated captions. */
async function fetchYoutubeTranscript(videoId: string): Promise<string> {
  try {
    const pageRes = await fetch(`https://www.youtube.com/watch?v=${videoId}`, {
      headers: { "User-Agent": UA },
    });
    if (!pageRes.ok) return "";
    const html = await pageRes.text();

    // The watch page embeds a JSON blob with captionTracks. We capture it
    // greedily then fix the HTML-escaped ampersands inside `baseUrl` URLs.
    const tracksMatch = html.match(/"captionTracks":(\[[^\]]*\])/);
    if (!tracksMatch) return "";

    const tracksJson = tracksMatch[1]
      .replace(/\\u0026/g, "&")
      .replace(/\\\//g, "/");

    let tracks: Array<{ baseUrl?: string; languageCode?: string; kind?: string }>;
    try {
      tracks = JSON.parse(tracksJson);
    } catch {
      return "";
    }
    if (tracks.length === 0) return "";

    // Prefer Indonesian, then English, then ASR auto-caption, then anything.
    const id = tracks.find((t) => t.languageCode === "id");
    const en = tracks.find((t) => t.languageCode === "en");
    const auto = tracks.find((t) => t.kind === "asr");
    const track = id ?? en ?? auto ?? tracks[0];
    if (!track?.baseUrl) return "";

    const captionRes = await fetch(track.baseUrl, {
      headers: { "User-Agent": UA },
    });
    if (!captionRes.ok) return "";
    const captionXml = await captionRes.text();

    // Each <text start="..." dur="...">CAPTION</text> entry is one line.
    const matches = captionXml.matchAll(/<text[^>]*>([\s\S]*?)<\/text>/g);
    const lines: string[] = [];
    for (const m of matches) {
      const cleaned = decodeEntities(m[1])
        .replace(/<[^>]+>/g, " ")
        .replace(/\s+/g, " ")
        .trim();
      if (cleaned) lines.push(cleaned);
    }
    return lines.join(" ");
  } catch (e) {
    console.error("[auto-summarize] yt transcript error:", e);
    return "";
  }
}

/** Generic article extractor — pulls text from <article> or <main> when
 * present, falls back to the whole <body>. */
async function fetchArticle(url: string): Promise<string> {
  try {
    const res = await fetch(url, { headers: { "User-Agent": UA } });
    if (!res.ok) return "";
    const html = await res.text();

    // Try <article>, then <main>, then any element with role="main".
    const articleMatch = html.match(/<article[^>]*>([\s\S]*?)<\/article>/i);
    const mainMatch = html.match(/<main[^>]*>([\s\S]*?)<\/main>/i);
    const roleMatch = html.match(
      /<[^>]+role=["']main["'][^>]*>([\s\S]*?)<\/[^>]+>/i,
    );
    const body = articleMatch?.[1] ?? mainMatch?.[1] ?? roleMatch?.[1] ?? html;
    return stripTags(body);
  } catch (e) {
    console.error("[auto-summarize] article fetch error:", e);
    return "";
  }
}

/** Fetch og:title + og:description as a last-resort content source. Used
 * for X/Twitter, TikTok, and Instagram where we can't reliably scrape the
 * full caption/transcript. */
async function fetchOgMeta(url: string): Promise<string> {
  try {
    const res = await fetch(url, { headers: { "User-Agent": UA } });
    if (!res.ok) return "";
    const html = await res.text();

    const grab = (prop: string): string => {
      const m = html.match(
        new RegExp(
          `<meta[^>]+(?:property|name)=["']${prop}["'][^>]+content=["']([^"']+)["']`,
          "i",
        ),
      );
      return m?.[1] ? decodeEntities(m[1]) : "";
    };

    const title = grab("og:title") || grab("twitter:title");
    const desc = grab("og:description") || grab("twitter:description") ||
      grab("description");

    return [title, desc].filter(Boolean).join("\n\n").trim();
  } catch (e) {
    console.error("[auto-summarize] og fetch error:", e);
    return "";
  }
}

// ───────────────────────────────────────────────────────────────────
// Main handler
// ───────────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing auth" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { url, locale = "id" } = await req.json();
    if (!url || typeof url !== "string" || !url.startsWith("http")) {
      return new Response(JSON.stringify({ error: "Valid URL required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1) Detect source + fetch content with type-appropriate strategy.
    const source = detectSource(url);
    let content = "";
    let contentLabel = "";

    if (source === "youtube") {
      const videoId = getYoutubeVideoId(url);
      if (videoId) {
        content = await fetchYoutubeTranscript(videoId);
        contentLabel = "transkrip video YouTube";
      }
      // No transcript available → fall back to OG description.
      if (!content || content.length < 50) {
        content = await fetchOgMeta(url);
        contentLabel = "deskripsi video YouTube";
      }
    } else if (source === "article") {
      content = await fetchArticle(url);
      contentLabel = "isi artikel";
      if (!content || content.length < 200) {
        content = await fetchOgMeta(url);
        contentLabel = "deskripsi artikel";
      }
    } else {
      // X / TikTok / Instagram — caption/transcript scraping is unreliable
      // and platform-specific. We use OG meta as a deliberate floor.
      content = await fetchOgMeta(url);
      contentLabel = source === "twitter"
        ? "tweet"
        : source === "tiktok"
          ? "deskripsi TikTok"
          : "deskripsi Instagram";
    }

    if (!content || content.length < 50) {
      return new Response(
        JSON.stringify({
          error:
            "Konten tidak ditemukan. Coba isi catatan secara manual atau pakai mic.",
        }),
        {
          status: 422,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Clip to keep prompt manageable.
    if (content.length > MAX_CONTENT_CHARS) {
      content = content.substring(0, MAX_CONTENT_CHARS) + "…";
    }

    // 2) Build prompt. Locale switches the output language; the prompt
    //    itself stays in Bahasa Indonesia for consistency with ask-brain.
    const langName = locale === "en" ? "English" : "Bahasa Indonesia";
    const systemPrompt =
      `Kamu adalah asisten yang membantu user mencatat konten dari internet menjadi catatan personal yang berguna untuk dirinya sendiri.

ATURAN:
- Tulis dalam ${langName} yang santai dan natural.
- Format Markdown — pakai bullet points, **bold** untuk istilah penting, ## untuk sub-section kalau memang perlu.
- Maksimal 200 kata. Fokus pada insight, take-away, atau hal yang berguna untuk diingat — bukan rangkuman umum.
- Jangan tulis preamble seperti "Berikut adalah ringkasan…" — langsung ke isi catatan.
- Jangan sebut sumber atau URL — user sudah tahu mereka menyimpan dari mana.
- Kalau konten teknikal (kode, tools, framework), highlight nama tools/komponennya pakai bold.`;

    const userPrompt = `Berikut ${contentLabel} dari URL ${url}:

===
${content}
===

Tulis catatan personal Markdown yang berguna untuk user.`;

    // 3) Stream LLM response back as SSE.
    const completion = await openai.chat.completions.create({
      model: CHAT_MODEL,
      stream: true,
      temperature: 0.5,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
    });

    const encoder = new TextEncoder();
    const readable = new ReadableStream({
      async start(controller) {
        // Emit a `meta` event first so the client can show "transkrip
        // video YouTube ditemukan…" before any LLM token arrives.
        controller.enqueue(
          encoder.encode(
            `event: meta\ndata: ${JSON.stringify({
              source,
              contentLabel,
              contentLength: content.length,
            })}\n\n`,
          ),
        );

        try {
          for await (const chunk of completion) {
            const token = chunk.choices[0]?.delta?.content ?? "";
            if (token) {
              controller.enqueue(
                encoder.encode(`data: ${JSON.stringify({ token })}\n\n`),
              );
            }
          }
        } catch (e) {
          console.error("[auto-summarize] LLM stream error:", e);
          controller.enqueue(
            encoder.encode(
              `data: ${JSON.stringify({ error: `${e}` })}\n\n`,
            ),
          );
        }

        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify({ done: true })}\n\n`),
        );
        controller.close();
      },
    });

    return new Response(readable, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  } catch (e) {
    console.error("[auto-summarize] handler error:", e);
    return new Response(JSON.stringify({ error: `${e}` }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
