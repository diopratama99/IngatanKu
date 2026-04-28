// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: generate-weekly-quiz
//
// Returns the user's quiz for the current week. If one doesn't exist yet,
// generates a fresh 5-question multiple-choice quiz from their last 7
// days of notes via the LLM, persists it to `weekly_quizzes`, then
// returns it. Idempotent — calling twice in the same week returns the
// already-stored quiz.
//
// Request body: (none required)
// Response:
// {
//   "id": "uuid",
//   "weekStart": "2025-04-21",
//   "questions": [...],
//   "sourceNoteIds": [...],
//   "userAnswers": null | [...],
//   "completedAt": null | "...",
//   "score": null | int,
//   "noteCount": 12
// }
//
// Deploy: supabase functions deploy generate-weekly-quiz
// Secrets reused from ask-brain: OPENAI_API_KEY, OPENAI_BASE_URL,
// OPENAI_CHAT_MODEL.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import OpenAI from "https://esm.sh/openai@4.56.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY")!,
  baseURL: Deno.env.get("OPENAI_BASE_URL") ?? "https://api.openai.com/v1",
});
const CHAT_MODEL = Deno.env.get("OPENAI_CHAT_MODEL") ?? "gpt-4o-mini";

/** Returns the Monday of the week containing [d], at 00:00:00 UTC. We
 * anchor on Monday because Sunday-end-of-week feels less natural in
 * Indonesia where the work week typically resets on Senin. */
function weekStartMonday(d: Date): string {
  const local = new Date(d);
  const day = local.getUTCDay(); // 0 Sun … 6 Sat
  const diff = day === 0 ? -6 : 1 - day; // back to Monday
  local.setUTCDate(local.getUTCDate() + diff);
  local.setUTCHours(0, 0, 0, 0);
  // Format YYYY-MM-DD without timezone shift quirks.
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
}

/** Validates and coerces the LLM's JSON output into our schema. Drops
 * malformed entries; returns null if we can't get at least 3 valid
 * questions (in which case the caller should surface an error). */
function sanitizeQuestions(raw: any, validNoteIds: Set<string>): QuizQuestion[] | null {
  const list = Array.isArray(raw?.questions) ? raw.questions : null;
  if (!list) return null;

  const out: QuizQuestion[] = [];
  for (const q of list) {
    if (typeof q?.question !== "string") continue;
    if (!Array.isArray(q?.options) || q.options.length !== 4) continue;
    if (q.options.some((o: any) => typeof o !== "string")) continue;
    const idx = Number(q.correctIndex);
    if (!Number.isInteger(idx) || idx < 0 || idx > 3) continue;
    const explanation = typeof q.explanation === "string" ? q.explanation : "";
    const noteId = typeof q.sourceNoteId === "string" && validNoteIds.has(q.sourceNoteId)
      ? q.sourceNoteId
      : null;
    out.push({
      question: q.question.trim(),
      options: q.options.map((o: string) => o.trim()),
      correctIndex: idx,
      explanation: explanation.trim(),
      sourceNoteId: noteId,
    });
    if (out.length === 5) break;
  }

  return out.length >= 3 ? out.slice(0, 5) : null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing auth" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    // Service-role client for inserting quizzes — bypasses RLS that
    // would otherwise block edge-function inserts.
    const adminClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userId = user.id;
    const weekStart = weekStartMonday(new Date());

    // 1) Already have a quiz for this week? Return it as-is.
    const { data: existing } = await supabase
      .from("weekly_quizzes")
      .select("id, week_start, questions, source_note_ids, user_answers, completed_at, score")
      .eq("user_id", userId)
      .eq("week_start", weekStart)
      .maybeSingle();

    if (existing) {
      return new Response(
        JSON.stringify({
          id: existing.id,
          weekStart: existing.week_start,
          questions: existing.questions,
          sourceNoteIds: existing.source_note_ids ?? [],
          userAnswers: existing.user_answers ?? null,
          completedAt: existing.completed_at,
          score: existing.score,
          noteCount: (existing.source_note_ids ?? []).length,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 2) Pull the user's last-7-day notes.
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setUTCDate(sevenDaysAgo.getUTCDate() - 7);

    const { data: notes, error: notesError } = await supabase
      .from("content_vault")
      .select("id, title, manual_notes, source_type, tags")
      .eq("user_id", userId)
      .gte("created_at", sevenDaysAgo.toISOString())
      .order("created_at", { ascending: false })
      .limit(20);

    if (notesError) throw notesError;
    if (!notes || notes.length < 3) {
      return new Response(
        JSON.stringify({
          error:
            "Belum cukup catatan minggu ini untuk membuat quiz. Tambah minimal 3 catatan dulu.",
          noteCount: notes?.length ?? 0,
        }),
        {
          status: 422,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 3) Build the LLM prompt. Keep each note's body trimmed to ~600
    //    chars so the combined context stays well within the 8k-token
    //    budget of GPT-4o-mini / GitHub Models gpt-4.1-mini.
    const validNoteIds = new Set(notes.map((n: any) => n.id as string));
    const notesBlock = notes
      .map((n: any, i: number) => {
        const title = n.title?.trim() || "(tanpa judul)";
        const body = (n.manual_notes ?? "").trim().slice(0, 600);
        const tags = Array.isArray(n.tags) && n.tags.length
          ? ` [${n.tags.join(", ")}]`
          : "";
        return `[${i + 1}] note-id=${n.id}\nTitle: ${title}${tags}\nIsi: ${body}`;
      })
      .join("\n\n---\n\n");

    const systemPrompt =
      `Kamu adalah quiz master yang membantu user me-review catatan personalnya.
Buat 5 pertanyaan pilihan ganda dalam Bahasa Indonesia dari catatan yang diberikan.

ATURAN KETAT:
- Output WAJIB JSON valid persis dengan schema:
{"questions":[{"question":"...","options":["...","...","...","..."],"correctIndex":0,"explanation":"...","sourceNoteId":"..."}, ...]}
- Tepat 5 pertanyaan. Tepat 4 opsi per pertanyaan.
- correctIndex: integer 0-3 (index opsi yang benar).
- explanation: 1-2 kalimat jelas kenapa jawaban itu benar, dalam Bahasa Indonesia.
- sourceNoteId: SALIN persis dari "note-id=…" pada note yang dipakai. Tidak boleh dikarang.
- Pertanyaan harus bisa dijawab HANYA dari isi catatan, bukan pengetahuan umum.
- Hindari pertanyaan trivial seperti "kapan catatan dibuat" — fokus pada konsep teknis, definisi, atau insight.
- Distribusi: usahakan ambil dari beberapa note berbeda, jangan semua dari satu note.`;

    const userPrompt = `Berikut catatan saya minggu ini (${notes.length} catatan):

${notesBlock}

Buat quiz 5 pertanyaan dari catatan-catatan ini.`;

    const completion = await openai.chat.completions.create({
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
      console.error("[generate-weekly-quiz] LLM returned non-JSON:", raw.slice(0, 300));
      return new Response(
        JSON.stringify({ error: "LLM gagal menghasilkan JSON valid. Coba lagi." }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const questions = sanitizeQuestions(parsed, validNoteIds);
    if (!questions) {
      return new Response(
        JSON.stringify({
          error: "Gagal membuat quiz dari catatan ini. Coba lagi nanti.",
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 4) Persist via service-role so RLS doesn't reject the insert.
    const sourceNoteIds = Array.from(
      new Set(questions.map((q) => q.sourceNoteId).filter((x): x is string => !!x)),
    );

    const { data: inserted, error: insertError } = await adminClient
      .from("weekly_quizzes")
      .insert({
        user_id: userId,
        week_start: weekStart,
        questions,
        source_note_ids: sourceNoteIds,
      })
      .select("id, week_start")
      .single();

    if (insertError) {
      // Race condition fallback: another request inserted first; refetch.
      const { data: refetched } = await supabase
        .from("weekly_quizzes")
        .select("id, week_start, questions, source_note_ids, user_answers, completed_at, score")
        .eq("user_id", userId)
        .eq("week_start", weekStart)
        .maybeSingle();
      if (refetched) {
        return new Response(
          JSON.stringify({
            id: refetched.id,
            weekStart: refetched.week_start,
            questions: refetched.questions,
            sourceNoteIds: refetched.source_note_ids ?? [],
            userAnswers: refetched.user_answers ?? null,
            completedAt: refetched.completed_at,
            score: refetched.score,
            noteCount: (refetched.source_note_ids ?? []).length,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      throw insertError;
    }

    return new Response(
      JSON.stringify({
        id: inserted.id,
        weekStart: inserted.week_start,
        questions,
        sourceNoteIds,
        userAnswers: null,
        completedAt: null,
        score: null,
        noteCount: sourceNoteIds.length,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[generate-weekly-quiz] handler error:", e);
    return new Response(JSON.stringify({ error: `${e}` }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
