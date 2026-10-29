import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../data/chat_session_store.dart';
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

/// Someone else signed in (or nobody is): their own conversation, if any.
class _ChatUserChanged extends ChatEvent {
  final String? user;
  const _ChatUserChanged(this.user);
}

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

  /// Keeps the conversation between visits (none in some tests).
  final ChatSessionStore? store;

  /// Who's signed in: the conversation is theirs.
  String? _user;

  /// The server keeps the last few turns of this session, so follow-ups
  /// ("ada lagi?") make sense. A uuid, like `chat_messages.session_id`.
  String _sessionId;

  StreamSubscription<ChatStreamEvent>? _sub;
  StreamSubscription<String?>? _users;

  /// Picks up [user]'s last conversation from [store], and follows
  /// [users] (the signed-in user's id, null when signed out).
  factory ChatBloc({
    required ChatRepository repo,
    ChatSessionStore? store,
    String? user,
    Stream<String?>? users,
  }) {
    final saved = store?.load(user) ??
        (sessionId: const Uuid().v4(), messages: const <MessageEntity>[]);
    final bloc = ChatBloc._(repo, store, user, saved.sessionId, saved.messages);
    bloc._users = users?.listen(
      (u) => bloc.add(_ChatUserChanged(u)),
      // A failed token refresh isn't a change of user.
      onError: (Object _) {},
    );
    return bloc;
  }

  ChatBloc._(this.repo, this.store, this._user, this._sessionId,
      List<MessageEntity> messages)
      : super(ChatState(messages: messages)) {
    on<ChatQuestionSent>(_onAsk);
    on<_ChatStreamEventArrived>(_onStreamEvent);
    on<ChatCleared>((_, emit) {
      // Whatever was still coming in belongs to the old conversation.
      _stop();
      _sessionId = store?.start(_user) ?? const Uuid().v4();
      emit(const ChatState());
    });
    on<_ChatUserChanged>((e, emit) {
      if (e.user == _user) return;
      _stop();
      _user = e.user;
      final saved = store?.load(_user) ??
          (sessionId: const Uuid().v4(), messages: const <MessageEntity>[]);
      _sessionId = saved.sessionId;
      emit(ChatState(messages: saved.messages));
    });
  }

  /// Stops listening to the answer coming in, without waiting for it to
  /// wind down: a connection that's stuck would otherwise hold the next
  /// question up for good.
  void _stop() {
    unawaited(_sub?.cancel());
    _sub = null;
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

    _stop();
    _sub = repo.ask(question: e.question, sessionId: _sessionId).listen(
          (event) => add(_ChatStreamEventArrived(event)),
          onError: (err) =>
              add(_ChatStreamEventArrived(ChatStreamError('$err'))),
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
      // Kept once answered; one that failed isn't (it'd only be a ⚠️).
      final store = this.store;
      if (store != null) unawaited(store.save(_user, _sessionId, msgs));
    } else if (ev is ChatStreamError) {
      if (last.content.isEmpty &&
          ConnectivityService.isNetworkError(ev.message)) {
        // No connection: no answer at all (the pet says why).
        msgs.removeAt(lastIdx);
      } else {
        msgs[lastIdx] = last.copyWith(
          content: last.content.isEmpty ? '⚠️ ${ev.message}' : last.content,
          streaming: false,
        );
      }
      emit(state.copyWith(
          messages: msgs, isStreaming: false, error: ev.message));
    }
  }

  @override
  Future<void> close() {
    _stop();
    _users?.cancel();
    return super.close();
  }
}
