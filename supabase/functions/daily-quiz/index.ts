// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: daily-quiz
//
// Returns the user's quiz for today — the pet's daily meal: three
// multiple-choice questions about their own notes. Idempotent per user per
// day (the app sends its local date, so "today" follows the user).
//
// Cheap by design: questions come from a bank (`note_questions`) written
// once per note. Only notes that don't have questions yet go to the LLM,
// in one batched call, so a day with no new notes costs no LLM call.
//
// Picking today's three:
//   * up to 2 fresh questions (never shown before), newest notes first;
//   * 1 review: a question that's due again (`next_show_after` ≤ today),
//     the ones marked "hard" first;
//   * at most one question per note when there's enough to choose from;
//   * if everything is still cooling down, the least recently due ones.
//
// Notes the user keeps out of the quizzes (`in_quiz` false — a saved comic
// or book title, say) are skipped: they don't count, get no questions
// written, and their questions already in the bank aren't picked.
//
// Needs at least 3 notes; below that it answers 422 with
// { code: "not_enough_notes", noteCount }.
//
// Body: { "locale": "id" | "en", "date": "YYYY-MM-DD" }
// Deploy: supabase functions deploy daily-quiz

import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";
import { CHAT_EXTRA } from "../_shared/ai.ts";
import { standalone } from "../_shared/quiz.ts";
import { PUBLIC_KEY, SECRET_KEY, SUPABASE_URL } from "../_shared/env.ts";
import { takeQuota } from "../_shared/quota.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const _baseURL = Deno.env.get("OPENAI_BASE_URL");
const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY")!,
  ...(_baseURL ? { baseURL: _baseURL } : {}),
});
const CHAT_MODEL =
  Deno.env.get("OPENAI_CHAT_MODEL") ??
  Deno.env.get("OPENAI_MODEL") ??
  (() => {
    throw new Error("Missing OPENAI_CHAT_MODEL env var");
  })();

const QUESTIONS_PER_DAY = 3;
const MIN_NOTES = 3;
/** Questions written for each note that doesn't have any yet. */
const PER_NOTE = 2;
/** How many question-less notes get written up per call (newest first). */
const WRITE_BATCH = 6;

interface QuizQuestion {
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  sourceNoteId: string | null;
  questionHash: string;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Today's date in UTC as YYYY-MM-DD (fallback when the app sends none). */
function utcToday(): string {
  return new Date().toISOString().slice(0, 10);
}

/** Whether [date] (yyyy-mm-dd) is today somewhere on Earth — the app's
 * local date is never more than a day off the server's. */
function nearToday(date: string): boolean {
  const day = 86_400_000;
  const diff = Date.parse(`${date}T00:00:00Z`) - Date.parse(`${utcToday()}T00:00:00Z`);
  return Math.abs(diff) <= day;
}

/** Stable hash of question + correct answer (same as the weekly quiz). */
async function hashQuestion(q: string, correctOption: string): Promise<string> {
  const norm = (s: string) => s.toLowerCase().replace(/\s+/g, " ").trim();
  const data = new TextEncoder().encode(`${norm(q)}|${norm(correctOption)}`);
  const buf = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Writes questions for [notes] with the LLM and stores them in the bank. */
async function writeQuestions(
  notes: any[],
  userId: string,
  isEn: boolean,
  admin: any,
): Promise<void> {
  if (notes.length === 0) return;
  const notesBlock = notes
    .map((n: any, i: number) => {
      const title = n.title?.trim() || (isEn ? "(untitled)" : "(tanpa judul)");
      const body = (n.manual_notes ?? "").trim().slice(0, 700);
      const tags =
        Array.isArray(n.tags) && n.tags.length ? ` [${n.tags.join(", ")}]` : "";
      return `[${i + 1}] note-id=${n.id}\nTitle: ${title}${tags}\n${isEn ? "Content" : "Isi"}: ${body}`;
    })
    .join("\n\n---\n\n");

  const total = notes.length * PER_NOTE;
  const system = isEn
    ? `You write short review questions to help the user remember their own notes.
For EACH note, write ${PER_NOTE} multiple-choice questions in English.

STRICT RULES:
- Output MUST be valid JSON: {"questions":[{"question":"...","options":["...","...","...","..."],"correctIndex":0,"explanation":"...","sourceNoteId":"..."}, ...]}
- ${total} questions in total, ${PER_NOTE} per note. Exactly 4 options each.
- correctIndex: integer 0-3. Vary the position of the right answer.
- explanation: 1 short sentence in English.
- sourceNoteId: copy verbatim from "note-id=..." of the note the question is about.
- The answer comes from the note's content, not general knowledge.
- Each question stands on its own: the user answers without seeing the note, so name the topic directly (e.g. "What's the main difference between Supabase and Firebase?"). Never refer to the note itself ("according to the note", "in this note", "the note above").
- Ask about the key idea, tip, step, fact or insight worth remembering, not trivia like dates or URLs.
- Keep questions short (one line) and the wrong options plausible.`
    : `Kamu menulis pertanyaan review singkat untuk membantu user mengingat catatannya sendiri.
Untuk SETIAP catatan, tulis ${PER_NOTE} pertanyaan pilihan ganda dalam Bahasa Indonesia.

ATURAN KETAT:
- Output WAJIB JSON: {"questions":[{"question":"...","options":["...","...","...","..."],"correctIndex":0,"explanation":"...","sourceNoteId":"..."}, ...]}
- Total ${total} pertanyaan, ${PER_NOTE} per catatan. Tepat 4 opsi per pertanyaan.
- correctIndex: integer 0-3. Variasikan posisi jawaban yang benar.
- explanation: 1 kalimat singkat dalam Bahasa Indonesia.
- sourceNoteId: SALIN persis dari "note-id=…" catatan yang ditanyakan.
- Jawabannya diambil dari isi catatan, bukan pengetahuan umum.
- Setiap pertanyaan harus berdiri sendiri: user menjawab tanpa melihat catatannya, jadi sebut topiknya langsung (mis. "Apa beda utama Supabase dan Firebase?"). JANGAN merujuk ke catatannya ("berdasarkan catatan", "menurut catatan", "catatan tersebut/ini", "di atas").
- Tanyakan ide utama, tips, langkah, fakta, atau insight yang layak diingat, bukan trivia seperti tanggal atau URL.
- Pertanyaan singkat (satu baris), opsi salah tetap masuk akal.`;

  const completion = await openai.chat.completions.create({
    ...CHAT_EXTRA,
    model: CHAT_MODEL,
    temperature: 0.5,
    response_format: { type: "json_object" },
    messages: [
      { role: "system", content: system },
      {
        role: "user",
        content: `${isEn ? "My notes" : "Catatan saya"}:\n\n${notesBlock}`,
      },
    ],
  });

  let parsed: any;
  try {
    parsed = JSON.parse(completion.choices[0]?.message?.content ?? "");
  } catch (_) {
    console.error("[daily-quiz] LLM returned non-JSON");
    return;
  }
  const list = Array.isArray(parsed?.questions) ? parsed.questions : [];
  const valid = new Set(notes.map((n: any) => n.id as string));
  const rows: any[] = [];
  const seen = new Set<string>();
  for (const q of list) {
    if (typeof q?.question !== "string") continue;
    if (!Array.isArray(q?.options) || q.options.length !== 4) continue;
    if (q.options.some((o: any) => typeof o !== "string")) continue;
    const idx = Number(q.correctIndex);
    if (!Number.isInteger(idx) || idx < 0 || idx > 3) continue;
    if (typeof q.sourceNoteId !== "string" || !valid.has(q.sourceNoteId)) {
      continue;
    }
    const options = q.options.map((o: string) => o.trim());
    const question = standalone(q.question);
    const hash = await hashQuestion(question, options[idx]);
    if (seen.has(hash)) continue;
    seen.add(hash);
    rows.push({
      user_id: userId,
      note_id: q.sourceNoteId,
      question,
      options,
      correct_index: idx,
      explanation: typeof q.explanation === "string" ? q.explanation.trim() : "",
      question_hash: hash,
      locale: isEn ? "en" : "id",
    });
  }
  if (rows.length === 0) return;
  const { error } = await admin
    .from("note_questions")
    .upsert(rows, { onConflict: "user_id,question_hash", ignoreDuplicates: true });
  if (error) console.error("[daily-quiz] bank insert:", error);
}

function toQuestion(row: any): QuizQuestion {
  return {
    question: standalone(row.question),
    options: row.options,
    correctIndex: row.correct_index,
    explanation: row.explanation ?? "",
    sourceNoteId: row.note_id ?? null,
    questionHash: row.question_hash,
  };
}

function response(row: any) {
  return {
    id: row.id,
    kind: "daily",
    weekStart: row.quiz_date,
    quizDate: row.quiz_date,
    // Questions written before they had to stand on their own, cleaned too.
    questions: (row.questions ?? []).map((q: any) => ({ ...q, question: standalone(q.question ?? "") })),
    sourceNoteIds: row.source_note_ids ?? [],
    userAnswers: row.user_answers ?? null,
    completedAt: row.completed_at ?? null,
    score: row.score ?? null,
    noteCount: (row.source_note_ids ?? []).length,
    targetCount: QUESTIONS_PER_DAY,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Set once the body's read, so a failure can still answer in the user's
  // language.
  let isEn = false;
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Missing auth" }, 401);

    const supabase = createClient(
      SUPABASE_URL,
      PUBLIC_KEY,
      {
        db: { schema: "ingatanku" },
        global: { headers: { Authorization: authHeader } },
      },
    );
    const admin = createClient(
      SUPABASE_URL,
      SECRET_KEY,
      { db: { schema: "ingatanku" } },
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return json({ error: "Unauthorized" }, 401);
    const userId = user.id;

    let locale = "id";
    let today = utcToday();
    try {
      const body = await req.json();
      if (body && typeof body.locale === "string") locale = body.locale;
      if (body && /^\d{4}-\d{2}-\d{2}$/.test(body.date ?? "") && nearToday(body.date)) {
        today = body.date;
      }
    } catch (_) {
      /* no body */
    }
    isEn = locale === "en";

    // 1) Today's quiz already exists? Return it.
    const { data: existing } = await supabase
      .from("daily_quizzes")
      .select(
        "id, quiz_date, questions, source_note_ids, user_answers, completed_at, score",
      )
      .eq("user_id", userId)
      .eq("quiz_date", today)
      .maybeSingle();
    if (existing) return json(response(existing));

    // 2) Enough notes to quiz on?
    const { data: notes, error: notesError } = await supabase
      .from("content_vault")
      .select("id, title, manual_notes, tags, created_at")
      .eq("user_id", userId)
      .eq("in_quiz", true)
      .order("created_at", { ascending: false })
      .limit(60);
    if (notesError) throw notesError;
    const noteCount = notes?.length ?? 0;
    if (noteCount < MIN_NOTES) {
      return json(
        {
          code: "not_enough_notes",
          noteCount,
          error: isEn
            ? `Save at least ${MIN_NOTES} notes to unlock the daily quiz.`
            : `Simpan minimal ${MIN_NOTES} catatan untuk membuka kuis harian.`,
        },
        422,
      );
    }

    // 3) Write questions for the newest notes that don't have any yet.
    const noteIds = notes.map((n: any) => n.id as string);
    const { data: banked } = await supabase
      .from("note_questions")
      .select("note_id")
      .eq("user_id", userId)
      .in("note_id", noteIds);
    const covered = new Set((banked ?? []).map((r: any) => r.note_id as string));
    const missing = notes
      .filter((n: any) => !covered.has(n.id) && (n.manual_notes ?? "").trim())
      .slice(0, WRITE_BATCH);
    try {
      // One LLM call from the day's "quiz" allowance; without it, today's
      // meal comes from the questions already in the bank.
      if (missing.length > 0 && (await takeQuota(supabase, "quiz"))) {
        await writeQuestions(missing, userId, isEn, admin);
      }
    } catch (e) {
      // Not fatal: older questions can still make today's meal.
      console.error("[daily-quiz] writing questions:", e);
    }

    // 4) The bank, and what's been shown before.
    const { data: bank } = await supabase
      .from("note_questions")
      .select(
        "note_id, question, options, correct_index, explanation, question_hash, created_at",
      )
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(400);
    const { data: history } = await supabase
      .from("quiz_question_history")
      .select("question_hash, difficulty, next_show_after, next_show_after_week")
      .eq("user_id", userId);
    // Notes kept out of the quizzes: their questions stay in the bank (for
    // if the note's switched back on) but aren't picked.
    const { data: keptOutRows } = await supabase
      .from("content_vault")
      .select("id")
      .eq("user_id", userId)
      .eq("in_quiz", false);
    const keptOut = new Set((keptOutRows ?? []).map((r: any) => r.id as string));

    // Latest spacing per question (a question can have one row per week).
    const seen = new Map<string, { due: string; difficulty: string }>();
    for (const h of history ?? []) {
      const due = (h.next_show_after ?? h.next_show_after_week) as string;
      const prev = seen.get(h.question_hash);
      if (!prev || due > prev.due) {
        seen.set(h.question_hash, { due, difficulty: h.difficulty });
      }
    }

    const fresh: any[] = [];
    const due: any[] = [];
    const waiting: any[] = [];
    for (const q of bank ?? []) {
      if (keptOut.has(q.note_id)) continue;
      const s = seen.get(q.question_hash);
      if (!s) fresh.push(q);
      else if (s.difficulty === "banned") continue;
      else if (s.due <= today) due.push({ ...q, _s: s });
      else waiting.push({ ...q, _s: s });
    }
    // Hard ones first, then the longest overdue.
    const rank = (d: string) => (d === "hard" ? 0 : d === "medium" ? 1 : 2);
    due.sort(
      (a, b) =>
        rank(a._s.difficulty) - rank(b._s.difficulty) ||
        a._s.due.localeCompare(b._s.due),
    );
    waiting.sort((a, b) => a._s.due.localeCompare(b._s.due));

    // 5) Pick today's three, one per note while there's choice.
    const picked: any[] = [];
    const usedNotes = new Set<string>();
    const take = (pool: any[], max: number, strict: boolean) => {
      for (const q of pool) {
        if (picked.length >= QUESTIONS_PER_DAY || max <= 0) break;
        if (picked.includes(q)) continue;
        if (strict && usedNotes.has(q.note_id)) continue;
        picked.push(q);
        usedNotes.add(q.note_id);
        max--;
      }
    };
    take(fresh, 2, true);
    take(due, QUESTIONS_PER_DAY - picked.length, true);
    take(fresh, QUESTIONS_PER_DAY - picked.length, true);
    take(fresh, QUESTIONS_PER_DAY - picked.length, false);
    take(due, QUESTIONS_PER_DAY - picked.length, false);
    take(waiting, QUESTIONS_PER_DAY - picked.length, false);

    if (picked.length === 0) {
      return json(
        {
          error: isEn
            ? "Couldn't make today's quiz. Try again in a bit."
            : "Gagal menyiapkan kuis hari ini. Coba lagi sebentar lagi.",
        },
        502,
      );
    }

    // Fresh questions first in the order they were picked, review last.
    const questions = picked.map(toQuestion);
    const sourceNoteIds = Array.from(
      new Set(questions.map((q) => q.sourceNoteId).filter((x) => !!x)),
    );

    // 6) Save today's quiz (service role), or pick up a parallel insert.
    const { data: inserted, error: insertError } = await admin
      .from("daily_quizzes")
      .insert({
        user_id: userId,
        quiz_date: today,
        questions,
        source_note_ids: sourceNoteIds,
      })
      .select(
        "id, quiz_date, questions, source_note_ids, user_answers, completed_at, score",
      )
      .single();
    if (insertError) {
      const { data: refetched } = await supabase
        .from("daily_quizzes")
        .select(
          "id, quiz_date, questions, source_note_ids, user_answers, completed_at, score",
        )
        .eq("user_id", userId)
        .eq("quiz_date", today)
        .maybeSingle();
      if (refetched) return json(response(refetched));
      throw insertError;
    }
    return json(response(inserted));
  } catch (e) {
    // Supabase errors are plain objects (`${e}` would read
    // "[object Object]"): the log gets all of it, the app a kind line.
    console.error("[daily-quiz] handler error:", e);
    return json(
      {
        error: isEn
          ? "Couldn't make today's quiz. Try again in a bit."
          : "Gagal menyiapkan kuis hari ini. Coba lagi sebentar lagi.",
      },
      500,
    );
  }
});
