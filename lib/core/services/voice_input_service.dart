import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  /// Resolved locale id that the device actually supports — chosen at init
  /// time. Falls back to the system locale if `id_ID` (Bahasa Indonesia)
  /// isn't installed.
  String? _resolvedLocale;
  String? get resolvedLocale => _resolvedLocale;

  Future<bool> ensurePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> init() async {
    if (_initialized) return _speech.isAvailable;
    final granted = await ensurePermission();
    if (!granted) return false;
    _initialized = await _speech.initialize(
      onError: (e) => debugPrint('[Voice] error: ${e.errorMsg}'),
      onStatus: (s) => debugPrint('[Voice] status: $s'),
    );
    if (_initialized) {
      await _resolveBestLocale();
    }
    return _initialized;
  }

  /// Try Bahasa Indonesia first; if the device doesn't have it installed,
  /// fall back to the system default locale, then any available locale.
  Future<void> _resolveBestLocale() async {
    try {
      final available = await _speech.locales();
      final ids = available.map((l) => l.localeId).toList();
      debugPrint('[Voice] available locales: $ids');

      String? pick;
      // 1. Exact match for Bahasa Indonesia
      pick = ids.firstWhere(
        (id) => id.toLowerCase() == 'id_id' || id.toLowerCase() == 'id-id',
        orElse: () => '',
      );
      if (pick.isEmpty) {
        // 2. Any Indonesian variant (id_xx)
        pick = ids.firstWhere(
          (id) => id.toLowerCase().startsWith('id'),
          orElse: () => '',
        );
      }
      if (pick.isEmpty) {
        // 3. System default
        final sys = await _speech.systemLocale();
        pick = sys?.localeId ?? '';
      }
      if (pick.isEmpty && ids.isNotEmpty) {
        // 4. First available
        pick = ids.first;
      }
      _resolvedLocale = pick.isEmpty ? null : pick;
      debugPrint('[Voice] resolved locale: $_resolvedLocale');
    } catch (e) {
      debugPrint('[Voice] locale resolution failed: $e');
    }
  }

  bool get isListening => _speech.isListening;

  /// Listens until [onFinal] callback or timeout (30s default).
  /// If [localeId] is null, uses the auto-resolved best locale (Bahasa
  /// Indonesia if available, else system default).
  Future<void> listen({
    required void Function(String partial, bool isFinal) onResult,
    String? localeId,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!await init()) {
      onResult('mic permission denied', true);
      return;
    }
    final effective = localeId ?? _resolvedLocale ?? 'id_ID';
    debugPrint('[Voice] listening with locale=$effective');
    await _speech.listen(
      localeId: effective,
      listenFor: timeout,
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async => _speech.stop();
  Future<void> cancel() async => _speech.cancel();

  Future<List<stt.LocaleName>> locales() async {
    if (!_initialized) await init();
    return _speech.locales();
  }
}
