// Each user's daily AI allowance (ingatanku.ai_usage, through
// consume_ai_quota). Limits per kind of request can be changed with
// secrets, e.g. `supabase secrets set AI_LIMIT_ASK=100`.

export type QuotaKind = "ask" | "summarize" | "quiz" | "embed";

const DEFAULTS: Record<QuotaKind, number> = {
  ask: 60, // assistant questions
  summarize: 40, // link write-ups
  quiz: 20, // LLM calls writing quiz questions
  embed: 300, // notes embedded (saving, editing, re-indexing)
};

export function limitFor(kind: QuotaKind): number {
  const v = Number(Deno.env.get(`AI_LIMIT_${kind.toUpperCase()}`));
  return Number.isFinite(v) && v > 0 ? v : DEFAULTS[kind];
}

/** Takes [amount] from the user's allowance for [kind] today. [client]
 * must carry the user's token. False when it's used up — or when it can't
 * be checked, so a fault never turns into unmetered AI calls. */
export async function takeQuota(
  // deno-lint-ignore no-explicit-any
  client: any,
  kind: QuotaKind,
  amount = 1,
): Promise<boolean> {
  const { data, error } = await client.rpc("consume_ai_quota", {
    p_kind: kind,
    p_limit: limitFor(kind),
    p_amount: amount,
  });
  if (error) {
    console.error(`[quota] ${kind}:`, error.message);
    return false;
  }
  return data === true;
}
