// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: reembed-missing
//
// One-shot backfill: scans `content_vault` for notes belonging to the
// caller that have NULL embedding, then generates and stores the
// embedding for each. Useful when the database webhook to `embed-note`
// wasn't firing (common on self-hosted instances missing `pg_net`).
//
// Deploy: supabase functions deploy reembed-missing
// Trigger from the app's Profile page or curl:
//   curl -X POST https://<your>/functions/v1/reembed-missing \
//     -H "Authorization: Bearer <USER_ACCESS_TOKEN>"
//
// Response: { processed: N, skipped: M, errors: [...] }

import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";

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

const EMBED_MODEL = Deno.env.get("OPENAI_EMBED_MODEL") ?? "text-embedding-3-small";

// Service-role client for the actual UPDATE (bypasses RLS so we can
// patch even rows that the user-scoped client wouldn't see during the
// race between webhook and read).
const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { db: { schema: "ingatanku" } },
);

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

    // User-scoped client just to verify the caller's identity.
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        db: { schema: "ingatanku" },
        global: { headers: { Authorization: authHeader } },
      },
    );
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Find notes for this user that lack an embedding. We use the
    // service-role client because the user-scoped one can race with
    // pending RLS-triggered embeddings from a stale webhook.
    const { data: notes, error: selErr } = await admin
      .from("content_vault")
      .select("id, title, manual_notes")
      .eq("user_id", user.id)
      .is("embedding", null);

    if (selErr) {
      return new Response(JSON.stringify({ error: selErr.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const targets = notes ?? [];
    if (targets.length === 0) {
      return new Response(
        JSON.stringify({ processed: 0, skipped: 0, message: "All notes already have embeddings." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    let processed = 0;
    let skipped = 0;
    const errors: Array<{ id: string; reason: string }> = [];

    // Sequential, not parallel — provider rate-limits are unforgiving and
    // personal corpora are small (<100 notes typically).
    for (const note of targets) {
      const text = `${note.title ?? ""}\n\n${note.manual_notes ?? ""}`.trim();
      if (!text) {
        skipped++;
        continue;
      }
      try {
        const embRes = await embedClient.embeddings.create({
          model: EMBED_MODEL,
          input: text,
        });
        const embedding = embRes.data[0].embedding;
        const { error: updErr } = await admin
          .from("content_vault")
          .update({ embedding })
          .eq("id", note.id);
        if (updErr) {
          errors.push({ id: note.id, reason: updErr.message });
        } else {
          processed++;
        }
      } catch (e) {
        errors.push({ id: note.id, reason: `${e}` });
      }
    }

    return new Response(
      JSON.stringify({
        processed,
        skipped,
        errors,
        total: targets.length,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[reembed-missing] handler error:", e);
    return new Response(JSON.stringify({ error: `${e}` }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
