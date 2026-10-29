import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../companion/data/pet_store.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

/// Calls the `ask-brain` Edge Function and parses Server-Sent Events.
/// The assistant is the user's pet, so it's told the pet's name.
class ChatRemoteDataSource {
  final SupabaseService service;
  ChatRemoteDataSource(this.service);

  Stream<ChatStreamEvent> ask({
    required String question,
    required String sessionId,
  }) async* {
    final token = await service.ensureFreshAccessToken();
    if (token == null) {
      yield const ChatStreamError('Not authenticated');
      return;
    }

    final uri = Uri.parse(
      '${Env.supabaseUrl}/functions/v1/${AppConstants.fnAskBrain}',
    );

    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'apikey': Env.supabaseAnonKey,
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    final locale = AppSettingsService.instance.resolvedLocale;
    request.body = jsonEncode({
      'question': question,
      'sessionId': sessionId,
      // Locale tells the edge function which language to reply in.
      // Stays under "language" so the same call signature works on
      // older deployments that don't recognise the field (they just
      // ignore unknown keys and default to ID).
      'locale': locale.languageCode,
      // Who's answering: the pet, by the name the user gave it.
      'petName': sl<PetStore>().customName ??
          lookupAppLocalizations(locale).petDefaultName,
    });

    try {
      // Never wait forever: not even a reply within this long, or a
      // silence this long mid-answer (the server gives up on the model
      // after 45s), and it's a timeout.
      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        yield ChatStreamError('HTTP ${streamed.statusCode}: $body');
        return;
      }

      String currentEvent = 'message';
      final lineStream = streamed.stream
          .timeout(const Duration(seconds: 75))
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
            } else if (json is Map && json['error'] != null) {
              yield ChatStreamError('${json['error']}');
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
