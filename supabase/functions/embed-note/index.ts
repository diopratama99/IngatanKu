// @ts-nocheck — runs on Deno, not Node. IDE TS warnings are safe to ignore.
// Supabase Edge Function: embed-note
// Generates an embedding for a note and stores it in content_vault.embedding.
// Trigger via Database Webhook on content_vault INSERT.
//
// Deploy: supabase functions deploy embed-note --no-verify-jwt
// Then create a Database Webhook on table content_vault, event INSERT,
// pointing to https://<project>.functions.supabase.co/embed-note

import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";

const _embedBaseURL = Deno.env.get("OPENAI_EMBED_BASE_URL") ?? Deno.env.get("OPENAI_BASE_URL");
const _embedApiKey = Deno.env.get("OPENAI_EMBED_API_KEY") ?? Deno.env.get("OPENAI_API_KEY")!;
const embedClient = new OpenAI({
  apiKey: _embedApiKey,
  ...(_embedBaseURL ? { baseURL: _embedBaseURL } : {}),
});

const EMBED_MODEL = Deno.env.get("OPENAI_EMBED_MODEL") ?? "text-embedding-3-small";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { db: { schema: "ingatanku" } },
);

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    // Supabase webhook payload shape: { type, table, record, schema, old_record }
    const record = payload.record;
    if (!record?.id || !record?.manual_notes) {
      return new Response("ignored", { status: 200 });
    }

    const text = `${record.title ?? ""}\n\n${record.manual_notes}`.trim();

    const embRes = await embedClient.embeddings.create({
      model: EMBED_MODEL,
      input: text,
    });
    const embedding = embRes.data[0].embedding;

    const { error } = await supabaseAdmin
      .from("content_vault")
      .update({ embedding })
      .eq("id", record.id);

    if (error) {
      console.error(error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
      });
    }

    return new Response(JSON.stringify({ ok: true, id: record.id }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: `${e}` }), { status: 500 });
  }
});
