// @ts-nocheck — runs on Deno, not Node. IDE TS warnings are safe to ignore.
// Supabase Edge Function: embed-note
//
// Writes the embedding of one of the signed-in user's notes (what the
// assistant searches), from the note as it's saved — the text sent along
// is ignored, so no one can write an embedding into a row that isn't theirs
// or embed text of their choosing.
//
// Body: { table?: 'content_vault' | 'personal_notes', id }
//   (the app's older shape, { record: { id, ... } }, still works)
//
// Reads and writes with the user's token, so RLS keeps it to their notes.
// Each note embedded takes one from their daily "embed" allowance.
//
// Deploy: supabase functions deploy embed-note

import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";
import { PUBLIC_KEY, SUPABASE_URL } from "../_shared/env.ts";
import { takeQuota } from "../_shared/quota.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const _embedBaseURL = Deno.env.get("OPENAI_EMBED_BASE_URL") ?? Deno.env.get("OPENAI_BASE_URL");
const _embedApiKey = Deno.env.get("OPENAI_EMBED_API_KEY") ?? Deno.env.get("OPENAI_API_KEY")!;
const embedClient = new OpenAI({
  apiKey: _embedApiKey,
  ...(_embedBaseURL ? { baseURL: _embedBaseURL } : {}),
});

const EMBED_MODEL = Deno.env.get("OPENAI_EMBED_MODEL") ?? "@cf/baai/bge-m3";

const TARGET_DIM = parseInt(
  Deno.env.get("EMBED_TARGET_DIM") ?? "1024",
  10,
);

/** Text beyond this isn't embedded (a note's start says what it's about). */
const MAX_EMBED_CHARS = 8000;

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

/** Per table: the columns to read, and the text to embed from them. */
const TABLES: Record<string, { columns: string; text: (row: any) => string }> = {
  content_vault: {
    columns: "id, title, manual_notes",
    text: (r) => `${r.title ?? ""}\n\n${r.manual_notes ?? ""}`.trim(),
  },
  personal_notes: {
    columns: "id, title, body",
    text: (r) => `${r.title ?? ""}\n\n${r.body ?? ""}`.trim(),
  },
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Missing auth" }, 401);
    const supabase = createClient(SUPABASE_URL, PUBLIC_KEY, {
      db: { schema: "ingatanku" },
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return json({ error: "Unauthorized" }, 401);

    const body = await req.json().catch(() => ({}));
    const table: string = body.table ?? "content_vault";
    const id = body.id ?? body.record?.id;
    const spec = TABLES[table];
    if (!spec || typeof id !== "string") return json({ error: "table and id required" }, 400);

    const { data: row, error: readError } = await supabase
      .from(table)
      .select(spec.columns)
      .eq("id", id)
      .maybeSingle();
    if (readError) throw readError;
    if (!row) return json({ error: "Not found" }, 404);

    const text = spec.text(row);
    // Nothing to embed yet (an empty draft): it's done once there's text.
    if (!text) return json({ ok: true, skipped: "empty" });
    if (!(await takeQuota(supabase, "embed"))) return json({ ok: true, skipped: "quota" });

    const embedding = await embed(text.slice(0, MAX_EMBED_CHARS));
    const fitted = embedding.length > TARGET_DIM ? embedding.slice(0, TARGET_DIM) : embedding;

    const { error } = await supabase.from(table).update({ embedding: fitted }).eq("id", id);
    if (error) throw error;
    return json({ ok: true, table, id });
  } catch (e) {
    console.error("[embed-note]", e);
    return json({ error: "Embedding failed" }, 500);
  }
});
