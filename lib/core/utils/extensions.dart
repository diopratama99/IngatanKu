import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../services/sound_service.dart';

extension DateTimeX on DateTime {
  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  /// Bahasa-Indonesia-only relative time. Kept for legacy call sites
  /// that don't have a [BuildContext] reachable. New code should
  /// prefer [timeAgoLocalized] so the string flips with the user's
  /// chosen locale.
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt';
    if (diff.inHours < 24) return '${diff.inHours} jam';
    if (diff.inDays < 7) return '${diff.inDays} hari';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} minggu';
    return prettyDate;
  }

  /// Relative time in the user's current locale. Pass any
  /// [BuildContext] reachable from inside `build()`.
  String timeAgoLocalized(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return l10n.timeAgoJustNow;
    if (diff.inMinutes < 60) return l10n.timeAgoMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeAgoHours(diff.inHours);
    if (diff.inDays < 7) return l10n.timeAgoDays(diff.inDays);
    if (diff.inDays < 30) return l10n.timeAgoWeeks(diff.inDays ~/ 7);
    return prettyDateLocalized(context);
  }

  /// Bahasa-Indonesia-only date display. Same legacy/locale-aware
  /// pair as [timeAgo].
  String get prettyDate => '$day ${_bulan[month - 1]} $year';

  String prettyDateLocalized(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mo = switch (month) {
      1 => l10n.monthShortJan,
      2 => l10n.monthShortFeb,
      3 => l10n.monthShortMar,
      4 => l10n.monthShortApr,
      5 => l10n.monthShortMay,
      6 => l10n.monthShortJun,
      7 => l10n.monthShortJul,
      8 => l10n.monthShortAug,
      9 => l10n.monthShortSep,
      10 => l10n.monthShortOct,
      11 => l10n.monthShortNov,
      _ => l10n.monthShortDec,
    };
    return '$day $mo $year';
  }
}

extension StringX on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get sourceFromUrl {
    final lower = toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) return 'youtube';
    if (lower.contains('tiktok.com')) return 'tiktok';
    if (lower.contains('instagram.com')) return 'instagram';
    if (lower.contains('threads.com') || lower.contains('threads.net')) {
      return 'threads';
    }
    // Order matters — match facebook AFTER threads.net, since
    // Threads is a Meta property reachable via facebook.com redirects.
    // Cover both `facebook.com` and the legacy short `fb.com`/`fb.watch`
    // share domains.
    if (lower.contains('facebook.com') ||
        lower.contains('fb.com') ||
        lower.contains('fb.watch')) {
      return 'facebook';
    }
    if (lower.contains('twitter.com') || lower.contains('x.com')) return 'x';
    return 'article';
  }
}

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textStyles => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.of(this).size;

  void showSnack(
    String message, {
    bool error = false,
    SnackBarAction? action,
  }) {
    if (error) SoundService.instance.play(Sfx.error);
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade900 : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: action,
          // Saat ada action button (label panjang), kasih durasi lebih
          // panjang biar user sempat ngeklik.
          duration: action != null
              ? const Duration(seconds: 6)
              : const Duration(seconds: 4),
        ),
      );
  }
}
