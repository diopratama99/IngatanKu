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
    super.thumbnailUrl,
    super.inQuiz,
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
      // In the phone's time zone, like notes made on the phone.
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      inQuiz: json['in_quiz'] as bool? ?? true,
    );
  }

  /// The server row, id and time included (both are made on the device).
  Map<String, dynamic> toRow() => {
        'id': id,
        'user_id': userId,
        'url': url,
        'title': title,
        'manual_notes': manualNotes,
        'tags': tags,
        'source_type': sourceType,
        'thumbnail_url': thumbnailUrl,
        'in_quiz': inQuiz,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  NoteModel copyWith({
    String? url,
    String? title,
    String? manualNotes,
    List<String>? tags,
    String? sourceType,
    String? thumbnailUrl,
    bool? inQuiz,
  }) =>
      NoteModel(
        id: id,
        userId: userId,
        url: url ?? this.url,
        title: title ?? this.title,
        manualNotes: manualNotes ?? this.manualNotes,
        tags: tags ?? this.tags,
        sourceType: sourceType ?? this.sourceType,
        createdAt: createdAt,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        inQuiz: inQuiz ?? this.inQuiz,
      );
}
