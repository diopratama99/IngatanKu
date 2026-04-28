// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: resolve-media
//
// Wraps the public Cobalt API (https://github.com/imputnet/cobalt) so that
// the Flutter client never has to touch a third-party endpoint directly.
// Why server-side?
//   1. Cobalt's public instance occasionally rate-limits by IP — running it
//      from our edge gives every user a different egress IP.
//   2. We can fall back to OG-image scraping for plain photos if Cobalt
//      can't resolve the URL (common for Instagram carousels of stills).
//   3. We log failures for debugging without coupling clients to whichever
//      Cobalt host we currently point at.
//
// Deploy: supabase functions deploy resolve-media
// Optional secret (defaults to the public api.cobalt.tools instance):
//   supabase secrets set COBALT_API_BASE=https://api.cobalt.tools
//
// Request body:  { "url": "<media URL>" }
// Response: {
//   "kind": "video" | "photo",
//   "downloadUrl": "<direct file URL>",
//   "filename": "<suggested filename>",
//   "ext": "mp4" | "jpg" | …
// }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const COBALT_BASE =
  Deno.env.get("COBALT_API_BASE") ?? "https://api.cobalt.tools";

const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/124 Safari/537.36";

function extFromFilename(name: string | undefined, fallback: string): string {
  if (!name) return fallback;
  const m = name.match(/\.([a-z0-9]+)(?:$|[?#])/i);
  return m ? m[1].toLowerCase() : fallback;
}

function extFromUrl(url: string, fallback: string): string {
  try {
    const u = new URL(url);
    const m = u.pathname.match(/\.([a-z0-9]+)$/i);
    return m ? m[1].toLowerCase() : fallback;
  } catch {
    return fallback;
  }
}

/** Ask Cobalt to resolve [sourceUrl] into a direct media link. Returns null
 * if Cobalt declines, errors, or the response shape is unrecognised. */
async function resolveViaCobalt(
  sourceUrl: string,
): Promise<{
  kind: "video" | "photo";
  downloadUrl: string;
  filename?: string;
} | null> {
  try {
    const res = await fetch(`${COBALT_BASE}/`, {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": UA,
      },
      body: JSON.stringify({
        url: sourceUrl,
        videoQuality: "720",
        downloadMode: "auto",
      }),
    });

    if (!res.ok) {
      console.error("[resolve-media] cobalt non-200:", res.status);
      return null;
    }

    const json: any = await res.json();
    const status = json?.status;

    // tunnel = Cobalt streams it for us; redirect = direct link from origin.
    if (status === "tunnel" || status === "redirect") {
      const downloadUrl = json.url as string;
      const filename = json.filename as string | undefined;
      // Heuristic: if Cobalt set audio output, we still treat it as video
      // because the user's flow is "save the video/photo I shared".
      const ext = extFromFilename(filename, extFromUrl(downloadUrl, "mp4"));
      const kind: "video" | "photo" =
        ["jpg", "jpeg", "png", "webp", "gif"].includes(ext) ? "photo" : "video";
      return { kind, downloadUrl, filename };
    }

    // picker = multiple media items (carousel). Take the first one — the
    // user can re-share the link with a different anchor if they want a
    // specific slide later.
    if (status === "picker" && Array.isArray(json.picker) && json.picker.length) {
      const first = json.picker[0];
      const downloadUrl = first.url as string;
      const type = first.type as string | undefined;
      const ext = extFromUrl(downloadUrl, type === "photo" ? "jpg" : "mp4");
      const kind: "video" | "photo" = type === "photo" ? "photo" : "video";
      return { kind, downloadUrl };
    }

    console.error("[resolve-media] cobalt unhandled status:", status, json);
    return null;
  } catch (e) {
    console.error("[resolve-media] cobalt fetch error:", e);
    return null;
  }
}

/** Last-resort fallback for URLs Cobalt can't handle (typically static
 * articles or plain product pages). Scrapes <meta property="og:image">. */
async function resolveOgImage(
  sourceUrl: string,
): Promise<{ kind: "photo"; downloadUrl: string } | null> {
  try {
    const res = await fetch(sourceUrl, { headers: { "User-Agent": UA } });
    if (!res.ok) return null;
    const html = await res.text();
    const grab = (prop: string): string | null => {
      const m = html.match(
        new RegExp(
          `<meta[^>]+(?:property|name)=["']${prop}["'][^>]+content=["']([^"']+)["']`,
          "i",
        ),
      );
      return m?.[1] ?? null;
    };
    const url =
      grab("og:image:secure_url") ?? grab("og:image") ?? grab("twitter:image");
    if (!url) return null;
    return { kind: "photo", downloadUrl: url };
  } catch (e) {
    console.error("[resolve-media] og fallback error:", e);
    return null;
  }
}

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

    const { url } = await req.json();
    if (!url || typeof url !== "string" || !url.startsWith("http")) {
      return new Response(JSON.stringify({ error: "Valid URL required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Try Cobalt first, then OG image as a photo-only fallback.
    let result = await resolveViaCobalt(url);
    if (!result) {
      const og = await resolveOgImage(url);
      if (og) {
        result = {
          kind: og.kind,
          downloadUrl: og.downloadUrl,
        };
      }
    }

    if (!result) {
      return new Response(
        JSON.stringify({
          error:
            "Tidak ada media yang bisa di-download dari URL ini. Coba salin link langsung ke video/foto.",
        }),
        {
          status: 422,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const ext = extFromFilename(result.filename, extFromUrl(result.downloadUrl,
      result.kind === "photo" ? "jpg" : "mp4"));

    return new Response(
      JSON.stringify({
        kind: result.kind,
        downloadUrl: result.downloadUrl,
        filename: result.filename ?? null,
        ext,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    console.error("[resolve-media] handler error:", e);
    return new Response(JSON.stringify({ error: `${e}` }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
