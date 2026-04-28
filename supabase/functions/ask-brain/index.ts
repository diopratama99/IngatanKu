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
      { global: { headers: { Authorization: authHeader } } },
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

    // 1) Embed question
    const embRes = await openai.embeddings.create({
      model: EMBED_MODEL,
      input: question,
    });
    const queryEmbedding = embRes.data[0].embedding;

    // 2) Retrieve top-K notes — start permissive, the LLM can ignore
    //    low-quality matches via the prompt instructions.
    const { data: matches, error: rpcErr } = await supabase.rpc("match_notes", {
      query_embedding: queryEmbedding,
      match_user_id: user.id,
      match_threshold: 0.4,
      match_count: 6,
    });
    if (rpcErr) console.error("match_notes error:", rpcErr);
    console.log(`match_notes returned ${matches?.length ?? 0} notes for user ${user.id}`);

    const matchList = (matches ?? []) as Array<{
      id: string;
      title: string | null;
      manual_notes: string;
      similarity: number;
    }>;

    // 3) Build prompt
    const context = matchList
      .map(
        (m, i) =>
          `[${i + 1}] (similarity ${m.similarity.toFixed(2)}) ${m.title ?? ""}\n${m.manual_notes}`,
      )
      .join("\n\n");

    const systemPrompt = `Kamu adalah "Otak Kedua" pribadi user — asisten AI yang membantu mereka mengingat dan memahami catatan tech yang sudah mereka simpan.

ATURAN:
- Jawab dalam Bahasa Indonesia yang santai dan natural.
- Utamakan informasi dari CONTEXT di bawah. Sebut sumber dengan format [1], [2], dst sesuai nomor catatan.
- Kalau CONTEXT relevan, jawab berdasarkan itu — TAPI boleh tambahkan sedikit penjelasan umum kalau membantu.
- Kalau CONTEXT kosong atau tidak relevan sama sekali dengan pertanyaan, balas: "Aku belum punya catatan soal itu. Coba simpan konten dulu, baru tanya lagi ya 🙂"
- Jangan halusinasi sumber. Hanya cite [1], [2], dst kalau memang ada di CONTEXT.

CONTEXT:
${context || "(belum ada catatan yang cocok)"}`;

    // 4) Stream from LLM
    const completion = await openai.chat.completions.create({
      model: CHAT_MODEL,
      stream: true,
      temperature: 0.4,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: question },
      ],
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
