import '../entities/message_entity.dart';

/// Stream chunks emitted while the AI answers.
abstract class ChatStreamEvent {
  const ChatStreamEvent();
}

class ChatSourcesReceived extends ChatStreamEvent {
  final List<SourceEntity> sources;
  const ChatSourcesReceived(this.sources);
}

class ChatTokenReceived extends ChatStreamEvent {
  final String token;
  const ChatTokenReceived(this.token);
}

class ChatDone extends ChatStreamEvent {
  const ChatDone();
}

class ChatStreamError extends ChatStreamEvent {
  final String message;
  const ChatStreamError(this.message);
}

abstract class ChatRepository {
  /// Send a question; returns a Stream that yields sources, tokens, then done.
  Stream<ChatStreamEvent> ask({
    required String question,
    required String sessionId,
  });
}
