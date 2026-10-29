import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/repositories/auto_summarize_repository.dart';

/// Calls the `auto-summarize` Edge Function and parses Server-Sent Events.
///
/// Format mirrors `ask-brain`:
///   event: meta\n
///   data: {"source":"…","contentLabel":"…","contentLength":1234}\n\n
///   event: stage\n
///   data: {"stage":"download","label":"Mengunduh audio…"}\n\n
///   data: {"token":"…"}\n\n
///   …
///   data: {"done":true}\n\n
class AutoSummarizeRemoteDataSource {
  final SupabaseService service;
  AutoSummarizeRemoteDataSource(this.service);

  Stream<AutoSummarizeEvent> summarize({
    required String url,
    String locale = 'id',
    bool transcribe = false,
  }) async* {
    final token = await service.ensureFreshAccessToken();
    if (token == null) {
      yield const AutoSummarizeError('Belum login');
      return;
    }

    final uri = Uri.parse(
      '${Env.supabaseUrl}/functions/v1/${AppConstants.fnAutoSummarize}',
    );

    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'apikey': Env.supabaseAnonKey,
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode({
      'url': url,
      'locale': locale,
      // Only forward `transcribe` when set — keeps the wire payload
      // identical to the legacy meta path so the server's default code
      // path stays warm in the cache.
      if (transcribe) 'transcribe': true,
    });

    try {
      final streamed = await request.send();
      if (streamed.statusCode != 200) {
        // Surface the raw HTTP status + body so we can debug bizarre
        // edge-fn timeouts. Truncate at 500 chars so the SnackBar
        // doesn't blow the screen with a 50KB stack trace.
        final body = await streamed.stream.bytesToString();
        final preview = body.length > 500 ? '${body.substring(0, 500)}…' : body;
        String message =
            'HTTP ${streamed.statusCode}${preview.isEmpty ? '' : ' · $preview'}';
        var outOfQuota = false;
        try {
          final json = jsonDecode(body);
          if (json is Map && json['error'] is String) {
            message = 'HTTP ${streamed.statusCode} · ${json['error']}';
          }
          outOfQuota = json is Map && json['code'] == 'quota';
        } catch (_) {/* not JSON, keep raw preview above */}
        yield AutoSummarizeError(message, outOfQuota: outOfQuota);
        return;
      }

      String currentEvent = 'message';
      final lineStream = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (line.isEmpty) {
          // Blank line resets event scope per SSE spec.
          currentEvent = 'message';
          continue;
        }
        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
          continue;
        }
        if (line.startsWith('data:')) {
          final raw = line.substring(5).trim();
          if (raw.isEmpty) continue;
          try {
            final json = jsonDecode(raw);
            if (currentEvent == 'meta' && json is Map) {
              yield AutoSummarizeMeta(
                source: json['source'] as String? ?? 'article',
                contentLabel: json['contentLabel'] as String? ?? 'konten',
                contentLength: (json['contentLength'] as num?)?.toInt() ?? 0,
              );
            } else if (currentEvent == 'stage' && json is Map) {
              yield AutoSummarizeStage(
                stage: json['stage'] as String? ?? 'work',
                label: json['label'] as String? ?? 'Memproses…',
              );
            } else if (currentEvent == 'tags' && json is Map) {
              yield AutoSummarizeTags([
                for (final t in (json['tags'] as List? ?? const []))
                  if (t is String) t,
              ]);
            } else if (json is Map && json['token'] != null) {
              yield AutoSummarizeToken(json['token'] as String);
            } else if (json is Map && json['done'] == true) {
              yield const AutoSummarizeDone();
            } else if (json is Map && json['error'] != null) {
              yield AutoSummarizeError('${json['error']}');
            }
          } catch (_) {/* ignore malformed line */}
        }
      }
      yield const AutoSummarizeDone();
    } on TimeoutException {
      yield const AutoSummarizeError('Request timeout');
    } catch (e) {
      // Surface the raw exception type + message instead of throwing.
      // Throws got swallowed by the bloc layer earlier; surfacing them
      // as an event lets the SnackBar show the real error (e.g.
      // ClientException, FormatException, etc.).
      yield AutoSummarizeError('${e.runtimeType}: $e');
    }
  }
}
