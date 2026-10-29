// Quiz questions are read without the note in front of the user, so they
// must stand on their own: "Apa beda utama Supabase dan Firebase?", not
// "…berdasarkan catatan tersebut?". The prompts ask for that; this takes out
// what slips through, and cleans questions written before the rule.

const NOTE_REFERENCE = new RegExp(
  [
    // Indonesian: "berdasarkan catatan tersebut", "menurut isi catatan ini",
    // "dalam catatan di atas", "yang disebut di catatan itu"…
    String.raw`[,\s]*(?:berdasarkan|menurut|sesuai(?:\s+dengan)?|dalam|di|pada|dari)\s+(?:isi\s+)?catatan(?:mu|\s+kamu)?(?:\s+(?:tersebut|ini|itu|di\s+atas|yang\s+(?:diberikan|disimpan|tadi)))?`,
    // English: "according to the note", "based on this note", "in the notes above"…
    String.raw`[,\s]*(?:according\s+to|based\s+on|in|from|per)\s+(?:the|this|that|your|these)\s+notes?(?:\s+(?:above|provided))?`,
  ].join("|"),
  "gi",
);

/** [question] without phrases that point at a note the user can't see. */
export function standalone(question: string): string {
  const cleaned = question
    .replace(NOTE_REFERENCE, "")
    .replace(/^[\s,;:]+/, "")
    .replace(/\s+([?.!,])/g, "$1")
    .replace(/\s{2,}/g, " ")
    .trim();
  return cleaned ? cleaned[0].toUpperCase() + cleaned.slice(1) : question.trim();
}
