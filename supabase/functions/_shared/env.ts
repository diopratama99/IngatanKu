// The project's API keys, under either key system: the new publishable /
// secret keys (SUPABASE_PUBLISHABLE_KEYS / SUPABASE_SECRET_KEYS, JSON keyed
// by name) when the project has them, else the legacy anon / service_role
// keys.

function defaultKey(name: string): string | undefined {
  const raw = Deno.env.get(name);
  if (!raw) return undefined;
  try {
    const keys = JSON.parse(raw);
    return typeof keys?.default === "string" ? keys.default : undefined;
  } catch {
    return undefined;
  }
}

export const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;

/** For clients that act as the signed-in user (with their token). */
export const PUBLIC_KEY =
  defaultKey("SUPABASE_PUBLISHABLE_KEYS") ?? Deno.env.get("SUPABASE_ANON_KEY")!;

/** For the service role: bypasses RLS, so only for writes users may not make. */
export const SECRET_KEY =
  defaultKey("SUPABASE_SECRET_KEYS") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
