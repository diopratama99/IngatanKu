// Fields added to every chat request, for what a provider needs beyond the
// OpenAI API, from the AI_CHAT_EXTRA secret (JSON). On Cloudflare Workers AI,
// gemma-4 answers in ~2 s instead of ~20 s with its thinking turned off:
//   AI_CHAT_EXTRA='{"chat_template_kwargs":{"enable_thinking":false}}'
// Leave it unset for providers that need nothing extra (e.g. DeepSeek).
export const CHAT_EXTRA: Record<string, unknown> = (() => {
  const raw = Deno.env.get("AI_CHAT_EXTRA");
  if (!raw) return {};
  try {
    const value = JSON.parse(raw);
    return value && typeof value === "object" && !Array.isArray(value) ? value : {};
  } catch {
    console.error("[ai] AI_CHAT_EXTRA isn't a JSON object; ignored");
    return {};
  }
})();
