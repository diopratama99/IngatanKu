import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/repositories/auto_summarize_repository.dart';

/// Calls the `auto-summarize` Edge Function and parses Server-Sent Events.
///
/// Format mirrors `ask-brain`:
///   event: meta\n
///   data: {"source":"…","contentLabel":"…","contentLength":1234}\n\n
///   data: {"token":"…"}\n\n
///   …
///   data: {"done":true}\n\n
class AutoSummarizeRemoteDataSource {
  final SupabaseService service;
  AutoSummarizeRemoteDataSource(this.service);

  Stream<AutoSummarizeEvent> summarize({
    required String url,
    String locale = 'id',
  }) async* {
    final session = service.auth.currentSession;
    if (session == null) {
      yield const AutoSummarizeError('Belum login');
      return;
    }

    final uri = Uri.parse(
      '${Env.supabaseUrl}/functions/v1/${AppConstants.fnAutoSummarize}',
    );

    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer ${session.accessToken}',
      'apikey': Env.supabaseAnonKey,
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode({'url': url, 'locale': locale});

    try {
      final streamed = await request.send();
      if (streamed.statusCode != 200) {
        // Server replied with a JSON error payload — surface its `error`
        // field if present, otherwise the raw body.
        final body = await streamed.stream.bytesToString();
        String message = 'HTTP ${streamed.statusCode}';
        try {
          final json = jsonDecode(body);
          if (json is Map && json['error'] is String) {
            message = json['error'] as String;
          }
        } catch (_) {/* not JSON, keep default */}
        yield AutoSummarizeError(message);
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
      throw ServerException(e.toString());
    }
  }
}
