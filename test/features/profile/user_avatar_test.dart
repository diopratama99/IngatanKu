import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/profile/domain/user_avatar.dart';

void main() {
  test('the avatar the user picked', () {
    final a = UserAvatar.of('fox', userId: 'u1');
    expect(a.id, 'fox');
    expect(a.animal, AvatarAnimal.fox);
  });

  test('none picked yet: one of the set, the same every time', () {
    final a = UserAvatar.of(null, userId: 'user-42');
    expect(UserAvatar.all, contains(a));
    expect(UserAvatar.of(null, userId: 'user-42').id, a.id);
    // An id that's not ours (an old blob one) counts as none.
    expect(UserAvatar.of('honey-crown', userId: 'user-42').id, a.id);
  });

  test('every avatar has its own id', () {
    final ids = {for (final a in UserAvatar.all) a.id};
    expect(ids, hasLength(UserAvatar.all.length));
  });
}
