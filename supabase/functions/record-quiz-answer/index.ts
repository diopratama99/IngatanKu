// @ts-nocheck — runs on Deno, not Node.
// Supabase Edge Function: record-quiz-answer
//
// Persists per-question answer metadata into `quiz_question_history`.
// Called after user reveals an answer (or when user submits the quiz).
// Implementation idempotent per (user, question_hash, week) — kalau
// sudah ada row dengan combo tersebut, di-update bukan duplicated.
//
// Input:
// {
//   quizId, questionHash, questionText, sourceNoteId?,
//   answeredCorrectly, timeToAnswerMs?, selfRating?,
//   date?: 'YYYY-MM-DD' (the user's local day, for the daily spacing)
// }
//
// Output: { ok: true, difficulty: 'easy'|'medium'|'hard',
//           nextShowAfterWeek: 'YYYY-MM-DD' }
//
// Logic difficulty:
//  * Wrong → 'hard' (override apapun self-rating)
//  * selfRating present & correct → use selfRating
//  * Implicit signals (correct only):
//    * < 5s → boost ke 'easy'
//    * > 30s → boost ke 'hard'
//    * else → 'medium'
//
// Cooldown (weekly quiz, `next_show_after_week`):
//  * easy   → +4 weeks
//  * medium → +2 weeks
//  * hard   → +1 week
//  * banned → +99 weeks (effectively never)
//
// Cooldown (daily quiz, `next_show_after`, also set for weekly answers so
// the daily quiz knows about them):
//  * easy   → +10 days
//  * medium → +4 days
//  * hard   → +1 day
//  * banned → +999 days
//
// Deploy: supabase functions deploy record-quiz-answer

import { createClient } from "@supabase/supabase-js";
import { PUBLIC_KEY, SUPABASE_URL } from "../_shared/env.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

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

function addWeeks(weekStart: string, weeks: number): string {
  const [y, m, d] = weekStart.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + weeks * 7);
  const yyyy = dt.getUTCFullYear();
  const mm = String(dt.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(dt.getUTCDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

type Difficulty = "easy" | "medium" | "hard" | "banned";

function deriveDifficulty(args: {
  correct: boolean;
  selfRating?: string;
  timeMs?: number;
}): Difficulty {
  const { correct, selfRating, timeMs } = args;
  if (!correct) return "hard";
  if (selfRating === "easy" || selfRating === "medium" || selfRating === "hard") {
    return selfRating;
  }
  if (typeof timeMs === "number") {
    if (timeMs < 5_000) return "easy";
    if (timeMs > 30_000) return "hard";
  }
  return "medium";
}

function cooldownWeeks(d: Difficulty): number {
  return d === "easy" ? 4 : d === "medium" ? 2 : d === "banned" ? 99 : 1;
}

function cooldownDays(d: Difficulty): number {
  return d === "easy" ? 10 : d === "medium" ? 4 : d === "banned" ? 999 : 1;
}

function addDays(day: string, days: number): string {
  const [y, m, d] = day.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + days);
  return dt.toISOString().slice(0, 10);
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
      SUPABASE_URL,
      PUBLIC_KEY,
      {
        db: { schema: "ingatanku" },
        global: { headers: { Authorization: authHeader } },
      },
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

    const body = await req.json();
    const questionHash = body?.questionHash as string | undefined;
    const questionText = body?.questionText as string | undefined;
    const sourceNoteId = body?.sourceNoteId as string | null | undefined;
    const correct = body?.answeredCorrectly as boolean | undefined;
    const timeMs = body?.timeToAnswerMs as number | undefined;
    const selfRating = body?.selfRating as string | undefined;
    const today = /^\d{4}-\d{2}-\d{2}$/.test(body?.date ?? "")
      ? (body.date as string)
      : new Date().toISOString().slice(0, 10);

    if (!questionHash || !questionText || typeof correct !== "boolean") {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const userId = user.id;
    const weekStart = weekStartMonday(new Date());

    const difficulty = deriveDifficulty({
      correct,
      selfRating,
      timeMs,
    });
    const nextShow = addWeeks(weekStart, cooldownWeeks(difficulty));
    const nextShowDay = addDays(today, cooldownDays(difficulty));

    // Idempotent upsert via two-step: cek existing untuk minggu ini.
    const { data: existing } = await supabase
      .from("quiz_question_history")
      .select("id")
      .eq("user_id", userId)
      .eq("question_hash", questionHash)
      .eq("shown_at_week", weekStart)
      .maybeSingle();

    if (existing) {
      await supabase
        .from("quiz_question_history")
        .update({
          difficulty,
          answered_correctly: correct,
          time_to_answer_ms: timeMs ?? null,
          self_rating: selfRating ?? null,
          next_show_after_week: nextShow,
          next_show_after: nextShowDay,
        })
        .eq("id", existing.id);
    } else {
      await supabase.from("quiz_question_history").insert({
        user_id: userId,
        question_hash: questionHash,
        question_text: questionText,
        source_note_id: sourceNoteId ?? null,
        difficulty,
        answered_correctly: correct,
        time_to_answer_ms: timeMs ?? null,
        self_rating: selfRating ?? null,
        shown_at_week: weekStart,
        next_show_after_week: nextShow,
        next_show_after: nextShowDay,
      });
    }

    return new Response(
      JSON.stringify({
        ok: true,
        difficulty,
        nextShowAfterWeek: nextShow,
        nextShowAfter: nextShowDay,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    console.error("[record-quiz-answer] handler error:", e);
    return new Response(JSON.stringify({ error: "Recording failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
