import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent settings for the app shell — its language.
///
/// We keep these in a single service (rather than two parallel ones) so
/// changes are atomic and there's only one place that pushes rebuilds
/// to `MaterialApp` via [ChangeNotifier]. Defaults are conservative:
/// follow the device locale, with English as the fallback when the
/// system gives us something we don't support.
///
/// SharedPreferences keys live as constants below so accidental typos
/// in other layers won't silently fail.
class AppSettingsService extends ChangeNotifier {
  AppSettingsService._(this._prefs);

  static const _keyLocale = 'app.locale';        // 'system' | 'id' | 'en'

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Locale used when the user picks "follow system" but the OS
  /// reports something we don't ship strings for. Per product
  /// decision: English wins because it's the international fallback.
  static const _systemFallback = Locale('en');

  final SharedPreferences _prefs;

  // ── Public init ────────────────────────────────────────────────
  static AppSettingsService? _instance;
  static AppSettingsService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'AppSettingsService not initialized — call AppSettingsService.init() '
        'before runApp().',
      );
    }
    return i;
  }

  static Future<AppSettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return _instance = AppSettingsService._(prefs);
  }

  // ── Locale ────────────────────────────────────────────────────

  /// User's stored choice. `null` means "follow system".
  Locale? get storedLocale {
    final raw = _prefs.getString(_keyLocale);
    if (raw == null || raw.isEmpty || raw == 'system') return null;
    return Locale(raw);
  }

  /// Resolved locale to apply to the app. Honours the stored choice
  /// when set, otherwise picks from the device locales using the
  /// supported list, falling back to [_systemFallback].
  Locale get resolvedLocale {
    final stored = storedLocale;
    if (stored != null) return stored;
    final supportedCodes = supportedLocales.map((l) => l.languageCode).toSet();
    for (final l in PlatformDispatcher.instance.locales) {
      if (supportedCodes.contains(l.languageCode)) {
        return Locale(l.languageCode);
      }
    }
    return _systemFallback;
  }

  /// Pass [locale] = null to revert to "follow system".
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.setString(_keyLocale, 'system');
    } else {
      // Defensive: only persist values we can resolve later.
      final code = locale.languageCode;
      if (!supportedLocales.any((l) => l.languageCode == code)) {
        return;
      }
      await _prefs.setString(_keyLocale, code);
    }
    notifyListeners();
  }
}
