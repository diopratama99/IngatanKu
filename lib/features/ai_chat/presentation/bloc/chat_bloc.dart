import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

// EVENTS
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatQuestionSent extends ChatEvent {
  final String question;
  const ChatQuestionSent(this.question);
  @override
  List<Object?> get props => [question];
}

class _ChatStreamEventArrived extends ChatEvent {
  final ChatStreamEvent event;
  const _ChatStreamEventArrived(this.event);
}

class ChatCleared extends ChatEvent {}

// STATE
class ChatState extends Equatable {
  final List<MessageEntity> messages;
  final bool isStreaming;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
  });

  ChatState copyWith({
    List<MessageEntity>? messages,
    bool? isStreaming,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [messages, isStreaming, error];
}

// BLOC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repo;
  final String sessionId;
  StreamSubscription<ChatStreamEvent>? _sub;

  ChatBloc({required this.repo, required this.sessionId}) : super(const ChatState()) {
    on<ChatQuestionSent>(_onAsk);
    on<_ChatStreamEventArrived>(_onStreamEvent);
    on<ChatCleared>((_, emit) => emit(const ChatState()));
  }

  Future<void> _onAsk(ChatQuestionSent e, Emitter<ChatState> emit) async {
    final now = DateTime.now();
    final userMsg = MessageEntity(
      id: 'u-${now.microsecondsSinceEpoch}',
      role: MessageRole.user,
      content: e.question,
      createdAt: now,
    );
    final aiMsg = MessageEntity(
      id: 'a-${now.microsecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: '',
      streaming: true,
      createdAt: now,
    );
    emit(state.copyWith(
      messages: [...state.messages, userMsg, aiMsg],
      isStreaming: true,
      clearError: true,
    ));

    await _sub?.cancel();
    _sub = repo.ask(question: e.question, sessionId: sessionId).listen(
      (event) => add(_ChatStreamEventArrived(event)),
      onError: (err) => add(_ChatStreamEventArrived(ChatStreamError('$err'))),
    );
  }

  void _onStreamEvent(_ChatStreamEventArrived e, Emitter<ChatState> emit) {
    final msgs = [...state.messages];
    if (msgs.isEmpty) return;
    final lastIdx = msgs.length - 1;
    final last = msgs[lastIdx];

    final ev = e.event;
    if (ev is ChatSourcesReceived) {
      msgs[lastIdx] = last.copyWith(sources: ev.sources);
      emit(state.copyWith(messages: msgs));
    } else if (ev is ChatTokenReceived) {
      msgs[lastIdx] = last.copyWith(content: last.content + ev.token);
      emit(state.copyWith(messages: msgs));
    } else if (ev is ChatDone) {
      msgs[lastIdx] = last.copyWith(streaming: false);
      emit(state.copyWith(messages: msgs, isStreaming: false));
    } else if (ev is ChatStreamError) {
      msgs[lastIdx] = last.copyWith(
        content: last.content.isEmpty ? '⚠️ ${ev.message}' : last.content,
        streaming: false,
      );
      emit(state.copyWith(messages: msgs, isStreaming: false, error: ev.message));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
