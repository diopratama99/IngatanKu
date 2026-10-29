// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: resolve-media
//
// Wraps a Cobalt instance (https://github.com/imputnet/cobalt) so that the
// Flutter client never has to know which one, and falls back to the page's
// og:image for plain photos Cobalt can't resolve (Instagram carousels of
// stills). The public api.cobalt.tools only serves its own website (it
// answers `error.api.auth.jwt.missing`), so point this at your own:
//
// Deploy: supabase functions deploy resolve-media
// Secrets:
//   supabase secrets set COBALT_API_BASE=https://<your cobalt instance>
//   supabase secrets set COBALT_API_KEY=<key>   # if the instance has API keys
//
// When the instance is down this answers 422 like any URL it can't resolve;
// nothing else in the app depends on it.
//
// Request body:  { "url": "<media URL>" }
// Response: {
//   "kind": "video" | "photo",
//   "downloadUrl": "<direct file URL>",
//   "filename": "<suggested filename>",
//   "ext": "mp4" | "jpg" | …
// }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { PUBLIC_KEY, SUPABASE_URL } from "../_shared/env.ts";
import { readText, safeFetch } from "../_shared/guard.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const COBALT_BASE =
  Deno.env.get("COBALT_API_BASE") ?? "https://api.cobalt.tools";
const COBALT_KEY = Deno.env.get("COBALT_API_KEY");
/** How long Cobalt gets before we give up on it (e.g. its server is down). */
const COBALT_TIMEOUT_MS = 20_000;

/** [url] with the scheme and host of COBALT_BASE. */
function onInstance(url: string): string {
  const u = new URL(url);
  const base = new URL(COBALT_BASE);
  u.protocol = base.protocol;
  u.host = base.host;
  return u.toString();
}

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
        ...(COBALT_KEY ? { Authorization: `Api-Key ${COBALT_KEY}` } : {}),
      },
      signal: AbortSignal.timeout(COBALT_TIMEOUT_MS),
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
      // A tunnel is served by the instance we asked, so it goes through the
      // address we reached it at — the one it names itself (its API_URL) may
      // be stale or unreachable.
      const downloadUrl = status === "tunnel"
        ? onInstance(json.url as string)
        : json.url as string;
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
    const res = await safeFetch(sourceUrl, {
      headers: { "User-Agent": UA },
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) return null;
    const html = await readText(res);
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

    const supabase = createClient(SUPABASE_URL, PUBLIC_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
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
    return new Response(JSON.stringify({ error: "Resolve failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
