// Centralized environment variable access for all edge functions.
// Throws at startup if required vars are missing — no silent fallbacks
// to hardcoded model names that may not exist on your LLM router.

function required(name: string): string {
  const val = Deno.env.get(name);
  if (!val) {
    throw new Error(
      `Missing required env var: ${name}. Set it via: supabase secrets set ${name}=<value>`,
    );
  }
  return val;
}

function optional(name: string, fallback: string): string {
  return Deno.env.get(name) || fallback;
}

export const ENV = {
  /** OpenAI-compatible API key (required). */
  OPENAI_API_KEY: () => required("OPENAI_API_KEY"),

  /** Base URL for the OpenAI-compatible endpoint (required).
   *  Examples:
   *    - https://api.openai.com/v1
   *    - https://models.github.ai/inference
   *    - https://your-router.example.com/v1
   */
  OPENAI_BASE_URL: () => required("OPENAI_BASE_URL"),

  /** Chat/completion model name (required).
   *  Must match exactly what your LLM router expects. */
  OPENAI_CHAT_MODEL: () => required("OPENAI_CHAT_MODEL"),

  /** Embedding model name. Falls back to text-embedding-3-small if unset,
   *  since most OpenAI-compatible routers support this model name. */
  OPENAI_EMBED_MODEL: () =>
    optional("OPENAI_EMBED_MODEL", "text-embedding-3-small"),

  // Supabase infra (always available in edge functions)
  SUPABASE_URL: () => required("SUPABASE_URL"),
  SUPABASE_ANON_KEY: () => required("SUPABASE_ANON_KEY"),
  SUPABASE_SERVICE_ROLE_KEY: () => required("SUPABASE_SERVICE_ROLE_KEY"),
};
