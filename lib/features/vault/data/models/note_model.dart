import '../../domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.userId,
    required super.url,
    super.title,
    required super.manualNotes,
    required super.tags,
    required super.sourceType,
    required super.createdAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      url: json['url'] as String,
      title: json['title'] as String?,
      manualNotes: json['manual_notes'] as String? ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      sourceType: json['source_type'] as String? ?? 'other',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsert() => {
        'user_id': userId,
        'url': url,
        'title': title,
        'manual_notes': manualNotes,
        'tags': tags,
        'source_type': sourceType,
      };
}
