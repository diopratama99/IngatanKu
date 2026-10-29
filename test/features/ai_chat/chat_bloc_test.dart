import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/ai_chat/data/chat_session_store.dart';
import 'package:ingatanku/features/ai_chat/domain/entities/message_entity.dart';
import 'package:ingatanku/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:ingatanku/features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The first answer hangs for good (a connection nobody closes, which
/// can't even be cancelled); the ones after it come through.
class _Repo implements ChatRepository {
  _Repo({this.hangFirst = true});
  final bool hangFirst;
  int asked = 0;
  final sessions = <String>[];

  @override
  Stream<ChatStreamEvent> ask({
    required String question,
    required String sessionId,
  }) {
    asked++;
    sessions.add(sessionId);
    if (hangFirst && asked == 1) {
      return StreamController<ChatStreamEvent>(
        onCancel: () => Completer<void>().future,
      ).stream;
    }
    return Stream.fromIterable(const [
      ChatTokenReceived('Wah, ketemu! '),
      ChatTokenReceived('Ini jawabannya.'),
      ChatDone(),
    ]);
  }
}

void main() {
  test('a stuck answer never holds up the next question', () async {
    final repo = _Repo();
    final bloc = ChatBloc(repo: repo);
    addTearDown(bloc.close);

    bloc.add(const ChatQuestionSent('pertama'));
    await pumpEventQueue();
    expect(bloc.state.isStreaming, isTrue);

    bloc.add(const ChatQuestionSent('kedua'));
    await pumpEventQueue();
    expect(repo.asked, 2);
    expect(bloc.state.isStreaming, isFalse);
    expect(bloc.state.messages.last.role, MessageRole.assistant);
    expect(bloc.state.messages.last.content, 'Wah, ketemu! Ini jawabannya.');
  });

  test('starting over drops the answer still coming in', () async {
    final repo = _Repo();
    final bloc = ChatBloc(repo: repo);
    addTearDown(bloc.close);

    bloc.add(const ChatQuestionSent('pertama'));
    await pumpEventQueue();
    bloc.add(ChatCleared());
    await pumpEventQueue();
    expect(bloc.state.messages, isEmpty);
    expect(bloc.state.isStreaming, isFalse);

    bloc.add(const ChatQuestionSent('lagi'));
    await pumpEventQueue();
    expect(bloc.state.messages.last.content, 'Wah, ketemu! Ini jawabannya.');
  });

  group('kept between visits', () {
    final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

    Future<ChatSessionStore> freshStore() async {
      SharedPreferences.setMockInitialValues({});
      return ChatSessionStore(await SharedPreferences.getInstance());
    }

    test('an answered conversation is there when the app opens again',
        () async {
      final store = await freshStore();
      final repo = _Repo(hangFirst: false);
      final first = ChatBloc(repo: repo, store: store, user: 'ana');
      first.add(const ChatQuestionSent('resep ayam?'));
      await pumpEventQueue();
      await first.close();

      final again = ChatBloc(repo: repo, store: store, user: 'ana');
      addTearDown(again.close);
      expect(again.state.messages.map((m) => m.content),
          ['resep ayam?', 'Wah, ketemu! Ini jawabannya.']);
      // Same session, so the server remembers the turns before.
      again.add(const ChatQuestionSent('ada lagi?'));
      await pumpEventQueue();
      expect(repo.sessions.toSet(), hasLength(1));
      expect(repo.sessions.first, matches(uuid));
    });

    test('starting over is a new session, and nothing is kept', () async {
      final store = await freshStore();
      final repo = _Repo(hangFirst: false);
      final bloc = ChatBloc(repo: repo, store: store, user: 'ana');
      addTearDown(bloc.close);
      bloc.add(const ChatQuestionSent('pertama'));
      await pumpEventQueue();
      bloc.add(ChatCleared());
      bloc.add(const ChatQuestionSent('baru'));
      await pumpEventQueue();
      expect(repo.sessions[0], isNot(repo.sessions[1]));
      expect(repo.sessions[1], matches(uuid));
      expect(store.load('ana').messages.map((m) => m.content),
          ['baru', 'Wah, ketemu! Ini jawabannya.']);
    });

    test("someone else signing in doesn't see the conversation", () async {
      final store = await freshStore();
      final repo = _Repo(hangFirst: false);
      final users = StreamController<String?>();
      final bloc =
          ChatBloc(repo: repo, store: store, user: 'ana', users: users.stream);
      addTearDown(bloc.close);
      bloc.add(const ChatQuestionSent('rahasia ana'));
      await pumpEventQueue();

      users.add(null);
      await pumpEventQueue();
      expect(bloc.state.messages, isEmpty);
      users.add('budi');
      await pumpEventQueue();
      expect(bloc.state.messages, isEmpty);
      expect(store.load('budi').messages, isEmpty);
    });
  });
}
