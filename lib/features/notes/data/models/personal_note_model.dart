import '../../domain/entities/personal_note.dart';

class PersonalNoteModel extends PersonalNote {
  const PersonalNoteModel({
    required super.id,
    required super.userId,
    super.title,
    required super.body,
    super.imageFiles,
    super.links,
    super.tags,
    super.pinned,
    super.color,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PersonalNoteModel.fromMap(Map<String, dynamic> json) {
    final rawLinks = (json['links'] as List?) ?? const [];
    return PersonalNoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      imageFiles: (json['image_files'] as List?)?.cast<String>() ?? const [],
      links: rawLinks
          .whereType<Map>()
          .map((e) => NoteLink.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      pinned: json['pinned'] as bool? ?? false,
      color: NoteColor.parse(json['color'] as String?),
      // In the phone's time zone, like notes made on the phone.
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  /// [n] as a model, with [userId] as its owner when given.
  factory PersonalNoteModel.of(PersonalNote n, {String? userId}) =>
      PersonalNoteModel(
        id: n.id,
        userId: userId ?? n.userId,
        title: n.title,
        body: n.body,
        imageFiles: n.imageFiles,
        links: n.links,
        tags: n.tags,
        pinned: n.pinned,
        color: n.color,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
      );

  /// The server row. The id and creation time are made on the device
  /// (the note may have been written offline); `updated_at` is bumped
  /// by the server on every update.
  Map<String, dynamic> toUpsert({required String userId}) => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'image_files': imageFiles,
        'links': links.map((l) => l.toJson()).toList(),
        'tags': tags,
        'pinned': pinned,
        'color': color.wireValue,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
