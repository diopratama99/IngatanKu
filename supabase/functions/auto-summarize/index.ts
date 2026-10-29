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
import { CHAT_EXTRA } from "../_shared/ai.ts";
import { PUBLIC_KEY, SUPABASE_URL } from "../_shared/env.ts";
import { readText, safeFetch } from "../_shared/guard.ts";
import { takeQuota } from "../_shared/quota.ts";

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

// The model that writes the note, and a second one asked as well when the
// first is slow to start (whichever starts writing first is used). The
// fallback defaults to the chat model: asking the router twice still
// helps, since its next try lands on another account / model.
//   OPENAI_FALLBACK_MODEL=<model>   (optional, e.g. a fast, steady one;
//                                    ask-brain uses it too)
const SUMMARY_MODEL = CHAT_MODEL;
const SUMMARY_FALLBACK_MODEL = Deno.env.get("OPENAI_FALLBACK_MODEL") ??
  CHAT_MODEL;

// Free-tier models sometimes take a minute to say a word, sometimes 3
// seconds. After this long without a word the fallback is asked too…
// AI_HEDGE_AFTER_MS=0 turns it off (with a paid key, asking twice costs
// twice); a model that fails outright is still followed by the next one.
const HEDGE_AFTER_MS = Number(Deno.env.get("AI_HEDGE_AFTER_MS") ?? 8_000);
// …and after this long without a word from either, we give up (the app
// stops waiting at 75s).
const GIVE_UP_AFTER_MS = 45_000;

// Fetching the source shouldn't hold the note up for long either.
const FETCH_TIMEOUT_MS = 10_000;
const MICROLINK_TIMEOUT_MS = 12_000;

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
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
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
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
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

/** The tags the model put on the note's last line ("Tags: resep, ayam"),
 * or null when [line] isn't that line. One-word tags only, at most four. */
function tagsFrom(line: string): string[] | null {
  const m = line.trim().match(/^[*_>#\s-]*tags?[*_\s]*:[*_\s]*(.*)$/i);
  if (!m) return null;
  return m[1]
    .split(",")
    .map((t) => t.replace(/[#*_`.]/g, "").trim().toLowerCase())
    .filter((t) => t.length > 0 && t.length <= 24 && !/\s/.test(t))
    .slice(0, 4);
}

/** YouTube's own blurb, which it serves instead of the video's page when
 * it turns a server away. */
function isYoutubeBlurb(text: string): boolean {
  return /Enjoy the videos and music you love|Nikmati video dan musik yang Anda sukai/i
    .test(text);
}

/** The video's title and channel from YouTube's oEmbed endpoint, which
 * answers servers that the watch page turns away. */
async function fetchYoutubeOembed(
  videoId: string | null,
  url: string,
): Promise<string> {
  try {
    const page = videoId ? `https://www.youtube.com/watch?v=${videoId}` : url;
    const res = await fetch(
      `https://www.youtube.com/oembed?format=json&url=${encodeURIComponent(page)}`,
      {
        headers: { "User-Agent": UA },
        signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
      },
    );
    if (!res.ok) return "";
    // deno-lint-ignore no-explicit-any
    const d: any = await res.json();
    const title = typeof d?.title === "string" ? d.title : "";
    const author = typeof d?.author_name === "string" ? `by ${d.author_name}` : "";
    return [title, author].filter(Boolean).join("\n\n").trim();
  } catch (e) {
    console.error("[auto-summarize] yt oembed error:", e);
    return "";
  }
}

/** Generic article extractor — pulls text from <article> or <main> when
 * present, falls back to the whole <body>. */
async function fetchArticle(url: string): Promise<string> {
  try {
    const res = await safeFetch(url, {
      headers: { "User-Agent": UA },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    });
    if (!res.ok) return "";
    const html = await readText(res);

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
    const res = await safeFetch(url, {
      headers: { "User-Agent": UA },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    });
    if (!res.ok) return "";
    const html = await readText(res);

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

/** Microlink.io fallback for sites that don't embed OG tags in their
 * server-rendered HTML (Instagram, TikTok, X — all SPAs). The free tier
 * gives us 50 req/day per IP without a key, which is plenty for our
 * personal-scale usage. We use this BEFORE falling back to direct OG
 * scrape because IG/X/TikTok now serve a JS-only shell and the OG meta
 * tags simply aren't present in the raw HTML.
 *
 * Returns the same `title\n\ndescription` shape as fetchOgMeta so the
 * downstream LLM prompt logic doesn't need to branch.
 */
async function fetchViaMicrolink(url: string): Promise<string> {
  try {
    const apiUrl =
      `https://api.microlink.io/?url=${encodeURIComponent(url)}` +
      `&audio=false&video=false`;
    const res = await fetch(apiUrl, {
      headers: { "User-Agent": UA },
      signal: AbortSignal.timeout(MICROLINK_TIMEOUT_MS),
    });
    if (!res.ok) {
      console.error("[auto-summarize] microlink non-200:", res.status);
      return "";
    }
    const json: any = await res.json();
    if (json?.status !== "success" || !json.data) {
      console.error(
        "[auto-summarize] microlink unhappy status:",
        json?.status,
      );
      return "";
    }
    const d = json.data;
    const title = (d.title as string | null) ?? "";
    const desc = (d.description as string | null) ?? "";
    const author = (d.author as string | null) ?? "";
    // Author tagline (e.g. "by dewakoding") only adds value when there's
    // no description. IG description already includes the @handle.
    const tail = !desc && author ? `by ${author}` : "";
    return [title, desc, tail]
      .filter(Boolean)
      .join("\n\n")
      .trim();
  } catch (e) {
    console.error("[auto-summarize] microlink error:", e);
    return "";
  }
}

// ───────────────────────────────────────────────────────────────────
// Getting the note written, by whichever model starts first
// ───────────────────────────────────────────────────────────────────
type Message = { role: "system" | "user"; content: string };

/** A model that has started writing: its first words, and the rest. */
type Writing = {
  model: string;
  first: string;
  rest: AsyncIterator<any>;
  stop: () => void;
};

/** Asks [model] for the note; resolves once it has written something. */
function ask(model: string, messages: Message[]) {
  const ctrl = new AbortController();
  const started = (async (): Promise<Writing> => {
    const stream = await openai.chat.completions.create(
      { model, stream: true, temperature: 0.5, messages, ...CHAT_EXTRA },
      { signal: ctrl.signal },
    );
    const rest = stream[Symbol.asyncIterator]();
    for (;;) {
      const r = await rest.next();
      if (r.done) throw new Error(`${model}: empty reply`);
      const first = r.value.choices?.[0]?.delta?.content ?? "";
      if (first) return { model, first, rest, stop: () => ctrl.abort() };
    }
  })();
  return { ctrl, started };
}

/** The summary model, with the fallback asked as well if it hasn't
 * started writing within HEDGE_AFTER_MS (or failed). The first to start
 * writing is used; the other is stopped. [onAbort] registers a way to
 * stop them all (the user left). */
async function firstToWrite(
  messages: Message[],
  onAbort: (stop: () => void) => void,
): Promise<Writing> {
  const models = [SUMMARY_MODEL, SUMMARY_FALLBACK_MODEL];
  const asked: AbortController[] = [];
  const pending = new Map<
    number,
    Promise<{ i: number; writing?: Writing; error?: unknown }>
  >();
  const askNext = () => {
    const i = asked.length;
    const { ctrl, started } = ask(models[i], messages);
    asked.push(ctrl);
    pending.set(
      i,
      started.then((writing) => ({ i, writing }), (error) => ({ i, error })),
    );
  };
  const stopAll = (except?: number) =>
    asked.forEach((c, j) => j !== except && c.abort());
  let cancelled = false;
  onAbort(() => {
    cancelled = true;
    stopAll();
  });

  let giveUp: number | undefined;
  const gaveUp = new Promise<"give-up">((resolve) => {
    giveUp = setTimeout(() => resolve("give-up"), GIVE_UP_AFTER_MS);
  });
  let lastError: unknown = new Error("no reply");
  try {
    askNext();
    while (pending.size > 0) {
      const canHedge = HEDGE_AFTER_MS > 0 && asked.length < models.length;
      let hedge: number | undefined;
      const hedged = canHedge
        ? new Promise<"hedge">((resolve) => {
          hedge = setTimeout(() => resolve("hedge"), HEDGE_AFTER_MS);
        })
        : null;
      const out = await Promise.race([
        ...pending.values(),
        gaveUp,
        ...(hedged ? [hedged] : []),
      ]);
      clearTimeout(hedge);
      if (out === "give-up" || cancelled) break;
      if (out === "hedge") {
        console.log(`[auto-summarize] ${models[0]} slow, asking ${models[1]}`);
        askNext();
        continue;
      }
      pending.delete(out.i);
      if (out.writing) {
        stopAll(out.i);
        return out.writing;
      }
      lastError = out.error;
      console.error(`[auto-summarize] ${models[out.i]} failed:`, out.error);
      // Failed straight away: no point waiting to ask the next one.
      if (pending.size === 0 && asked.length < models.length) askNext();
    }
  } finally {
    clearTimeout(giveUp);
  }
  stopAll();
  throw pending.size > 0
    ? new Error(`No reply after ${GIVE_UP_AFTER_MS / 1000}s`)
    : lastError;
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

    const supabase = createClient(SUPABASE_URL, PUBLIC_KEY, {
      db: { schema: "ingatanku" },
      global: { headers: { Authorization: authHeader } },
    });

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
    // What was found, said in the app's language ("Found the article…").
    const say = (en: string, id: string) => (locale === "en" ? en : id);

    if (source === "youtube") {
      const videoId = getYoutubeVideoId(url);
      if (videoId) {
        content = await fetchYoutubeTranscript(videoId);
        contentLabel = say("YouTube transcript", "transkrip video YouTube");
      }
      // No transcript available → fall back to OG description.
      if (!content || content.length < 50) {
        content = await fetchOgMeta(url);
        contentLabel = say("YouTube description", "deskripsi video YouTube");
        if (isYoutubeBlurb(content)) content = "";
      }
      // YouTube often shows servers a bot check instead of the page; these
      // two read the video's details from elsewhere.
      if (!content || content.length < 50) {
        // Microlink knows watch pages, not /shorts/ ones.
        content = await fetchViaMicrolink(
          videoId ? `https://www.youtube.com/watch?v=${videoId}` : url,
        );
        if (isYoutubeBlurb(content)) content = "";
      }
      if (!content || content.length < 50) {
        content = await fetchYoutubeOembed(videoId, url);
      }
    } else if (source === "article") {
      content = await fetchArticle(url);
      contentLabel = say("article", "isi artikel");
      if (!content || content.length < 200) {
        content = await fetchOgMeta(url);
        contentLabel = say("article's summary", "deskripsi artikel");
      }
    } else {
      // X / TikTok / Instagram — these are JS-rendered SPAs that don't
      // embed OG tags in their server-rendered HTML, so a direct fetch
      // returns an empty shell. We route through Microlink.io (same
      // strategy as the fetch-meta function powering preview cards),
      // which renders the page server-side and returns clean title +
      // description. Falls back to direct OG scrape on the off-chance
      // Microlink hits its free-tier daily limit.
      content = await fetchViaMicrolink(url);
      if (!content || content.length < 50) {
        content = await fetchOgMeta(url);
      }
      contentLabel = source === "twitter"
        ? say("post", "tweet")
        : source === "tiktok"
          ? say("TikTok caption", "deskripsi TikTok")
          : say("Instagram caption", "deskripsi Instagram");
    }

    // A video's own title is enough to go on, however short (Shorts often
    // have little more than that).
    const enough = source === "youtube" ? 10 : 50;
    if (!content || content.length < enough) {
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

    if (!(await takeQuota(supabase, "summarize"))) {
      return new Response(
        JSON.stringify({
          error: locale === "en"
            ? "That's all the write-ups for today. Fill in the note yourself, or try again tomorrow."
            : "Jatah ringkasan hari ini sudah habis. Isi catatannya sendiri dulu, atau coba lagi besok.",
          code: "quota",
        }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Clip to keep prompt manageable.
    if (content.length > MAX_CONTENT_CHARS) {
      content = content.substring(0, MAX_CONTENT_CHARS) + "…";
    }

    // 2) Build prompt — locale switches both the rule language AND
    //    the output language so the LLM stays in one register and
    //    doesn't codeswitch (which it tends to when the rules are ID
    //    but the output is supposed to be EN).
    const isEn = locale === "en";
    const systemPrompt = isEn
      ? `You help the user save internet content as a useful personal note for their own future reference.

RULES:
- FIRST line MUST be a Markdown H1 title that summarises the core topic of the content in 4-8 words. No fluff like "Notes on" or "Summary of". Examples of good titles: "Easy garlic butter chicken recipe", "Saving tips for monthly groceries", "3 days in Kyoto on a budget". Do not include the source platform (Instagram, YouTube, etc).
- After the title, leave one blank line, then write the rest of the note.
- Body uses Markdown. Bullet points, **bold** for key terms, ## for subsections only if truly needed.
- Hard cap: 200 words for the body. Focus on insights, takeaways, or things worth remembering, not a generic summary.
- Skip preamble like "Here is a summary..." in the body. Go straight into useful content.
- Don't mention the source URL or platform name in the body.
- Shape the note to the kind of content. A recipe: ingredients, then the steps. A how-to: numbered steps. A place or trip: what it is, where, cost, tips. A product: what it is, the good and the bad. A story or opinion: the main points and why they matter.
- Bold the names of the key things (ingredients, places, products, tools, people).
- If there's little to go on (just a title or a short caption), still write the note from it: the title, then a line or two on what it is. Don't make up details that aren't there, and never apologise or say you can't make a note.
- Never use em dashes (—). Use commas, periods, or parentheses instead.
- End with one last line: \`Tags:\` and 2-4 short lowercase tags for the topic, one word each, comma separated (e.g. \`Tags: recipe, chicken, grilling\`).`
      : `Kamu adalah asisten yang membantu user mencatat konten dari internet menjadi catatan personal yang berguna untuk dirinya sendiri.

ATURAN:
- Baris PERTAMA WAJIB berupa judul Markdown H1 yang merangkum inti konten dalam 4-8 kata. Tidak perlu kata sampah seperti "Catatan tentang" atau "Ringkasan". Contoh judul yang baik: "Resep ayam bawang mentega praktis", "Tips hemat belanja bulanan", "3 hari di Jogja dengan budget minim". Jangan sebut platform sumber (Instagram, YouTube, dll).
- Setelah judul, kasih satu baris kosong, baru tulis isi catatan.
- Format isi: Markdown. Pakai bullet points, **bold** untuk istilah penting, ## untuk sub-section kalau memang perlu.
- Maksimal 200 kata untuk isi. Fokus pada insight, take-away, atau hal yang berguna untuk diingat, bukan rangkuman umum.
- Jangan tulis preamble seperti "Berikut adalah ringkasan…" di body. Langsung ke isi yang berguna.
- Jangan sebut URL sumber atau nama platform di body. User sudah tahu mereka menyimpan dari mana.
- Sesuaikan bentuk catatan dengan jenis kontennya. Resep: bahan, lalu langkah. Cara/tutorial: langkah bernomor. Tempat atau perjalanan: apa, di mana, biaya, tips. Produk: apa itu, kelebihan dan kekurangan. Cerita atau opini: poin utama dan kenapa penting.
- Bold nama hal-hal penting (bahan, tempat, produk, alat, orang).
- Kalau isinya sedikit (cuma judul atau caption pendek), tetap tulis catatannya dari situ: judul, lalu satu dua baris tentang apa isinya. Jangan mengarang detail yang tidak ada, dan jangan pernah minta maaf atau bilang tidak bisa membuat catatan.
- Jangan pakai em dash (—) di mana pun. Pakai koma, titik, atau tanda kurung biasa untuk memisah ide.
- Akhiri dengan satu baris terakhir: \`Tags:\` lalu 2-4 tag pendek huruf kecil tentang topiknya, satu kata per tag, dipisah koma (contoh: \`Tags: resep, ayam, bakar\`).`;

    // The user prompt template intentionally stays in the source
    // locale: we tell the LLM what kind of content this is using the
    // same labels regardless. The system prompt's language directive
    // takes precedence for output style.
    const userPrompt = isEn
      ? `Here is the ${contentLabel} from ${url}:

===
${content}
===

Write a personal Markdown note that's useful to the user.`
      : `Berikut ${contentLabel} dari URL ${url}:

===
${content}
===

Tulis catatan personal Markdown yang berguna untuk user.`;

    // 3) Stream the note back as SSE. The response starts straight away
    //    (the client hears what was found while the model gets going).
    const messages: Message[] = [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt },
    ];
    const encoder = new TextEncoder();
    let stop = () => {};
    let closed = false;
    const readable = new ReadableStream({
      async start(controller) {
        // False once the client has gone.
        const send = (chunk: string): boolean => {
          if (closed) return false;
          try {
            controller.enqueue(encoder.encode(chunk));
            return true;
          } catch {
            closed = true;
            stop();
            return false;
          }
        };
        const data = (obj: unknown) => send(`data: ${JSON.stringify(obj)}\n\n`);

        // A `meta` event first so the client can show "transkrip video
        // YouTube ditemukan…" before any LLM token arrives.
        send(
          `event: meta\ndata: ${JSON.stringify({
            source,
            contentLabel,
            contentLength: content.length,
          })}\n\n`,
        );

        try {
          const writing = await firstToWrite(messages, (s) => (stop = s));
          stop = writing.stop;
          if (writing.model !== SUMMARY_MODEL) {
            console.log(`[auto-summarize] written by ${writing.model}`);
          }
          // The note goes out a line at a time, so the tags line at its
          // end can be taken out and sent as a `tags` event instead (an
          // app that doesn't know the event just skips it).
          let line = "";
          let tags: string[] = [];
          const pass = (text: string): boolean => {
            line += text;
            for (let nl = line.indexOf("\n"); nl >= 0; nl = line.indexOf("\n")) {
              const whole = line.slice(0, nl + 1);
              line = line.slice(nl + 1);
              const picked = tagsFrom(whole);
              if (picked) tags = picked;
              else if (!data({ token: whole })) return false;
            }
            return true;
          };
          let open = pass(writing.first);
          while (open) {
            const r = await writing.rest.next();
            if (r.done) break;
            const token = r.value.choices?.[0]?.delta?.content ?? "";
            if (token) open = pass(token);
          }
          if (open && line) {
            const picked = tagsFrom(line);
            if (picked) tags = picked;
            else data({ token: line });
          }
          if (open && tags.length > 0) {
            send(`event: tags\ndata: ${JSON.stringify({ tags })}\n\n`);
          }
        } catch (e) {
          if (!closed) {
            console.error("[auto-summarize] LLM error:", e);
            data({ error: `${e}` });
          }
        }

        data({ done: true });
        if (!closed) {
          closed = true;
          controller.close();
        }
      },
      cancel() {
        // The app stopped listening: stop the models too.
        closed = true;
        stop();
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
    return new Response(JSON.stringify({ error: "Summary failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
