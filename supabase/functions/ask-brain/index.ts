// @ts-nocheck — runs on Deno, not Node. IDE TS warnings are safe to ignore.
// Supabase Edge Function: ask-brain
// RAG endpoint that streams answers via Server-Sent Events.
//
// Deploy: supabase functions deploy ask-brain
// Secrets:
//   supabase secrets set OPENAI_API_KEY=<key-or-github-pat>
//   # Optional — point to a different OpenAI-compatible provider:
//   supabase secrets set OPENAI_BASE_URL=https://models.github.ai/inference
//   supabase secrets set OPENAI_CHAT_MODEL=gpt-4o-mini
//   supabase secrets set OPENAI_EMBED_MODEL=text-embedding-3-small

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import OpenAI from "https://esm.sh/openai@4.56.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Both OpenAI proper and GitHub Models / OpenRouter / Together / etc expose
// the same OpenAI-compatible REST API; we just point baseURL at whichever
// provider's API key is configured.
const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY")!,
  baseURL: Deno.env.get("OPENAI_BASE_URL") ?? "https://api.openai.com/v1",
});

const CHAT_MODEL = Deno.env.get("OPENAI_CHAT_MODEL") ?? "gpt-4o-mini";
const EMBED_MODEL =
  Deno.env.get("OPENAI_EMBED_MODEL") ?? "text-embedding-3-small";

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
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        db: { schema: "ingatanku" },
        global: { headers: { Authorization: authHeader } },
      },
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { question, sessionId } = await req.json();
    if (!question || typeof question !== "string") {
      return new Response(JSON.stringify({ error: "question required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1) Fetch recent conversation history for this session so follow-up
    //    questions like "ada lagi?" or "yang itu" don't get treated as
    //    fresh, context-less queries.
    const HISTORY_WINDOW = 6;
    let conversationHistory: Array<{ role: string; content: string }> = [];
    if (sessionId) {
      const { data: histRows } = await supabase
        .from("chat_messages")
        .select("role, content")
        .eq("user_id", user.id)
        .eq("session_id", sessionId)
        .order("created_at", { ascending: false })
        .limit(HISTORY_WINDOW);
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

    const embRes = await openai.embeddings.create({
      model: EMBED_MODEL,
      input: embedQuery,
    });
    const queryEmbedding = embRes.data[0].embedding;

    // 3) Two-tier retrieval. Start with a sane threshold; if nothing
    //    matches, retry with a looser one before falling back to the
    //    "no notes" reply. Personal-scale corpora often have <50 notes
    //    so a strict threshold is more likely to mis-fire than overfetch.
    async function retrieve(threshold: number) {
      const { data, error } = await supabase.rpc("match_notes", {
        query_embedding: queryEmbedding,
        match_user_id: user.id,
        match_threshold: threshold,
        match_count: 6,
      });
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

    const systemPrompt = `Kamu adalah "Otak Kedua" pribadi user — asisten AI yang ingat catatan tech yang sudah mereka simpan.

ATURAN:
- Jawab dalam Bahasa Indonesia yang santai dan natural.
- Utamakan informasi dari CONTEXT di bawah. Cite sumber pakai format [1], [2], dst sesuai nomor catatan.
- Boleh tambahkan sedikit penjelasan umum kalau membantu pemahaman — tapi jangan halusinasi sumber.
- Untuk follow-up question (mis. "ada lagi?", "yang itu", "tersebut", "atau apa"), gunakan RIWAYAT PERCAKAPAN untuk memahami maksud user. Jangan langsung bilang tidak punya catatan kalau topiknya jelas dari riwayat.
- Kalau CONTEXT benar-benar kosong DAN tidak ada topik yang nyambung di riwayat percakapan, balas ramah: "Aku belum punya catatan soal itu — coba simpan dulu, baru tanya lagi ya 🙂"
- Hanya cite [1], [2], dst kalau memang ada di CONTEXT. Jangan invent nomor.

CONTEXT:
${context || "(belum ada catatan yang cocok untuk query ini)"}`;

    // 5) Stream from LLM with full conversation history. The model now
    //    sees the multi-turn flow (alternating user/assistant) so it can
    //    resolve pronouns and follow-ups naturally.
    const messages: Array<{ role: "system" | "user" | "assistant"; content: string }> = [
      { role: "system", content: systemPrompt },
      ...conversationHistory.map((m) => ({
        role: (m.role === "assistant" ? "assistant" : "user") as "user" | "assistant",
        content: m.content,
      })),
      { role: "user", content: question },
    ];

    const completion = await openai.chat.completions.create({
      model: CHAT_MODEL,
      stream: true,
      temperature: 0.4,
      messages,
    });

    const encoder = new TextEncoder();
    const readable = new ReadableStream({
      async start(controller) {
        // Send sources first
        controller.enqueue(
          encoder.encode(`event: sources\ndata: ${JSON.stringify(matchList)}\n\n`),
        );

        let full = "";
        try {
          for await (const chunk of completion) {
            const token = chunk.choices[0]?.delta?.content ?? "";
            if (token) {
              full += token;
              controller.enqueue(
                encoder.encode(`data: ${JSON.stringify({ token })}\n\n`),
              );
            }
          }
        } catch (e) {
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify({ error: `${e}` })}\n\n`),
          );
        }

        // Persist
        try {
          await supabase.from("chat_messages").insert([
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
        } catch (e) {
          console.error("persist error:", e);
        }

        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ done: true })}\n\n`));
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
    console.error(e);
    return new Response(JSON.stringify({ error: `${e}` }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
