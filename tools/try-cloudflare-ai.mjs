#!/usr/bin/env node
// Tries Cloudflare Workers AI the way IngatanKu's edge functions use an AI
// provider: embeddings for the assistant's search (bge-m3), and for each chat
// model that fits the free allocation, a pet-style answer from notes, a
// streamed answer and a quiz in JSON. Prints the answers, how long each took
// and the neurons it used, so the models can be compared before choosing.
//
//   CF_ACCOUNT_ID=<account id> CF_API_TOKEN=<token> node tools/try-cloudflare-ai.mjs [model ...]
//
// AI_CHAT_EXTRA (JSON, like the edge functions' secret) is added to every
// chat request, e.g. '{"chat_template_kwargs":{"enable_thinking":false}}'.
//
// Needs Node 18+. Nothing here is sent anywhere but Cloudflare.

const ACCOUNT = process.env.CF_ACCOUNT_ID;
const TOKEN = process.env.CF_API_TOKEN;
if (!ACCOUNT || !TOKEN) {
  console.error('Set CF_ACCOUNT_ID and CF_API_TOKEN first.');
  process.exit(1);
}
const BASE = `https://api.cloudflare.com/client/v4/accounts/${ACCOUNT}/ai/v1`;

// Neurons per million input / output tokens (Workers AI pricing page, Oct 2026).
// The free allocation is 10,000 neurons a day.
const NEURONS = {
  '@cf/qwen/qwen3-30b-a3b-fp8': [4625, 30475],
  '@cf/google/gemma-4-26b-a4b-it': [9091, 27273],
  '@cf/zai-org/glm-4.7-flash': [5500, 36400],
  '@cf/openai/gpt-oss-20b': [18182, 27273],
};
const EMBED_MODEL = '@cf/baai/bge-m3';
const EXTRA = JSON.parse(process.env.AI_CHAT_EXTRA || '{}');
const EMBED_NEURONS = 1075;
const chatModels = process.argv.length > 2 ? process.argv.slice(2) : Object.keys(NEURONS);

// What 10 testers use in a day (rough, from the app's prompts): tokens in / out.
const DAY_IN = 333_000;
const DAY_OUT = 50_000;

let neuronsUsed = 0;
const neurons = (model, usage) => {
  const [i, o] = NEURONS[model] ?? [0, 0];
  const n = ((usage?.prompt_tokens ?? 0) * i + (usage?.completion_tokens ?? 0) * o) / 1e6;
  neuronsUsed += n;
  return n;
};

async function post(path, body) {
  const t0 = Date.now();
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${text.slice(0, 300)}`);
  return { json: JSON.parse(text), ms: Date.now() - t0 };
}

const line = (s = '') => console.log(s);
const head = (s) => line(`\n━━ ${s} ${'━'.repeat(Math.max(0, 66 - s.length))}`);

// ── Embeddings ──────────────────────────────────────────────────────

const NOTES = [
  'Chicken teriyaki: marinate chicken thighs in soy sauce, mirin and honey, then pan-fry until glazed.',
  'Sambal matah khas Bali: iris bawang merah, cabai rawit dan serai, siram minyak kelapa panas, beri perasan jeruk limau.',
  'Itinerary 3 hari di Lombok: hari 1 Gili Trawangan, hari 2 Pantai Pink, hari 3 Bukit Merese saat matahari terbenam.',
  'Cara merawat tanaman monstera: siram seminggu sekali, taruh di tempat terang tapi tidak kena matahari langsung.',
];
const QUESTIONS = [
  ['resep ayam yang pernah aku simpan', 0],
  ['makanan pedas apa yang bisa kumasak?', 1],
  ['tempat liburan dekat pantai', 2],
  ['how do I take care of my houseplant?', 3],
];

const cosine = (a, b) => {
  let dot = 0, na = 0, nb = 0;
  for (let i = 0; i < a.length; i++) { dot += a[i] * b[i]; na += a[i] * a[i]; nb += b[i] * b[i]; }
  return dot / Math.sqrt(na * nb);
};

async function tryEmbeddings() {
  head(`Embedding: ${EMBED_MODEL}`);
  const texts = [...NOTES, ...QUESTIONS.map(([q]) => q)];
  const { json, ms } = await post('/embeddings', { model: EMBED_MODEL, input: texts });
  const vecs = json.data.map((d) => d.embedding);
  const tokens = json.usage?.prompt_tokens ?? 0;
  neuronsUsed += (tokens * EMBED_NEURONS) / 1e6;
  line(`${vecs.length} texts, ${vecs[0].length} dimensions, ${ms} ms, ${tokens} tokens`);
  let right = 0;
  for (const [i, [q, want]] of QUESTIONS.entries()) {
    const scores = NOTES.map((_, j) => cosine(vecs[NOTES.length + i], vecs[j]));
    const best = scores.indexOf(Math.max(...scores));
    if (best === want) right++;
    line(`${best === want ? '✓' : '✗'} "${q}" → ${NOTES[best].slice(0, 48)}…  (${scores[best].toFixed(3)})`);
  }
  line(`${right}/${QUESTIONS.length} found the right note`);

  // The edge functions ask for `dimensions` first and retry without it.
  try {
    await post('/embeddings', { model: EMBED_MODEL, input: 'tes', dimensions: 1024 });
    line('`dimensions` accepted');
  } catch (e) {
    line(`\`dimensions\` refused (the functions then retry without it): ${String(e.message).slice(0, 80)}`);
  }
}

// ── Chat ────────────────────────────────────────────────────────────

const SYSTEM = `Kamu adalah Bolubi, peliharaan virtual milik user di aplikasi IngatanKu: makhluk mungil yang "makan" catatan yang user simpan dan mengingat semuanya. Kamu juga asisten pribadi user: jawab pertanyaan mereka dari catatan yang sudah mereka simpan.

CARA KAMU NGOBROL:
- Sebut dirimu "aku" dan panggil user "kamu". Bahasa sehari-hari yang santai, kalimat pendek, hangat dan ekspresif.
- Kalimat PERTAMAmu selalu reaksi singkat yang berdiri sendiri (maksimal 10 kata, tanpa nomor sumber), misalnya "Wah, yang ini aku ingat banget! 😋".
- Tutup dengan satu kalimat pendek ala kamu. Emoji maksimal 1-2. Jangan pakai em dash (—).

ATURAN:
- Jawab dalam Bahasa Indonesia yang santai dan natural.
- Utamakan informasi dari CONTEXT. Cite sumber pakai [1], [2] sesuai nomor catatan, hanya kalau memang ada di CONTEXT.

CONTEXT:
[1] Chicken teriyaki
Marinasi paha ayam dengan kecap asin, mirin dan madu 30 menit, lalu panggang di wajan sampai mengilap. Taburi wijen.

[2] Sambal matah khas Bali
Iris bawang merah, cabai rawit dan serai, siram minyak kelapa panas, beri perasan jeruk limau dan sedikit garam.`;
const QUESTION = 'resep ayam apa yang pernah aku simpan?';

const QUIZ_PROMPT = `Buat 2 soal pilihan ganda dari catatan ini. Output WAJIB JSON: {"questions":[{"question":"...","options":["...","...","...","..."],"correctIndex":0,"explanation":"..."}]}

Catatan: Itinerary 3 hari di Lombok. Hari 1 ke Gili Trawangan naik kapal dari Bangsal. Hari 2 ke Pantai Pink di Lombok Timur. Hari 3 sunset di Bukit Merese dekat Kuta Mandalika.`;

const thinks = (text) => /<think>|<\/think>/.test(text ?? '');

async function tryChat(model) {
  head(`Chat: ${model}`);
  const messages = [{ role: 'system', content: SYSTEM }, { role: 'user', content: QUESTION }];

  // 1) A whole answer.
  try {
    const { json, ms } = await post('/chat/completions', { model, messages, temperature: 0.7, ...EXTRA });
    const msg = json.choices?.[0]?.message ?? {};
    const n = neurons(model, json.usage);
    line(`Answer (${ms} ms, ${json.usage?.prompt_tokens}→${json.usage?.completion_tokens} tokens, ${n.toFixed(1)} neurons):`);
    line((msg.content ?? '(empty)').trim());
    if (thinks(msg.content)) line('⚠ the answer includes <think> reasoning: it would show in the app');
    if (msg.reasoning_content || msg.reasoning) line('ℹ reasoning came in a separate field (not shown in the app)');
  } catch (e) {
    line(`✗ answer failed: ${e.message}`);
  }

  // 2) Streamed, as ask-brain and auto-summarize read it.
  try {
    const t0 = Date.now();
    const res = await fetch(`${BASE}/chat/completions`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model, messages, stream: true, ...EXTRA }),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
    const decoder = new TextDecoder();
    let first = null, chunks = 0, text = '', buf = '';
    for await (const part of res.body) {
      buf += decoder.decode(part, { stream: true });
      const lines = buf.split('\n');
      buf = lines.pop();
      for (const l of lines) {
        if (!l.startsWith('data:')) continue;
        const data = l.slice(5).trim();
        if (!data || data === '[DONE]') continue;
        const delta = JSON.parse(data).choices?.[0]?.delta?.content ?? '';
        if (delta) { first ??= Date.now() - t0; chunks++; text += delta; }
      }
    }
    line(`Stream: first words after ${first ?? '-'} ms, ${chunks} chunks, ${Date.now() - t0} ms in all${thinks(text) ? ', ⚠ <think> in the stream' : ''}`);
  } catch (e) {
    line(`✗ stream failed: ${e.message}`);
  }

  // 3) A quiz in JSON, as daily-quiz and generate-weekly-quiz ask for it.
  try {
    const { json, ms } = await post('/chat/completions', {
      ...EXTRA,
      model,
      temperature: 0.6,
      response_format: { type: 'json_object' },
      messages: [{ role: 'user', content: QUIZ_PROMPT }],
    });
    neurons(model, json.usage);
    const raw = (json.choices?.[0]?.message?.content ?? '').replace(/<think>[\s\S]*?<\/think>/g, '').trim();
    const parsed = JSON.parse(raw.replace(/^```(?:json)?\s*|\s*```$/g, ''));
    const qs = parsed.questions ?? [];
    const ok = qs.length > 0 && qs.every((q) => Array.isArray(q.options) && q.options.length === 4 && Number.isInteger(q.correctIndex));
    line(`Quiz JSON (${ms} ms): ${ok ? '✓' : '✗'} ${qs.length} questions${ok ? `, e.g. "${qs[0].question}"` : ''}`);
  } catch (e) {
    line(`✗ quiz JSON failed: ${String(e.message).slice(0, 200)}`);
  }

  const [i, o] = NEURONS[model] ?? [0, 0];
  const perDay = (DAY_IN * i + DAY_OUT * o) / 1e6;
  line(`10 testers a day ≈ ${Math.round(perDay)} neurons (${Math.round(perDay / 100)}% of the free 10,000)`);
}

try {
  await tryEmbeddings();
} catch (e) {
  line(`✗ embeddings failed: ${e.message}`);
}
for (const model of chatModels) await tryChat(model);
head('Done');
line(`This run used about ${Math.round(neuronsUsed)} neurons.`);
