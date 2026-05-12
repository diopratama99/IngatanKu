// Shared OpenAI-compatible client instance.
// Uses ENV.OPENAI_BASE_URL so it works with any OpenAI-compatible router
// (OpenRouter, Together, vLLM, LiteLLM, custom proxy, etc).

import OpenAI from "https://esm.sh/openai@4.56.0";
import { ENV } from "./env.ts";

/** Lazily-initialized singleton. Call `getOpenAI()` instead of constructing
 *  your own `new OpenAI(...)` — ensures baseURL and apiKey come from env. */
let _instance: OpenAI | null = null;

export function getOpenAI(): OpenAI {
  if (!_instance) {
    _instance = new OpenAI({
      apiKey: ENV.OPENAI_API_KEY(),
      baseURL: ENV.OPENAI_BASE_URL(),
    });
  }
  return _instance;
}
