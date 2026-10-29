// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: beta-signup
//
// The landing page's "Join the beta" form. Public (no sign-in): it checks
// what it's given, slows down floods and keeps one row per email in
// `ingatanku.beta_signups`.
//
// Input:  { email, name?, locale?: 'en' | 'id', website? }
//         (`website` is a field only bots fill in.)
// Output: { ok: true }, or { error } with 400 / 429 / 500.

import { createClient } from "@supabase/supabase-js";
import { SECRET_KEY, SUPABASE_URL } from "../_shared/env.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
/** Sign-ups allowed from one IP in an hour. */
const PER_HOUR = 5;

function reply(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

async function hash(text: string) {
  const bytes = new TextEncoder().encode(`ingatanku-beta:${text}`);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ error: "POST only" }, 405);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return reply({ error: "invalid json" }, 400);
  }

  // A bot filled in the hidden field: say yes, keep nothing.
  if (typeof body.website === "string" && body.website.trim() !== "") {
    return reply({ ok: true });
  }

  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  if (email.length > 254 || !EMAIL.test(email)) {
    return reply({ error: "invalid email" }, 400);
  }
  const name = typeof body.name === "string" ? body.name.trim().slice(0, 60) || null : null;
  const locale = body.locale === "id" ? "id" : "en";

  const ip = (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim();
  const ipHash = ip ? await hash(ip) : null;

  const db = createClient(SUPABASE_URL, SECRET_KEY, {
    db: { schema: "ingatanku" },
    auth: { persistSession: false },
  });

  try {
    if (ipHash) {
      const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
      const { count, error } = await db
        .from("beta_signups")
        .select("id", { count: "exact", head: true })
        .eq("ip_hash", ipHash)
        .gte("created_at", since);
      if (error) throw error;
      if ((count ?? 0) >= PER_HOUR) return reply({ error: "too many" }, 429);
    }

    // Signing up twice is fine: the first one stands.
    const { error } = await db
      .from("beta_signups")
      .upsert({ email, name, locale, ip_hash: ipHash }, { onConflict: "email", ignoreDuplicates: true });
    if (error) throw error;
    return reply({ ok: true });
  } catch (e) {
    console.error("beta-signup:", e?.message ?? e);
    return reply({ error: "could not save" }, 500);
  }
});
