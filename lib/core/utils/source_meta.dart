import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Single source of truth for the human-readable label and icon of every
/// supported source type. Centralising this keeps the dashboard, vault
/// list, detail page, glass card and stats page in lockstep — adding a
/// new platform means touching exactly two switches here, not eight.
///
/// `sourceType` strings follow the convention used by `extensions.dart`'s
/// `String.sourceFromUrl`: `youtube | tiktok | instagram | threads |
/// facebook | x | article | other`.
class SourceMeta {
  SourceMeta._();

  /// Locale-independent label. Most source labels are brand names
  /// (YouTube, Instagram, etc.) so they stay constant. Only
  /// `article` and the unknown fallback are translated; for those
  /// the legacy [label] returns the Indonesian wording for
  /// backwards compat. Prefer [labelLocalized] in widgets that have
  /// a [BuildContext].
  static String label(String sourceType) {
    switch (sourceType) {
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
        return 'Artikel';
      default:
        return 'Tautan';
    }
  }

  /// Locale-aware variant. Returns the same brand names for known
  /// platforms; only `article` (and the unknown fallback) flip with
  /// the active locale.
  static String labelLocalized(BuildContext context, String sourceType) {
    switch (sourceType) {
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
        return AppLocalizations.of(context)!.sourceLabelArticle;
      default:
        return 'Link';
    }
  }

  static IconData icon(String sourceType) {
    switch (sourceType) {
      case 'youtube':
        return Icons.play_circle_outline_rounded;
      case 'tiktok':
        return Icons.music_note_rounded;
      case 'instagram':
        return Icons.photo_camera_outlined;
      case 'threads':
        return Icons.alternate_email_rounded;
      case 'facebook':
        return Icons.thumb_up_off_alt_rounded;
      case 'x':
        return Icons.alternate_email_rounded;
      case 'article':
        return Icons.article_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  /// Whether `resolve-media` (Cobalt) can resolve a media artifact for
  /// this source — used to gate the inline player CTA, the
  /// "Simpan offline" menu item and the transcribe button.
  static bool supportsCobaltResolve(String sourceType) {
    switch (sourceType) {
      case 'youtube':
      case 'tiktok':
      case 'instagram':
      case 'threads':
      case 'facebook':
      case 'x':
        return true;
      default:
        return false;
    }
  }

  /// Whether the backend transcribe path is supported. Per the
  /// `auto-summarize` Edge Function contract, only IG / TikTok / X are
  /// routed through Cobalt + Whisper. YouTube uses native captions via
  /// the default meta path; everything else falls back to OG scraping.
  static bool supportsTranscribe(String sourceType) {
    switch (sourceType) {
      case 'instagram':
      case 'tiktok':
      case 'x':
        return true;
      default:
        return false;
    }
  }
}
