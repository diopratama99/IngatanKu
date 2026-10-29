import 'dart:math';

import '../../../l10n/generated/app_localizations.dart';
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
  static List<String> _starterPrompts(AppLocalizations l10n) => [
        l10n.chatStarterAsk,
        l10n.chatStarterHow,
        l10n.chatStarterWhat,
      ];

  /// Build 3 prompts adapted to the recent [notes], in [l10n]'s language.
  ///
  /// [now] defaults to `DateTime.now()` and seeds the daily rotation. Pass an
  /// explicit value in tests for determinism.
  static List<String> build(
    List<NoteEntity> notes, {
    required AppLocalizations l10n,
    DateTime? now,
    int count = 3,
  }) {
    if (notes.isEmpty) return _starterPrompts(l10n).take(count).toList();

    final today = (now ?? DateTime.now()).toUtc();
    final daySeed = today.difference(DateTime.utc(1970, 1, 1)).inDays;

    // Use only the freshest 10 notes — caller is expected to pass a sorted
    // list, but we sort defensively.
    final recent = [...notes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pool = recent.take(10).toList();

    final candidates = _generateCandidates(pool, l10n);
    if (candidates.isEmpty) {
      return _starterPrompts(l10n).take(count).toList();
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

  static List<_Candidate> _generateCandidates(
      List<NoteEntity> notes, AppLocalizations l10n) {
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
        _Candidate('tag:summary', l10n.chatTagSummary(tag)),
        _Candidate('tag:list', l10n.chatTagList(tag)),
        _Candidate('tag:points', l10n.chatTagPoints(tag)),
        _Candidate('tag:tips', l10n.chatTagTips(tag)),
        _Candidate('tag:try', l10n.chatTagTry(tag)),
        _Candidate('tag:pattern', l10n.chatTagPattern(tag)),
      ]);
    }

    // Tag comparisons (need ≥ 2 distinct tags)
    if (tagList.length >= 2) {
      final a = tagList[0];
      final b = tagList[1];
      out.addAll([
        _Candidate('compare', l10n.chatCompare(a, b)),
        _Candidate('compare', l10n.chatShared(a, b)),
      ]);
    }
    if (tagList.length >= 3) {
      out.add(_Candidate('compare', l10n.chatLink(tagList[0], tagList[2])));
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
        _Candidate('title', l10n.chatTitlePoints(title)),
        _Candidate('title', l10n.chatTitleSummary(title)),
        _Candidate('title', l10n.chatTitleTakeaway(title)),
      ]);
    }

    // Source-type prompts
    final sources = notes.map((n) => n.sourceType).toSet();
    for (final s in sources) {
      final label = _sourceLabel(s, l10n);
      if (label == null) continue;
      out.add(_Candidate('source', l10n.chatSource(label)));
    }

    // Time-based prompts (always available)
    out.addAll([
      _Candidate('time', l10n.chatWeek),
      _Candidate('time', l10n.chatLatestFive),
      _Candidate('time', l10n.chatTheme),
      _Candidate('time', l10n.chatHighlight),
    ]);

    // Open-ended (always available)
    out.addAll([
      _Candidate('open', l10n.chatNextIdea),
      _Candidate('open', l10n.chatDig),
      _Candidate('open', l10n.chatGaps),
    ]);

    return out;
  }

  static String? _sourceLabel(String s, AppLocalizations l10n) {
    switch (s) {
      case 'youtube':
        return 'YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'instagram':
        return 'Instagram';
      case 'threads':
        return 'Threads';
      case 'facebook':
        return 'Facebook';
      case 'x':
        return 'X';
      case 'article':
        return l10n.chatSourceArticle;
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
