import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

/// Calls the `ask-brain` Edge Function and parses Server-Sent Events.
class ChatRemoteDataSource {
  final SupabaseService service;
  ChatRemoteDataSource(this.service);

  Stream<ChatStreamEvent> ask({
    required String question,
    required String sessionId,
  }) async* {
    final session = service.auth.currentSession;
    if (session == null) {
      yield const ChatStreamError('Not authenticated');
      return;
    }

    final uri = Uri.parse(
      '${Env.supabaseUrl}/functions/v1/${AppConstants.fnAskBrain}',
    );

    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer ${session.accessToken}',
      'apikey': Env.supabaseAnonKey,
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode({'question': question, 'sessionId': sessionId});

    try {
      final streamed = await request.send();
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        yield ChatStreamError('HTTP ${streamed.statusCode}: $body');
        return;
      }

      String currentEvent = 'message';
      final lineStream = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (line.isEmpty) {
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
            if (currentEvent == 'sources') {
              final list = (json as List)
                  .map((e) => SourceEntity(
                        noteId: e['id'] as String,
                        title: e['title'] as String?,
                        similarity: (e['similarity'] as num).toDouble(),
                      ))
                  .toList();
              yield ChatSourcesReceived(list);
            } else if (json is Map && json['token'] != null) {
              yield ChatTokenReceived(json['token'] as String);
            } else if (json is Map && json['done'] == true) {
              yield const ChatDone();
            }
          } catch (_) {/* ignore malformed line */}
        }
      }
      yield const ChatDone();
    } on TimeoutException {
      yield const ChatStreamError('Request timed out');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
