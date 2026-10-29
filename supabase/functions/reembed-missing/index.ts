// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: reembed-missing
//
// Backfill: writes the embedding of every one of the signed-in user's
// notes that has none (content_vault and personal_notes) — after switching
// OPENAI_EMBED_MODEL, or when saving a note couldn't embed it. Reads and
// writes with the user's token; each note takes one from their daily
// "embed" allowance, and it stops when that's used up.
//
// Body (optional): { tables: ['content_vault' | 'personal_notes'] }
// When omitted, both are done.
//
// Response: {
//   processed: { content_vault: N, personal_notes: M },
//   skipped:   { ... },
//   errors:    [ { table, id, reason } ],
//   total:     T,
//   quotaReached: boolean
// }

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

/** Text beyond this isn't embedded (same as embed-note). */
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

/// Per table: which columns make up the text to embed.
const TABLES: Record<
  string,
  {
    select: string;
    buildText: (row: any) => string;
  }
> = {
  content_vault: {
    select: "id, title, manual_notes",
    buildText: (r) => `${r.title ?? ""}\n\n${r.manual_notes ?? ""}`.trim(),
  },
  personal_notes: {
    select: "id, title, body",
    buildText: (r) => `${r.title ?? ""}\n\n${r.body ?? ""}`.trim(),
  },
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Missing auth" }, 401);

    const supabase = createClient(SUPABASE_URL, PUBLIC_KEY, {
      db: { schema: "ingatanku" },
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return json({ error: "Unauthorized" }, 401);

    const reqBody = await req.json().catch(() => ({}));
    const requested: string[] = Array.isArray(reqBody?.tables) &&
        reqBody.tables.length > 0
      ? reqBody.tables.filter((t: string) => t in TABLES)
      : Object.keys(TABLES);

    const processed: Record<string, number> = {};
    const skipped: Record<string, number> = {};
    const errors: Array<{ table: string; id: string; reason: string }> = [];
    let total = 0;
    let quotaReached = false;

    for (const table of requested) {
      const cfg = TABLES[table];
      processed[table] = 0;
      skipped[table] = 0;
      if (quotaReached) continue;

      const { data: rows, error: selErr } = await supabase
        .from(table)
        .select(cfg.select)
        .eq("user_id", user.id)
        .is("embedding", null);

      if (selErr) {
        console.error(`[reembed-missing] ${table}:`, selErr.message);
        errors.push({ table, id: "*", reason: "read failed" });
        continue;
      }
      const targets = rows ?? [];
      total += targets.length;

      for (const row of targets) {
        const text = cfg.buildText(row);
        if (!text) {
          skipped[table]++;
          continue;
        }
        if (!(await takeQuota(supabase, "embed"))) {
          quotaReached = true;
          break;
        }
        try {
          const embedding = await embed(text.slice(0, MAX_EMBED_CHARS));
          const fitted = embedding.length > TARGET_DIM
            ? embedding.slice(0, TARGET_DIM)
            : embedding;
          const { error: updErr } = await supabase
            .from(table)
            .update({ embedding: fitted })
            .eq("id", row.id);
          if (updErr) {
            console.error(`[reembed-missing] ${table} ${row.id}:`, updErr.message);
            errors.push({ table, id: row.id, reason: "update failed" });
          } else {
            processed[table]++;
          }
        } catch (e) {
          console.error(`[reembed-missing] ${table} ${row.id}:`, e);
          errors.push({ table, id: row.id, reason: "embedding failed" });
        }
      }
    }

    return json({ processed, skipped, errors, total, quotaReached });
  } catch (e) {
    console.error("[reembed-missing] handler error:", e);
    return json({ error: "Re-embedding failed" }, 500);
  }
});
