import 'package:equatable/equatable.dart';

class NoteEntity extends Equatable {
  final String id;
  final String userId;
  final String url;
  final String? title;
  final String manualNotes;
  final List<String> tags;
  final String
      sourceType; // youtube|tiktok|instagram|threads|facebook|x|article|other
  final DateTime createdAt;

  /// OG/Twitter image scraped by `fetch-meta` (or its Microlink fallback)
  /// at the time the note was added. Used for list-row thumbnails and the
  /// detail page hero/cover when no video is playable.
  final String? thumbnailUrl;

  /// Whether the daily quiz and the weekly feast may ask about this note.
  /// Off for links only worth keeping, like a comic or book title.
  final bool inQuiz;

  const NoteEntity({
    required this.id,
    required this.userId,
    required this.url,
    this.title,
    required this.manualNotes,
    required this.tags,
    required this.sourceType,
    required this.createdAt,
    this.thumbnailUrl,
    this.inQuiz = true,
  });

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        manualNotes,
        tags,
        sourceType,
        createdAt,
        thumbnailUrl,
        inQuiz,
      ];
}
