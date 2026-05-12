import 'package:equatable/equatable.dart';

class NoteEntity extends Equatable {
  final String id;
  final String userId;
  final String url;
  final String? title;
  final String manualNotes;
  final List<String> tags;
  final String sourceType; // youtube|tiktok|instagram|x|article|other
  final DateTime createdAt;

  const NoteEntity({
    required this.id,
    required this.userId,
    required this.url,
    this.title,
    required this.manualNotes,
    required this.tags,
    required this.sourceType,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, url, title, manualNotes, tags, sourceType, createdAt];
}
