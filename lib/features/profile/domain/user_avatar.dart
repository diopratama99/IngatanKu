import '../../notes/domain/entities/personal_note.dart';

/// The animals there are to pick from.
enum AvatarAnimal {
  cat,
  dog,
  bear,
  bunny,
  panda,
  fox,
  frog,
  owl,
  koala,
  pig,
  penguin,
  lion,
}

/// The user's picture: a little animal face, picked from a set ([all]),
/// on its own pastel paper. Saved to the account by [id]
/// (`user_metadata.avatar_id`).
class UserAvatar {
  final String id;
  final AvatarAnimal animal;

  /// The pastel behind it.
  final NoteColor paper;

  const UserAvatar(this.id, this.animal, {required this.paper});

  static const all = <UserAvatar>[
    UserAvatar('cat', AvatarAnimal.cat, paper: NoteColor.yellow),
    UserAvatar('dog', AvatarAnimal.dog, paper: NoteColor.blue),
    UserAvatar('bear', AvatarAnimal.bear, paper: NoteColor.green),
    UserAvatar('bunny', AvatarAnimal.bunny, paper: NoteColor.pink),
    UserAvatar('panda', AvatarAnimal.panda, paper: NoteColor.teal),
    UserAvatar('fox', AvatarAnimal.fox, paper: NoteColor.purple),
    UserAvatar('frog', AvatarAnimal.frog, paper: NoteColor.yellow),
    UserAvatar('owl', AvatarAnimal.owl, paper: NoteColor.orange),
    UserAvatar('koala', AvatarAnimal.koala, paper: NoteColor.green),
    UserAvatar('pig', AvatarAnimal.pig, paper: NoteColor.blue),
    UserAvatar('penguin', AvatarAnimal.penguin, paper: NoteColor.pink),
    UserAvatar('lion', AvatarAnimal.lion, paper: NoteColor.teal),
  ];

  /// The avatar saved as [id] — or, if there's none yet (or it's not one
  /// of ours), one picked for [userId] that stays the same for them.
  static UserAvatar of(String? id, {required String userId}) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    var hash = 0;
    for (final c in userId.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return all[hash % all.length];
  }
}
