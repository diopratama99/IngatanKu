import 'dart:math';

import '../../vault/domain/entities/note_entity.dart';

/// Generates 3 chat starter prompts that adapt to the user's most recent
/// notes and rotate every 24 hours — even when the note set hasn't changed.
///
/// Design goals:
///   * **Zero token cost** — fully local rule-based generation.
///   * **Adaptive** — picks tags / titles / sources from the latest notes.
///   * **Daily rotation** — deterministic shuffle keyed off the current
///     date so the suggested set changes once per local day.
///   * **Stable within a day** — same inputs + same date always yield the
///     same three prompts (no flicker on widget rebuild).
class SuggestedPromptsBuilder {
  SuggestedPromptsBuilder._();

  /// Default fallback when the user has zero notes yet.
  static const List<String> _starterPrompts = [
    'Apa yang bisa aku tanyakan setelah punya beberapa catatan?',
    'Bagaimana cara kerja AI ini menjawab pertanyaanku?',
    'Apa tips memulai catatan teknis yang baik?',
  ];

  /// Build 3 prompts adapted to the recent [notes].
  ///
  /// [now] defaults to `DateTime.now()` and seeds the daily rotation. Pass an
  /// explicit value in tests for determinism.
  static List<String> build(
    List<NoteEntity> notes, {
    DateTime? now,
    int count = 3,
  }) {
    if (notes.isEmpty) return List.of(_starterPrompts).take(count).toList();

    final today = (now ?? DateTime.now()).toUtc();
    final daySeed = today.difference(DateTime.utc(1970, 1, 1)).inDays;

    // Use only the freshest 10 notes — caller is expected to pass a sorted
    // list, but we sort defensively.
    final recent = [...notes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pool = recent.take(10).toList();

    final candidates = _generateCandidates(pool);
    if (candidates.isEmpty) {
      return List.of(_starterPrompts).take(count).toList();
    }

    // Deterministic shuffle keyed by the day. Same day → same order; new
    // day → fully reshuffled order. We mix in the candidate-list length so
    // that adding a new note also nudges the order.
    final rng = Random(daySeed * 1000003 ^ candidates.length);
    final shuffled = [...candidates]..shuffle(rng);

    // Greedy de-duplication by template family so we don't return three
    // variations of "tell me about #{sameTag}".
    final picked = <String>[];
    final seenFamilies = <String>{};
    for (final c in shuffled) {
      if (picked.length >= count) break;
      if (seenFamilies.add(c.family)) picked.add(c.text);
    }
    // If we somehow didn't fill the quota (e.g. only 1 family available),
    // pad with whatever is left.
    if (picked.length < count) {
      for (final c in shuffled) {
        if (picked.length >= count) break;
        if (!picked.contains(c.text)) picked.add(c.text);
      }
    }
    return picked;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Candidate generation
  // ─────────────────────────────────────────────────────────────────────

  static List<_Candidate> _generateCandidates(List<NoteEntity> notes) {
    final out = <_Candidate>[];

    // Tag frequency
    final tagCount = <String, int>{};
    for (final n in notes) {
      for (final t in n.tags) {
        final key = t.trim().toLowerCase();
        if (key.isEmpty) continue;
        tagCount[key] = (tagCount[key] ?? 0) + 1;
      }
    }
    final topTags = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tagList = topTags.map((e) => e.key).toList();

    // Per-tag prompts (one family per template; many tags → many candidates)
    for (final tag in tagList.take(5)) {
      out.addAll([
        _Candidate('tag:summary', 'Rangkum catatanku tentang #$tag'),
        _Candidate('tag:list', 'Apa saja yang aku simpan tentang #$tag?'),
        _Candidate(
            'tag:insight', 'Beri 3 insight utama dari catatan #$tag'),
        _Candidate(
            'tag:tips', 'Tampilkan tips praktis tentang #$tag'),
        _Candidate(
            'tag:concept', 'Apa konsep penting di catatan #$tag?'),
        _Candidate(
            'tag:pattern', 'Cari pola dari catatan ber-tag #$tag'),
      ]);
    }

    // Tag comparisons (need ≥ 2 distinct tags)
    if (tagList.length >= 2) {
      final a = tagList[0];
      final b = tagList[1];
      out.addAll([
        _Candidate('compare', 'Bandingkan catatanku tentang #$a dan #$b'),
        _Candidate('compare',
            'Apa kesamaan antara catatan #$a dan #$b?'),
      ]);
    }
    if (tagList.length >= 3) {
      final a = tagList[0];
      final c = tagList[2];
      out.add(_Candidate('compare',
          'Apa benang merah antara #$a dan #$c di catatanku?'));
    }

    // Per-title prompts (only titles short enough to fit cleanly)
    final titles = notes
        .map((n) => n.title?.trim())
        .whereType<String>()
        .where((t) => t.isNotEmpty && t.length <= 70)
        .take(5)
        .toList();
    for (final title in titles) {
      out.addAll([
        _Candidate('title', "Apa poin utama dari '$title'?"),
        _Candidate('title', "Berikan ringkasan dari '$title'"),
        _Candidate('title', "Pelajaran apa dari '$title'?"),
      ]);
    }

    // Source-type prompts
    final sources = notes.map((n) => n.sourceType).toSet();
    for (final s in sources) {
      final label = _sourceLabel(s);
      if (label == null) continue;
      out.add(_Candidate(
          'source', 'Apa insight dari catatan $label belakangan?'));
    }

    // Time-based prompts (always available)
    out.addAll(const [
      _Candidate('time', 'Apa yang aku simpan minggu ini?'),
      _Candidate(
          'time', 'Buatkan ringkasan 5 poin dari catatan terbaruku'),
      _Candidate('time', 'Apa tema dominan dari catatan terakhirku?'),
      _Candidate('time',
          'Apa hal paling menarik yang baru aku simpan?'),
    ]);

    // Open-ended (always available)
    out.addAll(const [
      _Candidate('open',
          'Berikan ide topik baru untuk dipelajari berdasarkan catatanku'),
      _Candidate('open',
          'Pertanyaan menarik apa yang bisa aku gali dari catatanku?'),
      _Candidate('open',
          'Tunjukkan kelemahan atau gap di pemahamanku berdasarkan catatan'),
    ]);

    return out;
  }

  static String? _sourceLabel(String s) {
    switch (s) {
      case 'youtube':
        return 'YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'instagram':
        return 'Instagram';
      case 'x':
        return 'X';
      case 'article':
        return 'artikel';
      default:
        return null;
    }
  }
}

class _Candidate {
  final String family;
  final String text;
  const _Candidate(this.family, this.text);
}
