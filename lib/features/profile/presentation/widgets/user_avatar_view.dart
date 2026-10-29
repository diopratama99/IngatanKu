import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../notes/presentation/widgets/note_color_palette.dart';
import '../../domain/user_avatar.dart';
import 'animal_face_painter.dart';

/// The user's avatar: their little animal, in a round frame of its
/// pastel paper.
class UserAvatarView extends StatelessWidget {
  final UserAvatar avatar;
  final double size;
  const UserAvatarView({super.key, required this.avatar, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NoteColorPalette.background(avatar.paper),
        border: Border.all(
            color: NoteColorPalette.border(avatar.paper),
            width: size > 60 ? 2 : 1.5),
      ),
      child: ClipOval(
        child: CustomPaint(painter: AnimalFacePainter(avatar.animal)),
      ),
    );
  }
}

extension AvatarAnimalName on AppLocalizations {
  /// What the animal is called.
  String avatarAnimal(AvatarAnimal a) => switch (a) {
        AvatarAnimal.cat => avatarCat,
        AvatarAnimal.dog => avatarDog,
        AvatarAnimal.bear => avatarBear,
        AvatarAnimal.bunny => avatarBunny,
        AvatarAnimal.panda => avatarPanda,
        AvatarAnimal.fox => avatarFox,
        AvatarAnimal.frog => avatarFrog,
        AvatarAnimal.owl => avatarOwl,
        AvatarAnimal.koala => avatarKoala,
        AvatarAnimal.pig => avatarPig,
        AvatarAnimal.penguin => avatarPenguin,
        AvatarAnimal.lion => avatarLion,
      };
}

/// Lets the user pick an avatar from [UserAvatar.all], [current] chosen
/// to start with. The picked avatar's id, or null if they changed their
/// mind.
Future<String?> showAvatarPicker(BuildContext context,
    {required UserAvatar current}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AvatarPicker(current: current),
  );
}

class _AvatarPicker extends StatefulWidget {
  final UserAvatar current;
  const _AvatarPicker({required this.current});

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  late UserAvatar _picked = widget.current;

  void _pick(UserAvatar a) {
    if (a.id == _picked.id) return;
    HapticFeedback.selectionClick();
    SoundService.instance.play(Sfx.equip);
    setState(() => _picked = a);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final changed = _picked.id != widget.current.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.surfaceStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: UserAvatarView(
                    key: ValueKey(_picked.id), avatar: _picked, size: 76),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.avatarPickerTitle,
                      style: AppFonts.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.avatarPickerBody,
                      style: AppFonts.body(
                        fontSize: 13,
                        height: 1.4,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 14,
            // Room for the name under each.
            childAspectRatio: 0.74,
            children: [
              for (final a in UserAvatar.all)
                _AvatarChoice(
                  avatar: a,
                  picked: a.id == _picked.id,
                  onTap: () => _pick(a),
                ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed:
                changed ? () => Navigator.pop(context, _picked.id) : null,
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(l10n.avatarPickerUse),
          ),
        ],
      ),
    );
  }
}

/// One avatar in the grid, its name under it; the picked one gets a
/// ring and a tick.
class _AvatarChoice extends StatelessWidget {
  final UserAvatar avatar;
  final bool picked;
  final VoidCallback onTap;
  const _AvatarChoice({
    required this.avatar,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = AppLocalizations.of(context)!.avatarAnimal(avatar.animal);
    return Semantics(
      button: true,
      selected: picked,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: LayoutBuilder(builder: (context, c) {
          final size = c.maxWidth;
          return Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: picked ? palette.primary : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: UserAvatarView(avatar: avatar, size: size - 11),
                  ),
                  if (picked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.primary,
                          border:
                              Border.all(color: palette.bgSecondary, width: 2),
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 13, color: palette.onPrimary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.body(
                  fontSize: 11.5,
                  fontWeight: picked ? FontWeight.w700 : FontWeight.w500,
                  color: picked ? palette.textPrimary : palette.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
