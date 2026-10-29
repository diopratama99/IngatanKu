import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/message_entity.dart';

/// The conversation on the Assistant page, kept on the phone so it's
/// still there when the app is opened again. One at a time, for the
/// account it belongs to (signing out drops it); "Mulai sesi baru" starts
/// another (a new session id, so the server's memory of the old one stays
/// out of it).
class ChatSessionStore {
  ChatSessionStore(this._prefs);

  final SharedPreferences _prefs;

  static const _keyUser = 'chat.user';
  static const _keySession = 'chat.session';
  static const _keyMessages = 'chat.messages';

  /// The most messages kept (the newest).
  static const keep = 40;

  /// [user]'s conversation, or a fresh one when there's none (or it's
  /// someone else's).
  ({String sessionId, List<MessageEntity> messages}) load(String? user) {
    final session = _prefs.getString(_keySession);
    if (user == null || session == null || _prefs.getString(_keyUser) != user) {
      return (sessionId: start(user), messages: const []);
    }
    return (sessionId: session, messages: _messages());
  }

  /// Keeps [messages] as [user]'s conversation [sessionId].
  Future<void> save(
      String? user, String sessionId, List<MessageEntity> messages) async {
    if (user == null) return;
    final kept = messages.length > keep
        ? messages.sublist(messages.length - keep)
        : messages;
    await _prefs.setString(_keyUser, user);
    await _prefs.setString(_keySession, sessionId);
    await _prefs.setString(
        _keyMessages, jsonEncode([for (final m in kept) _toJson(m)]));
  }

  /// A new, empty conversation for [user]; returns its session id.
  String start(String? user) {
    final id = const Uuid().v4();
    if (user != null) {
      _prefs.setString(_keyUser, user);
      _prefs.setString(_keySession, id);
    }
    _prefs.remove(_keyMessages);
    return id;
  }

  List<MessageEntity> _messages() {
    final raw = _prefs.getString(_keyMessages);
    if (raw == null) return const [];
    try {
      return [
        for (final m in jsonDecode(raw) as List)
          _fromJson(m as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Map<String, dynamic> _toJson(MessageEntity m) => {
        'id': m.id,
        'role': m.role.name,
        'content': m.content,
        'at': m.createdAt.toIso8601String(),
        'sources': [
          for (final s in m.sources)
            {'id': s.noteId, 'title': s.title, 'similarity': s.similarity},
        ],
      };

  static MessageEntity _fromJson(Map<String, dynamic> j) => MessageEntity(
        id: j['id'] as String,
        role: MessageRole.values.byName(j['role'] as String),
        content: j['content'] as String,
        createdAt: DateTime.parse(j['at'] as String),
        sources: [
          for (final s in (j['sources'] as List? ?? const []))
            SourceEntity(
              noteId: s['id'] as String,
              title: s['title'] as String?,
              similarity: (s['similarity'] as num).toDouble(),
            ),
        ],
      );
}
