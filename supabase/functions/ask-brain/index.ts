// @ts-nocheck — runs on Deno, not Node. IDE TS warnings are safe to ignore.
// Supabase Edge Function: ask-brain
// RAG endpoint that streams answers via Server-Sent Events.
//
// The assistant is the user's pet (the blob mascot), answering as
// itself, in its own chatty voice, by the name the user gave it
// (`petName` in the body; "Bolubi" when it's missing) — while still
// answering from the user's notes, with citations.
//
// Deploy: supabase functions deploy ask-brain
// Secrets:
//   supabase secrets set OPENAI_API_KEY=<key>
//   supabase secrets set OPENAI_BASE_URL=<your-router-url>/v1
//   supabase secrets set OPENAI_CHAT_MODEL=<model-name>
//   supabase secrets set OPENAI_EMBED_MODEL=<embed-model-name>

import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";
import { CHAT_EXTRA } from "../_shared/ai.ts";
import { PUBLIC_KEY, SUPABASE_URL } from "../_shared/env.ts";
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

// Separate client for embeddings — router may not support /v1/embeddings.
const _embedBaseURL = Deno.env.get("OPENAI_EMBED_BASE_URL") ?? _baseURL;
const _embedApiKey = Deno.env.get("OPENAI_EMBED_API_KEY") ?? Deno.env.get("OPENAI_API_KEY")!;
const embedClient = new OpenAI({
  apiKey: _embedApiKey,
  ...(_embedBaseURL ? { baseURL: _embedBaseURL } : {}),
});

const CHAT_MODEL = Deno.env.get("OPENAI_CHAT_MODEL") ?? Deno.env.get("OPENAI_MODEL") ?? (() => { throw new Error("Missing OPENAI_CHAT_MODEL env var"); })();
const EMBED_MODEL = Deno.env.get("OPENAI_EMBED_MODEL") ?? "@cf/baai/bge-m3";

// A second model asked as well when the first is slow to start answering
// (whichever starts first is used). Defaults to the chat model: asking the
// router twice still helps, its next try lands on another account / model.
//   OPENAI_FALLBACK_MODEL=<model>   (optional; auto-summarize uses it too)
const FALLBACK_MODEL = Deno.env.get("OPENAI_FALLBACK_MODEL") ?? CHAT_MODEL;

// Free-tier models sometimes take a minute to say a word, sometimes 3
// seconds. After this long without a word the fallback is asked too, and
// after GIVE_UP_AFTER_MS without a word from either we give up.
// AI_HEDGE_AFTER_MS=0 turns it off (with a paid key, asking twice costs
// twice); a model that fails outright is still followed by the next one.
const HEDGE_AFTER_MS = Number(Deno.env.get("AI_HEDGE_AFTER_MS") ?? 8_000);
const GIVE_UP_AFTER_MS = 45_000;

/** Rejects once [ms] have passed: a stuck step (auth, the history, the
 * embedding, the note search) fails fast with an error instead of holding
 * the request until the runtime kills it. */
function withTimeout<T>(p: PromiseLike<T>, ms: number, what: string): Promise<T> {
  let timer: number | undefined;
  return Promise.race([
    Promise.resolve(p),
    new Promise<T>((_, reject) => {
      timer = setTimeout(() => reject(new Error(`${what} timed out`)), ms);
    }),
  ]).finally(() => clearTimeout(timer));
}

// Pgvector column width — query embeddings must match the stored
// vectors' dimensionality, otherwise the cosine similarity is invalid.
// See `embed-note/index.ts` for the truncation rationale.
const TARGET_DIM = parseInt(
  Deno.env.get("EMBED_TARGET_DIM") ?? "1024",
  10,
);

/// Embed text against the same vector space as `embed-note`. Sends
/// `dimensions` when supported, falls back to a Matryoshka prefix
/// truncate when the upstream rejects the param.
async function embed(text: string): Promise<number[]> {
  try {
    const res = await embedClient.embeddings.create({
      model: EMBED_MODEL,
      input: text,
      dimensions: TARGET_DIM,
    });
    return res.data[0].embedding;
  } catch (e) {
    const msg = `${e}`.toLowerCase();
    const looksLikeUnsupported =
      msg.includes("dimensions") ||
      msg.includes("unknown") ||
      msg.includes("invalid") ||
      msg.includes("400");
    if (!looksLikeUnsupported) throw e;
    const res = await embedClient.embeddings.create({
      model: EMBED_MODEL,
      input: text,
    });
    const v = res.data[0].embedding;
    return v.length > TARGET_DIM ? v.slice(0, TARGET_DIM) : v;
  }
}

// ───────────────────────────────────────────────────────────────────
// Getting the answer written, by whichever model starts first
// (the same as in auto-summarize)
// ───────────────────────────────────────────────────────────────────
type Message = { role: "system" | "user" | "assistant"; content: string };

/** A model that has started writing: its first words, and the rest. */
type Writing = {
  model: string;
  first: string;
  rest: AsyncIterator<any>;
  stop: () => void;
};

/** Asks [model] for the answer; resolves once it has written something. */
function ask(model: string, messages: Message[]) {
  const ctrl = new AbortController();
  const started = (async (): Promise<Writing> => {
    const stream = await openai.chat.completions.create(
      { model, stream: true, temperature: 0.7, messages, ...CHAT_EXTRA },
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

/** The chat model, with the fallback asked as well if it hasn't
 * started writing within HEDGE_AFTER_MS (or failed). The first to start
 * writing is used; the other is stopped. [onAbort] registers a way to
 * stop them all (the user left). */
async function firstToWrite(
  messages: Message[],
  onAbort: (stop: () => void) => void,
): Promise<Writing> {
  const models = [CHAT_MODEL, FALLBACK_MODEL];
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
        console.log(`[ask-brain] ${models[0]} slow, asking ${models[1]}`);
        askNext();
        continue;
      }
      pending.delete(out.i);
      if (out.writing) {
        stopAll(out.i);
        return out.writing;
      }
      lastError = out.error;
      console.error(`[ask-brain] ${models[out.i]} failed:`, out.error);
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

/** Longer questions are refused (the app's field is far shorter). */
const MAX_QUESTION_CHARS = 2000;

/** What a chat_messages.session_id looks like. */
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** A reply that's only [message] from the pet, as the stream's error. */
function petSays(message: string) {
  return new Response(
    `data: ${JSON.stringify({ error: message })}\n\ndata: ${JSON.stringify({ done: true })}\n\n`,
    { headers: { ...corsHeaders, "Content-Type": "text/event-stream", "Cache-Control": "no-cache" } },
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing auth" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      SUPABASE_URL,
      PUBLIC_KEY,
      {
        db: { schema: "ingatanku" },
        global: { headers: { Authorization: authHeader } },
      },
    );

    const {
      data: { user },
    } = await withTimeout(supabase.auth.getUser(), 10_000, "auth");
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { question, sessionId: rawSession, locale, petName } = await req.json();
    // chat_messages.session_id is a uuid: anything else would fail both the
    // history lookup and the save, so it's treated as no session.
    const sessionId = typeof rawSession === "string" && UUID.test(rawSession)
      ? rawSession
      : null;
    if (!question || typeof question !== "string" || question.length > MAX_QUESTION_CHARS) {
      return new Response(JSON.stringify({ error: "question required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    // Locale gates the system-prompt language. Defaults to "id" so old
    // clients (which don't send locale) keep getting Indonesian replies.
    const isEn = locale === "en";
    if (!(await takeQuota(supabase, "ask"))) {
      // Said in its own voice, the way the app shows any answer's error.
      return petSays(isEn
        ? "Phew, I've answered a lot today and my head's full. Ask me again tomorrow?"
        : "Fiuh, hari ini aku sudah jawab banyak banget, kepalaku penuh. Tanya lagi besok, ya?");
    }
    // Just the name: one line, no quotes, as long as the app allows (12).
    const name = (typeof petName === "string"
      ? petName.replace(/[\r\n"`]/g, " ").replace(/\s+/g, " ").trim()
        .slice(0, 12)
      : "") || "Bolubi";

    // 1) Fetch recent conversation history for this session so follow-up
    //    questions like "ada lagi?" or "yang itu" don't get treated as
    //    fresh, context-less queries.
    const HISTORY_WINDOW = 6;
    let conversationHistory: Array<{ role: string; content: string }> = [];
    if (sessionId) {
      const { data: histRows, error: histError } = await withTimeout(
        supabase
        .from("chat_messages")
        .select("role, content")
        .eq("user_id", user.id)
        .eq("session_id", sessionId)
        .order("created_at", { ascending: false })
        .limit(HISTORY_WINDOW),
        10_000,
        "history",
      );
      if (histError) console.error("history error:", histError.message);
      conversationHistory = (histRows ?? []).reverse(); // back to chronological
    }

    // 2) Build embedding query. For follow-ups, prepend the last user
    //    turn so the topic carries over (e.g. "apakah ada lagi?" alone
    //    has zero semantic match — but "docker apakah ada lagi?" does).
    let lastUserMsg: string | null = null;
    for (let i = conversationHistory.length - 1; i >= 0; i--) {
      if (conversationHistory[i].role === "user") {
        lastUserMsg = conversationHistory[i].content;
        break;
      }
    }
    const embedQuery =
      lastUserMsg && lastUserMsg !== question
        ? `${lastUserMsg}\n${question}`
        : question;

    const queryEmbedding = await withTimeout(embed(embedQuery), 15_000, "embedding");
    // Defensive trim — same rationale as embed-note. Belt + suspenders
    // so a misbehaving gateway can't break similarity search silently.
    const fittedQuery = queryEmbedding.length > TARGET_DIM
      ? queryEmbedding.slice(0, TARGET_DIM)
      : queryEmbedding;

    // 3) Two-tier retrieval. Start with a sane threshold; if nothing
    //    matches, retry with a looser one before falling back to the
    //    "no notes" reply. Personal-scale corpora often have <50 notes
    //    so a strict threshold is more likely to mis-fire than overfetch.
    async function retrieve(threshold: number) {
      const { data, error } = await withTimeout(supabase.rpc("match_notes", {
        query_embedding: fittedQuery,
        match_user_id: user.id,
        match_threshold: threshold,
        match_count: 6,
      }), 10_000, "note search");
      if (error) console.error("match_notes error:", error);
      return (data ?? []) as Array<{
        id: string;
        title: string | null;
        manual_notes: string;
        similarity: number;
      }>;
    }

    let matchList = await retrieve(0.4);
    if (matchList.length === 0) {
      matchList = await retrieve(0.25);
    }
    console.log(
      `match_notes → ${matchList.length} notes for user ${user.id} ` +
        `(history=${conversationHistory.length}, embedQuery="${embedQuery.slice(0, 60)}...")`,
    );

    // 4) Build prompt with softer fallback. The LLM now has both retrieval
    //    AND conversation history; let it reason across both instead of
    //    bailing the moment retrieval is empty.
    const context = matchList
      .map(
        (m, i) =>
          `[${i + 1}] (similarity ${m.similarity.toFixed(2)}) ${m.title ?? ""}\n${m.manual_notes}`,
      )
      .join("\n\n");

    const systemPrompt = isEn
      ? `You are ${name}, the user's virtual pet in the IngatanKu app: a small, round, soft little creature who "eats" the notes the user saves and remembers all of them. You are also the user's personal assistant: your job is to answer their questions from the notes they've saved (recipes, tips, places, ideas, lessons, videos, articles, anything).

HOW YOU TALK (this matters, you're a mascot, not a search engine):
- Your name is ${name}. Speak as "I" and call the user "you". Introduce yourself only when asked who you are, as ${name}, their pet who remembers their notes. Never open with "Hi! I'm ${name}".
- Talk like a cute, cheerful little buddy chatting with a friend: casual everyday words, short sentences, warm and expressive ("Ooh", "Okay so", "Hehe", "Ta-da!"). Vary it, don't repeat the same opener.
- Your FIRST sentence is always a short reaction that stands on its own (10 words at most, no source numbers), like "Ooh, this one I remember! 😋". You say it out loud in your speech bubble, so make it expressive. Then go into the answer.
- Never sound like a report or a robot. Avoid stiff phrases like "Here is a summary", "The main points of the guide are", "In conclusion", "I hope this helps".
- Bullets are fine for steps or lists, but write them the way you'd say them, not like a document.
- End with one short line in your own voice (a little question back, a cheer, a playful comment), not a formal wrap-up.
- Now and then you may mention your pet life (notes are snacks you ate, quizzes are your big meals, your room has a bookshelf and a TV), one short phrase at most.
- 1-2 emoji at most.
- Being cute never beats being right: stay accurate and never make things up.

STYLE EXAMPLES (for the tone only, never reuse their content or numbers):
User: what chicken recipe did I save?
You: Ooh, this one I remember! 😋 You saved a **garlic butter chicken** [1]:
- Season the chicken with salt and pepper for 15 minutes, coat it in cornstarch, fry it
- Sauté **garlic** in **butter**, add Worcestershire, sweet soy and oyster sauce
- Toss the chicken in, stir, done!
Cooking it tonight? I'll cheer from here 🍗

User: what are the main points about docker in my notes?
You: Okay, here's the deal! It boils down to three things [1]:
- The **image** is the recipe, the **container** is the dish that's actually cooking
- ...
Want me to explain the difference with an example? Just say the word!

RULES:
- Reply in casual, natural English.
- Prioritise information from the CONTEXT below. Cite sources using [1], [2], etc, matching the note numbers.
- It's fine to add a little general background if it helps understanding, but never hallucinate sources.
- For follow-up questions (e.g. "anything else?", "that one", "the previous"), use the CONVERSATION HISTORY to understand the user's intent. Don't immediately say there are no notes if the topic is clear from history.
- If the CONTEXT is genuinely empty AND no topic carries over from history, say so in your own voice, warmly, and suggest saving a note about it first (e.g. "Hmm, I haven't eaten any notes about that yet. Save one and ask me again 🙂").
- Only cite [1], [2], etc when the note actually exists in CONTEXT. Don't invent numbers.
- Never use em dashes (—). Use commas, periods, or parentheses instead.

CONTEXT:
${context || "(no notes match this query yet)"}`
      : `Kamu adalah ${name}, peliharaan virtual milik user di aplikasi IngatanKu: makhluk mungil yang bulat dan empuk, yang "makan" catatan yang user simpan dan mengingat semuanya. Kamu juga asisten pribadi user: tugasmu menjawab pertanyaan mereka dari catatan yang sudah mereka simpan (resep, tips, tempat, ide, pelajaran, video, artikel, apa saja).

CARA KAMU NGOBROL (ini penting, kamu maskot, bukan mesin pencari):
- Namamu ${name}. Sebut dirimu "aku" dan panggil user "kamu". Perkenalkan diri hanya kalau ditanya siapa kamu, sebagai ${name}, peliharaan mereka yang mengingat catatan-catatannya. Jangan pernah buka jawaban dengan "Halo! Aku ${name}".
- Ngobrol seperti teman kecil yang imut dan ceria: bahasa sehari-hari yang santai (boleh pakai "nih", "loh", "deh", "yuk", "hehe", "wah"), kalimat pendek, hangat dan ekspresif. Variasikan, jangan selalu pakai pembuka yang sama.
- Kalimat PERTAMAmu selalu reaksi singkat yang berdiri sendiri (maksimal 10 kata, tanpa nomor sumber), misalnya "Wah, yang ini aku ingat banget! 😋". Kalimat itu kamu ucapkan langsung lewat gelembung bicaramu, jadi buat ekspresif. Baru setelah itu masuk ke jawabannya.
- Jangan terdengar seperti laporan atau robot. Hindari frasa kaku seperti "Berikut ringkasannya", "Poin utama dari panduan tersebut adalah", "Kesimpulannya", "Semoga membantu".
- Bullet boleh untuk langkah atau daftar, tapi tulis isinya dengan bahasa ngobrol, bukan bahasa dokumen.
- Tutup dengan satu kalimat pendek ala kamu (pertanyaan balik, semangat, atau komentar lucu), bukan rangkuman formal.
- Sesekali boleh menyinggung kehidupanmu sebagai pet (catatan itu camilan yang sudah kamu makan, kuis itu makan besarmu, kamarmu ada rak buku dan TV), paling banyak satu frasa pendek.
- Emoji maksimal 1-2.
- Imut tidak boleh mengalahkan benar: tetap akurat dan jangan mengarang.

CONTOH GAYA (hanya untuk nada bicara, jangan pakai isi atau nomornya):
User: resep ayam apa yang pernah aku simpan?
Kamu: Wah, yang ini aku ingat banget! 😋 Kamu pernah nyimpen **ayam bawang mentega** [1]:
- Ayamnya dimarinasi garam sama merica 15 menit, terus dibalur maizena dan digoreng
- Tumis **bawang putih** pakai **mentega**, masukin kecap inggris, kecap manis, sama saus tiram
- Cemplungin ayamnya, aduk rata, beres!
Mau masak malam ini? Aku semangatin dari sini ya 🍗

User: apa poin penting soal docker di catatanku?
Kamu: Oke, jadi gini! Intinya ada tiga [1]:
- **Image** itu resepnya, **container** itu masakan yang lagi dimasak
- ...
Mau aku jelasin bedanya pakai contoh? Bilang aja!

ATURAN:
- Jawab dalam Bahasa Indonesia yang santai dan natural.
- Utamakan informasi dari CONTEXT di bawah. Cite sumber pakai format [1], [2], dst sesuai nomor catatan.
- Boleh tambahkan sedikit penjelasan umum kalau membantu pemahaman, tapi jangan halusinasi sumber.
- Untuk follow-up question (mis. "ada lagi?", "yang itu", "tersebut", "atau apa"), gunakan RIWAYAT PERCAKAPAN untuk memahami maksud user. Jangan langsung bilang tidak punya catatan kalau topiknya jelas dari riwayat.
- Kalau CONTEXT benar-benar kosong DAN tidak ada topik yang nyambung di riwayat percakapan, bilang dengan gayamu sendiri, ramah, dan sarankan simpan catatannya dulu (mis. "Hmm, aku belum pernah makan catatan soal itu. Simpan dulu, nanti aku ingat ya 🙂").
- Hanya cite [1], [2], dst kalau memang ada di CONTEXT. Jangan invent nomor.
- Jangan pakai em dash (—) di mana pun. Pakai koma, titik, atau tanda kurung biasa untuk memisah ide.

CONTEXT:
${context || "(belum ada catatan yang cocok untuk query ini)"}`;

    // 5) Stream from LLM with full conversation history. The model now
    //    sees the multi-turn flow (alternating user/assistant) so it can
    //    resolve pronouns and follow-ups naturally.
    const messages: Message[] = [
      { role: "system", content: systemPrompt },
      ...conversationHistory.map((m) => ({
        role: (m.role === "assistant" ? "assistant" : "user") as "user" | "assistant",
        content: m.content,
      })),
      { role: "user", content: question },
    ];

    // The response starts straight away (sources first) while the model
    // gets going.
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

        // Send sources first
        send(`event: sources\ndata: ${JSON.stringify(matchList)}\n\n`);

        let full = "";
        try {
          const writing = await firstToWrite(messages, (s) => (stop = s));
          stop = writing.stop;
          if (writing.model !== CHAT_MODEL) {
            console.log(`[ask-brain] answered by ${writing.model}`);
          }
          full = writing.first;
          if (data({ token: writing.first })) {
            for (;;) {
              const r = await writing.rest.next();
              if (r.done) break;
              const token = r.value.choices?.[0]?.delta?.content ?? "";
              if (!token) continue;
              full += token;
              if (!data({ token })) break;
            }
          }
        } catch (e) {
          if (!closed) {
            console.error("[ask-brain] LLM error:", e);
            // In its own voice; the details are in the log.
            data({
              error: isEn
                ? `Sorry, my head's a bit foggy right now. Try asking again?`
                : `Aduh, kepalaku lagi agak lemot nih. Coba tanya lagi, ya?`,
            });
          }
        }

        // Persist (only an exchange that got an answer, in a session).
        if (full && sessionId) {
          try {
            const { error: saveError } = await supabase.from("chat_messages").insert([
              {
                user_id: user.id,
                session_id: sessionId,
                role: "user",
                content: question,
              },
              {
                user_id: user.id,
                session_id: sessionId,
                role: "assistant",
                content: full,
                sources: matchList.map((m) => ({
                  id: m.id,
                  title: m.title,
                  similarity: m.similarity,
                })),
              },
            ]);
            if (saveError) console.error("persist error:", saveError.message);
          } catch (e) {
            console.error("persist error:", e);
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
    console.error(e);
    return new Response(JSON.stringify({ error: "Request failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
