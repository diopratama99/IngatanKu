// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: generate-weekly-quiz
//
// Mengembalikan quiz user untuk minggu berjalan. Kalau belum ada,
// generate adaptif:
//   * Jumlah soal scaling dari aktivitas (5..15 berdasarkan note baru
//     minggu ini).
//   * 70% soal baru dari note minggu ini, 30% recall soal "hard" yang
//     due review.
//   * Exclude soal yang user tandain "easy" / "medium" yang masih di
//     periode cooldown (next_show_after_week > minggu ini).
//   * Note yang user keluarkan dari kuis (`in_quiz` false, mis. link
//     judul komik/buku) dilewati: gak jadi soal baru, soal "hard"-nya
//     juga gak di-recall.
//
// Idempotent — call kedua di minggu sama akan return row yang sudah
// di-persist tanpa generate ulang.
//
// Deploy: supabase functions deploy generate-weekly-quiz

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

const QUIZ_MIN = 5;
const QUIZ_MAX = 15;
const HARD_RECALL_RATIO = 0.3;

/** Returns the Monday of the week containing [d], at 00:00:00 UTC. */
function weekStartMonday(d: Date): string {
  const local = new Date(d);
  const day = local.getUTCDay();
  const diff = day === 0 ? -6 : 1 - day;
  local.setUTCDate(local.getUTCDate() + diff);
  local.setUTCHours(0, 0, 0, 0);
  const yyyy = local.getUTCFullYear();
  const mm = String(local.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(local.getUTCDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

interface QuizQuestion {
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  sourceNoteId: string | null;
  questionHash: string;
}

/// Stable hash dari question + correct answer text. Pakai SubtleCrypto
/// supaya deterministic across runs (web crypto bawaan Deno).
async function hashQuestion(q: string, correctOption: string): Promise<string> {
  const norm = (s: string) => s.toLowerCase().replace(/\s+/g, " ").trim();
  const data = new TextEncoder().encode(`${norm(q)}|${norm(correctOption)}`);
  const buf = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function sanitizeQuestions(
  raw: any,
  validNoteIds: Set<string>,
  excludedHashes: Set<string>,
  maxCount: number,
): Promise<QuizQuestion[]> {
  const list = Array.isArray(raw?.questions) ? raw.questions : null;
  if (!list) return [];

  const out: QuizQuestion[] = [];
  for (const q of list) {
    if (typeof q?.question !== "string") continue;
    if (!Array.isArray(q?.options) || q.options.length !== 4) continue;
    if (q.options.some((o: any) => typeof o !== "string")) continue;
    const idx = Number(q.correctIndex);
    if (!Number.isInteger(idx) || idx < 0 || idx > 3) continue;
    const explanation = typeof q.explanation === "string" ? q.explanation : "";
    const noteId =
      typeof q.sourceNoteId === "string" && validNoteIds.has(q.sourceNoteId)
        ? q.sourceNoteId
        : null;

    const correctOption = q.options[idx];
    const question = standalone(q.question);
    const hash = await hashQuestion(question, correctOption);
    if (excludedHashes.has(hash)) continue;

    out.push({
      question,
      options: q.options.map((o: string) => o.trim()),
      correctIndex: idx,
      explanation: explanation.trim(),
      sourceNoteId: noteId,
      questionHash: hash,
    });
    if (out.length >= maxCount) break;
  }
  return out;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Diisi begitu body terbaca, supaya error pun dijawab dalam bahasa user.
  let isEn = false;
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing auth" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      SUPABASE_URL,
      PUBLIC_KEY,
      {
        db: { schema: "ingatanku" },
        global: { headers: { Authorization: authHeader } },
      },
    );
    const adminClient = createClient(
      SUPABASE_URL,
      SECRET_KEY,
      { db: { schema: "ingatanku" } },
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userId = user.id;
    const weekStart = weekStartMonday(new Date());

    let locale = "id";
    try {
      const body = await req.json();
      if (body && typeof body.locale === "string") locale = body.locale;
    } catch (_) {
      /* no body */
    }
    isEn = locale === "en";

    // 1) Already have a quiz for this week? Return as-is.
    const { data: existing } = await supabase
      .from("weekly_quizzes")
      .select(
        "id, week_start, questions, source_note_ids, user_answers, completed_at, score, target_count",
      )
      .eq("user_id", userId)
      .eq("week_start", weekStart)
      .maybeSingle();

    if (existing) {
      return new Response(
        JSON.stringify({
          id: existing.id,
          weekStart: existing.week_start,
          questions: (existing.questions ?? []).map((q: any) => ({ ...q, question: standalone(q.question ?? "") })),
          sourceNoteIds: existing.source_note_ids ?? [],
          userAnswers: existing.user_answers ?? null,
          completedAt: existing.completed_at,
          score: existing.score,
          noteCount: (existing.source_note_ids ?? []).length,
          targetCount: existing.target_count ?? 5,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 2) Pull last 7 days of notes for this user.
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setUTCDate(sevenDaysAgo.getUTCDate() - 7);

    const { data: notes, error: notesError } = await supabase
      .from("content_vault")
      .select("id, title, manual_notes, source_type, tags")
      .eq("user_id", userId)
      .eq("in_quiz", true)
      .gte("created_at", sevenDaysAgo.toISOString())
      .order("created_at", { ascending: false })
      .limit(30);

    if (notesError) throw notesError;
    const newNotesCount = notes?.length ?? 0;

    // 3) Hitung target count based on aktivitas.
    const targetCount = Math.max(QUIZ_MIN, Math.min(QUIZ_MAX, newNotesCount));

    // 4) Pull hard-due questions for recall.
    const hardSlot = Math.ceil(targetCount * HARD_RECALL_RATIO);
    const { data: hardDueRows } = await supabase
      .from("quiz_question_history")
      .select("question_hash, question_text, source_note_id")
      .eq("user_id", userId)
      .eq("difficulty", "hard")
      .lte("next_show_after_week", weekStart)
      .order("next_show_after_week", { ascending: true })
      .limit(hardSlot);

    // 5) Pull excluded hashes (cooldown not yet expired).
    const { data: excludedRows } = await supabase
      .from("quiz_question_history")
      .select("question_hash")
      .eq("user_id", userId)
      .gt("next_show_after_week", weekStart);
    const excludedHashes = new Set<string>(
      (excludedRows ?? []).map((r: any) => r.question_hash as string),
    );

    // Pre-load full question rows for hard-due (kita perlu options +
    // correctIndex + explanation utk recall). Karena tabel history cuma
    // simpan teks question, kita match balik ke weekly_quizzes by hash.
    // Lebih efisien: simpan full payload nanti waktu record-quiz-answer
    // (kita nge-store options + correctIndex juga). Untuk sekarang
    // recall mechanic disable kalau row gak ditemukan, just-in-case.
    const recalledQuestions: QuizQuestion[] = [];
    // (Rekomendasi: tabel quiz_question_history tambahin kolom
    // `payload jsonb` ke depan biar verbatim recall gampang.)
    // Sementara, kita cuma exclude hash yang cooldown — recall full
    // question bakal di-implement saat tabel sudah punya kolom payload.

    // Note yang dikeluarkan dari kuis: soal "hard"-nya gak di-recall.
    const { data: keptOutRows } = await supabase
      .from("content_vault")
      .select("id")
      .eq("user_id", userId)
      .eq("in_quiz", false);
    const keptOut = new Set((keptOutRows ?? []).map((r: any) => r.id as string));

    if (hardDueRows && hardDueRows.length > 0) {
      // Cari soal full di weekly_quizzes lama (jsonb questions[]) yang
      // hash-nya match. SQL native gak punya jsonb-cross-row matching
      // efisien; cara paling sederhana: ambil semua quiz user, scan
      // jsonb-nya in-memory. Quiz row jumlahnya kecil (~52/tahun).
      const targetHashes = new Set(
        hardDueRows.map((r: any) => r.question_hash as string),
      );
      const { data: pastQuizzes } = await supabase
        .from("weekly_quizzes")
        .select("questions")
        .eq("user_id", userId)
        .lt("week_start", weekStart)
        .order("week_start", { ascending: false })
        .limit(20);

      for (const row of pastQuizzes ?? []) {
        const qs = row.questions as any[];
        if (!Array.isArray(qs)) continue;
        for (const q of qs) {
          if (recalledQuestions.length >= hardSlot) break;
          if (typeof q?.question !== "string") continue;
          if (q.sourceNoteId && keptOut.has(q.sourceNoteId)) continue;
          const correct = q.options?.[q.correctIndex];
          if (typeof correct !== "string") continue;
          const h = await hashQuestion(q.question, correct);
          if (!targetHashes.has(h)) continue;
          if (recalledQuestions.find((r) => r.questionHash === h)) continue;
          recalledQuestions.push({
            question: standalone(q.question),
            options: q.options,
            correctIndex: q.correctIndex,
            explanation: q.explanation ?? "",
            sourceNoteId: q.sourceNoteId ?? null,
            questionHash: h,
          });
        }
        if (recalledQuestions.length >= hardSlot) break;
      }
      // Recalled hashes are obviously NOT excluded (kita memang mau
      // bawa balik), but mereka harus di-mark agar LLM gak generate
      // duplikat di slot baru.
      for (const r of recalledQuestions) excludedHashes.add(r.questionHash);
    }

    // 6) Slot baru dari LLM = targetCount - recalled.
    const fillSlot = Math.max(0, targetCount - recalledQuestions.length);

    let newQuestions: QuizQuestion[] = [];
    let validNoteIds = new Set<string>();

    if (fillSlot > 0) {
      // Need at least 3 note bodies untuk diversity.
      if (newNotesCount < 3 && recalledQuestions.length === 0) {
        return new Response(
          JSON.stringify({
            error:
              "Belum cukup catatan minggu ini untuk membuat quiz. Tambah minimal 3 catatan dulu.",
            noteCount: newNotesCount,
          }),
          {
            status: 422,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      validNoteIds = new Set(
        (notes ?? []).map((n: any) => n.id as string),
      );

      // One LLM call from the day's "quiz" allowance.
      if (validNoteIds.size > 0 && !(await takeQuota(supabase, "quiz"))) {
        return new Response(
          JSON.stringify({
            error: isEn
              ? "That's enough quizzes for today. The feast will be ready tomorrow."
              : "Kuis hari ini sudah cukup banyak. Pestanya siap besok, ya.",
            code: "quota",
          }),
          {
            status: 429,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      // Build LLM prompt only when we have notes to draw from.
      if (validNoteIds.size > 0) {
        const notesBlock = (notes ?? [])
          .map((n: any, i: number) => {
            const title = n.title?.trim() || "(tanpa judul)";
            const body = (n.manual_notes ?? "").trim().slice(0, 600);
            const tags =
              Array.isArray(n.tags) && n.tags.length
                ? ` [${n.tags.join(", ")}]`
                : "";
            return `[${i + 1}] note-id=${n.id}\nTitle: ${title}${tags}\nIsi: ${body}`;
          })
          .join("\n\n---\n\n");

        const systemPrompt = isEn
          ? `You are a quiz master helping the user review their personal notes.
Generate ${fillSlot} multiple-choice questions in English from the notes provided.

STRICT RULES:
- Output MUST be valid JSON: {"questions":[{"question":"...","options":["...","...","...","..."],"correctIndex":0,"explanation":"...","sourceNoteId":"..."}, ...]}
- Exactly ${fillSlot} questions. Exactly 4 options per question.
- correctIndex: integer 0-3.
- explanation: 1-2 sentences in English.
- sourceNoteId: copy verbatim from "note-id=..." on the source note. Don't invent IDs.
- The answer comes from the note's content, not general knowledge.
- Each question stands on its own: the user answers without seeing the note, so name the topic directly (e.g. "What's the main difference between Supabase and Firebase?"). Never refer to the note itself ("according to the note", "in this note", "the note above").
- Avoid trivia like timestamps. Focus on the key ideas, tips, steps, facts and insights worth remembering.
- Distribute across multiple notes when possible.`
          : `Kamu adalah quiz master yang membantu user me-review catatan personalnya.
Buat ${fillSlot} pertanyaan pilihan ganda dalam Bahasa Indonesia dari catatan yang diberikan.

ATURAN KETAT:
- Output WAJIB JSON: {"questions":[{"question":"...","options":["...","...","...","..."],"correctIndex":0,"explanation":"...","sourceNoteId":"..."}, ...]}
- Tepat ${fillSlot} pertanyaan. Tepat 4 opsi per pertanyaan.
- correctIndex: integer 0-3.
- explanation: 1-2 kalimat dalam Bahasa Indonesia.
- sourceNoteId: SALIN persis dari "note-id=…" pada catatan sumber. Jangan dikarang.
- Jawabannya diambil dari isi catatan, bukan pengetahuan umum.
- Setiap pertanyaan harus berdiri sendiri: user menjawab tanpa melihat catatannya, jadi sebut topiknya langsung (mis. "Apa beda utama Supabase dan Firebase?"). JANGAN merujuk ke catatannya ("berdasarkan catatan", "menurut catatan", "catatan tersebut/ini", "di atas").
- Hindari pertanyaan trivial seperti timestamp. Fokus pada ide utama, tips, langkah, fakta, dan insight yang layak diingat.
- Sebar antar beberapa catatan kalau bisa.`;

        const userPrompt = isEn
          ? `Here are my notes from this week (${newNotesCount} notes):

${notesBlock}

Generate a ${fillSlot}-question quiz from these notes.`
          : `Berikut catatan saya minggu ini (${newNotesCount} catatan):

${notesBlock}

Buat quiz ${fillSlot} pertanyaan dari catatan-catatan ini.`;

        const completion = await openai.chat.completions.create({
          ...CHAT_EXTRA,
          model: CHAT_MODEL,
          temperature: 0.6,
          response_format: { type: "json_object" },
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: userPrompt },
          ],
        });

        const raw = completion.choices[0]?.message?.content ?? "";
        let parsed: any;
        try {
          parsed = JSON.parse(raw);
        } catch (_) {
          console.error(
            "[generate-weekly-quiz] LLM non-JSON:",
            raw.slice(0, 300),
          );
          return new Response(
            JSON.stringify({
              error: "LLM gagal menghasilkan JSON valid. Coba lagi.",
            }),
            {
              status: 502,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
          );
        }

        newQuestions = await sanitizeQuestions(
          parsed,
          validNoteIds,
          excludedHashes,
          fillSlot,
        );
      }
    }

    const allQuestions: QuizQuestion[] = [
      ...recalledQuestions,
      ...newQuestions,
    ];
    if (allQuestions.length < 3) {
      return new Response(
        JSON.stringify({
          error:
            "Gagal membuat quiz. Tambah catatan dulu atau coba lagi nanti.",
          noteCount: newNotesCount,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 7) Persist via service-role.
    const sourceNoteIds = Array.from(
      new Set(
        allQuestions
          .map((q) => q.sourceNoteId)
          .filter((x): x is string => !!x),
      ),
    );

    const { data: inserted, error: insertError } = await adminClient
      .from("weekly_quizzes")
      .insert({
        user_id: userId,
        week_start: weekStart,
        questions: allQuestions,
        source_note_ids: sourceNoteIds,
        target_count: targetCount,
      })
      .select("id, week_start, target_count")
      .single();

    if (insertError) {
      // Race fallback.
      const { data: refetched } = await supabase
        .from("weekly_quizzes")
        .select(
          "id, week_start, questions, source_note_ids, user_answers, completed_at, score, target_count",
        )
        .eq("user_id", userId)
        .eq("week_start", weekStart)
        .maybeSingle();
      if (refetched) {
        return new Response(
          JSON.stringify({
            id: refetched.id,
            weekStart: refetched.week_start,
            questions: (refetched.questions ?? []).map((q: any) => ({ ...q, question: standalone(q.question ?? "") })),
            sourceNoteIds: refetched.source_note_ids ?? [],
            userAnswers: refetched.user_answers ?? null,
            completedAt: refetched.completed_at,
            score: refetched.score,
            noteCount: (refetched.source_note_ids ?? []).length,
            targetCount: refetched.target_count ?? 5,
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
      throw insertError;
    }

    return new Response(
      JSON.stringify({
        id: inserted.id,
        weekStart: inserted.week_start,
        questions: allQuestions,
        sourceNoteIds,
        userAnswers: null,
        completedAt: null,
        score: null,
        noteCount: sourceNoteIds.length,
        targetCount: inserted.target_count,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    // Error Supabase itu objek biasa (`${e}` jadi "[object Object]"):
    // log dapat semuanya, app dapat kalimat yang ramah.
    console.error("[generate-weekly-quiz] handler error:", e);
    const body = {
      error: isEn
        ? "Couldn't make this week's feast. Try again in a bit."
        : "Gagal menyiapkan pesta minggu ini. Coba lagi sebentar lagi.",
    };
    return new Response(JSON.stringify(body), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
