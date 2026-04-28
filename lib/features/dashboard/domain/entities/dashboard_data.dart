import 'package:equatable/equatable.dart';
import '../../../vault/domain/entities/note_entity.dart';

class DashboardData extends Equatable {
  final String username;
  final int level;
  final int xp;
  final int xpForNextLevel;
  final int streakDays;
  final int totalNotes;
  final int badgesUnlocked;
  final List<NoteEntity> recentNotes;
  final List<TagCount> topTags;

  const DashboardData({
    required this.username,
    required this.level,
    required this.xp,
    required this.xpForNextLevel,
    required this.streakDays,
    required this.totalNotes,
    required this.badgesUnlocked,
    required this.recentNotes,
    required this.topTags,
  });

  double get xpProgress {
    if (xpForNextLevel == 0) return 0;
    final into = xp % xpForNextLevel;
    return into / xpForNextLevel;
  }

  @override
  List<Object?> get props =>
      [username, level, xp, streakDays, totalNotes, badgesUnlocked, recentNotes, topTags];
}

class TagCount extends Equatable {
  final String tag;
  final int count;
  const TagCount(this.tag, this.count);
  @override
  List<Object?> get props => [tag, count];
}
