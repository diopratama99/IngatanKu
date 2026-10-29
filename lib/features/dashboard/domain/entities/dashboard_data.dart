import 'package:equatable/equatable.dart';
import '../../../vault/domain/entities/note_entity.dart';

class DashboardData extends Equatable {
  /// Days in a row the pet has been looked after (0 when broken).
  final int streakDays;
  final int totalNotes;

  /// Latest saved notes, newest first. Beranda serves the ones the
  /// pet hasn't eaten yet as food in its pantry.
  final List<NoteEntity> recentNotes;
  final List<TagCount> topTags;

  const DashboardData({
    required this.streakDays,
    required this.totalNotes,
    required this.recentNotes,
    required this.topTags,
  });

  @override
  List<Object?> get props => [streakDays, totalNotes, recentNotes, topTags];
}

class TagCount extends Equatable {
  final String tag;
  final int count;
  const TagCount(this.tag, this.count);
  @override
  List<Object?> get props => [tag, count];
}
