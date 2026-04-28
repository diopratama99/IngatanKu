import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Listens for content shared from other apps (Instagram, X, browser, etc.)
/// and emits the first URL extracted from the shared text.
class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  StreamSubscription<List<SharedMediaFile>>? _liveSub;
  final _urlController = StreamController<String>.broadcast();

  /// Hot stream of URLs from share intents.
  Stream<String> get sharedUrlStream => _urlController.stream;

  /// Buffered URL — kept until the first listener subscribes (e.g. user just
  /// finished logging in).
  String? _pending;
  String? consumePending() {
    final v = _pending;
    _pending = null;
    return v;
  }

  Future<void> init() async {
    // 1. Cold-start: app was launched directly from a share intent.
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      debugPrint('[ShareIntent] cold-start media: ${initial.length} items');
      for (final f in initial) {
        debugPrint(
          '[ShareIntent]   type=${f.type} path=${f.path} message=${f.message} mime=${f.mimeType}',
        );
      }
      if (initial.isNotEmpty) {
        _emit(initial);
        ReceiveSharingIntent.instance.reset();
      }
    } catch (e, st) {
      debugPrint('[ShareIntent] getInitialMedia error: $e\n$st');
    }

    // 2. Warm: app is already running, OS routes the share to us.
    _liveSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) {
        debugPrint('[ShareIntent] live media: ${files.length} items');
        for (final f in files) {
          debugPrint(
            '[ShareIntent]   type=${f.type} path=${f.path} message=${f.message} mime=${f.mimeType}',
          );
        }
        _emit(files);
      },
      onError: (e) => debugPrint('[ShareIntent] stream error: $e'),
    );
  }

  void _emit(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final f = files.first;
    // The plugin shoves the shared text into different fields depending on
    // version & sender app. Check all of them.
    final candidates = <String?>[f.path, f.message, f.mimeType];
    for (final raw in candidates) {
      if (raw == null || raw.isEmpty) continue;
      final url = _extractUrl(raw);
      if (url != null) {
        debugPrint('[ShareIntent] extracted url: $url');
        _pending = url;
        _urlController.add(url);
        return;
      }
    }
    debugPrint('[ShareIntent] could not find URL in shared payload');
  }

  /// Pulls the first http/https URL out of an arbitrary string. Many apps
  /// (Instagram, TikTok) share text like "Check this out https://..." rather
  /// than a bare URL.
  static String? _extractUrl(String s) {
    final m = RegExp(r'https?://\S+').firstMatch(s);
    return m?.group(0);
  }

  Future<void> dispose() async {
    await _liveSub?.cancel();
    await _urlController.close();
  }
}
