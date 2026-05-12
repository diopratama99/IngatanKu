import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

class SourceEntity extends Equatable {
  final String noteId;
  final String? title;
  final double similarity;
  const SourceEntity({required this.noteId, this.title, required this.similarity});
  @override
  List<Object?> get props => [noteId, title, similarity];
}

class MessageEntity extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final List<SourceEntity> sources;
  final bool streaming;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.role,
    required this.content,
    this.sources = const [],
    this.streaming = false,
    required this.createdAt,
  });

  MessageEntity copyWith({String? content, List<SourceEntity>? sources, bool? streaming}) {
    return MessageEntity(
      id: id,
      role: role,
      content: content ?? this.content,
      sources: sources ?? this.sources,
      streaming: streaming ?? this.streaming,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, role, content, sources, streaming, createdAt];
}
