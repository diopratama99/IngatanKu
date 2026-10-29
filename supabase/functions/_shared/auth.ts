import { PUBLIC_KEY, SUPABASE_URL } from "./env.ts";

/** The signed-in user the request comes from, asked of Supabase Auth with
 * the token it carries; null without a valid one. For functions that need
 * nothing else from supabase-js. */
export async function requestUser(req: Request): Promise<{ id: string } | null> {
  const auth = req.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) return null;
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: auth, apikey: PUBLIC_KEY },
    });
    if (!res.ok) return null;
    const user = await res.json();
    return typeof user?.id === "string" ? user : null;
  } catch {
    return null;
  }
}
