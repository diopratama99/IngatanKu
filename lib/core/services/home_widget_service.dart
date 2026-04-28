import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/vault/domain/entities/note_entity.dart';

/// Bridge between the Flutter app and the native Android `RecentNotesWidget`
/// (and any future iOS widget). Owns three jobs:
///
///   1. Serialise the user's three most-recent notes into shared storage so
///      the native widget can read them.
///   2. Trigger a redraw whenever the data actually changes.
///   3. Surface cold-start and warm-tap URIs so the app can deep-link to the
///      right page (note detail, capture page) when the user taps something
///      inside the widget.
///
/// Storage keys match what `RecentNotesWidget.kt` reads:
///   * `recent_notes` → JSON array of `{id, title, tag}`
///   * `updated_at`   → "HH.mm" string for the footer timestamp
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// Class name (Kotlin) of the AppWidgetProvider — must match exactly.
  static const String _androidWidgetName = 'RecentNotesWidget';

  /// iOS app group ID, used by WidgetKit to share `UserDefaults`. Harmless on
  /// Android — the package treats it as a no-op there.
  static const String _appGroupId = 'group.com.temanlabs.ingatanku';

  static const String _kRecentNotes = 'recent_notes';
  static const String _kUpdatedAt = 'updated_at';

  /// Last-pushed serialisation; lets us skip redraws when nothing changed.
  String? _lastFingerprint;

  Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Serialises [notes] (top 3, newest first) into widget storage and asks
  /// the platform to redraw the widget. No-op when the payload hasn't
  /// changed since the previous call.
  Future<void> pushRecentNotes(List<NoteEntity> notes) async {
    final top = notes.take(3).map((n) {
      return {
        'id': n.id,
        'title': _resolveTitle(n),
        'tag': n.tags.isNotEmpty ? '#${n.tags.first}' : '',
      };
    }).toList();
    final fingerprint = jsonEncode(top);
    if (fingerprint == _lastFingerprint) return;
    _lastFingerprint = fingerprint;

    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    try {
      await HomeWidget.saveWidgetData<String>(_kRecentNotes, fingerprint);
      await HomeWidget.saveWidgetData<String>(_kUpdatedAt, '$hh.$mm');
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e, st) {
      debugPrint('[HomeWidget] push failed: $e\n$st');
    }
  }

  /// Returns the URI that launched the app via a widget tap on cold start,
  /// or `null` if the launch was unrelated to the widget.
  Future<Uri?> consumeColdStartUri() {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  /// Stream of URIs emitted whenever the user taps a clickable region inside
  /// the widget while the app is already running.
  Stream<Uri?> get tapStream => HomeWidget.widgetClicked;

  // ── helpers ────────────────────────────────────────────────────

  String _resolveTitle(NoteEntity note) {
    final t = note.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final m = note.manualNotes.trim();
    if (m.isNotEmpty) return m.split('\n').first;
    final url = note.url.trim();
    if (url.isNotEmpty) return url;
    return '(tanpa judul)';
  }
}
