import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/router/app_router.dart';
import '../../../companion/presentation/widgets/pet_room_card.dart';
import '../../../notes/domain/entities/personal_note.dart';
import '../../../notes/presentation/widgets/note_color_palette.dart';
import '../../domain/user_avatar.dart';
import '../widgets/settings_paper.dart';
import '../widgets/user_avatar_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// Shows a confirmation dialog before dispatching [AuthSignOutRequested].
  /// We grab the bloc reference *before* the await so we don't have to use
  /// `BuildContext` across an async gap (avoids `use_build_context_synchronously`).
  ///
  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.palette.surfaceStroke, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 14, 12),
        title: Text(
          l10n.profileSignOutDialogTitle,
          style: AppFonts.display(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: context.palette.textPrimary,
            height: 1.15,
          ),
        ),
        content: Text(
          l10n.profileSignOutDialogMessage,
          style: AppFonts.body(
            fontSize: 14,
            height: 1.55,
            color: context.palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              l10n.profileSignOutDialogCancel,
              style: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              l10n.profileSignOutDialogConfirm,
              style: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(AuthSignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: SpacedTitle(l10n.navProfile),
      ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          // Rebuild on auth changes so the header reflects fresh
          // display name / avatar after the user edits them in
          // /profile/account.
          buildWhen: (prev, curr) =>
              curr is Authenticated || curr is AuthProfileUpdateSuccess,
          builder: (ctx, state) {
            final user = _userFrom(state);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  16, 8, 16, 32 + kEditorialNavBarOverlay),
              children: [
                _IdentityBlock(
                  user: user,
                  onTap: () => context.push(Routes.accountSettings),
                  onSignOut: () => _confirmSignOut(context),
                ),
                const SizedBox(height: 20),
                const PetRoomCard(),
                const SizedBox(height: 32),

                // ─── Pengaturan: sheets of the pet's notepaper ───
                SettingsPaper(
                  label: l10n.profileGroupSound,
                  tape: NoteColor.yellow,
                  child: const _SoundPanel(),
                ),
                const SizedBox(height: 30),
                SettingsPaper(
                  label: l10n.accountFieldLanguage,
                  tape: NoteColor.purple,
                  child: const _LanguagePanel(),
                ),
                const SizedBox(height: 30),
                SettingsPaper(
                  label: l10n.profileGroupYou,
                  tape: NoteColor.pink,
                  child: Column(children: [
                    _MenuRow(
                      icon: Icons.manage_accounts_outlined,
                      sticker: NoteColor.orange,
                      label: l10n.profileNavAccount,
                      onTap: () => context.push(Routes.accountSettings),
                    ),
                    const SettingsPerforation(),
                    _MenuRow(
                      icon: Icons.privacy_tip_outlined,
                      sticker: NoteColor.green,
                      label: l10n.profileNavPrivacy,
                      onTap: () => context.push(Routes.privacy),
                    ),
                  ]),
                ),
                const SizedBox(height: 30),
                SettingsPaper(
                  label: l10n.profileGroupNotes,
                  tape: NoteColor.blue,
                  child: Column(children: [
                    _MenuRow(
                      icon: Icons.sell_outlined,
                      sticker: NoteColor.purple,
                      label: l10n.featureManageTags,
                      onTap: () => context.push(Routes.tags),
                    ),
                    const SettingsPerforation(),
                    _MenuRow(
                      icon: Icons.sd_storage_outlined,
                      sticker: NoteColor.teal,
                      label: l10n.profileNavStorage,
                      onTap: () => context.push(Routes.storage),
                    ),
                    const SettingsPerforation(),
                    _MenuRow(
                      icon: Icons.auto_awesome_outlined,
                      sticker: NoteColor.yellow,
                      label: l10n.profileNavAiSearch,
                      onTap: () => context.push(Routes.reindex),
                    ),
                  ]),
                ),
                const SizedBox(height: 30),
                SettingsPaper(
                  label: l10n.profileGroupMore,
                  tape: NoteColor.green,
                  child: _MenuRow(
                    icon: Icons.info_outline,
                    sticker: NoteColor.pink,
                    label: l10n.profileNavAbout,
                    onTap: () => context.push(Routes.about),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  UserEntity? _userFrom(AuthState state) {
    if (state is Authenticated) return state.user;
    if (state is AuthProfileUpdateSuccess) return state.user;
    return null;
  }
}

/// Avatar + display name + email + sign-out icon. Tapping the row
/// (anywhere except the sign-out button) navigates to the Account
/// Settings page so the user has two equally-discoverable paths to
/// edit their profile.
class _IdentityBlock extends StatelessWidget {
  final UserEntity? user;
  final VoidCallback onTap;
  final VoidCallback onSignOut;
  const _IdentityBlock({
    required this.user,
    required this.onTap,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatarView(
              avatar: UserAvatar.of(user?.avatarId, userId: user?.id ?? ''),
              size: 64,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? l10n.profileFallbackDisplayName,
                    style: pageTitleStyle(context: context, size: 26),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: AppFonts.body(
                      fontSize: 13,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.profileSignOutTooltip,
              onPressed: onSignOut,
              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.danger,
              ),
              splashRadius: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final NoteColor sticker;
  final String label;
  final VoidCallback onTap;
  const _MenuRow({
    required this.icon,
    required this.sticker,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SettingsSticker(icon: icon, color: sticker),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppFonts.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: context.palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// The three sound switches as big buttons that light up in their own
/// pastel when they're on: the pet's sounds, the music, and each room's
/// quiet background sound.
class _SoundPanel extends StatelessWidget {
  const _SoundPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sound = SoundService.instance;
    return ListenableBuilder(
      listenable: sound,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: _SoundTile(
                icon: sound.enabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: l10n.profileSoundEffects,
                color: NoteColor.yellow,
                on: sound.enabled,
                onChanged: (on) {
                  sound.setEnabled(on);
                  // A little squeak to show it's back on.
                  if (on) sound.play(Sfx.pet);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SoundTile(
                icon: Icons.music_note_rounded,
                label: l10n.profileBackgroundMusic,
                color: NoteColor.pink,
                on: sound.musicEnabled,
                onChanged: sound.setMusicEnabled,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SoundTile(
                icon: Icons.weekend_rounded,
                label: l10n.profileRoomAmbience,
                color: NoteColor.green,
                on: sound.ambienceEnabled,
                onChanged: sound.setAmbienceEnabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the sound switches: a [_PastelTile] that says "on" / "off".
class _SoundTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final NoteColor color;
  final bool on;
  final ValueChanged<bool> onChanged;
  const _SoundTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.on,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _PastelTile(
      mark: (ink) => Icon(icon, size: 22, color: ink),
      label: label,
      status: on ? l10n.profileSoundOn : l10n.profileSoundOff,
      color: color,
      on: on,
      onTap: () => onChanged(!on),
    );
  }
}

/// The app's language, picked from three tiles like the sound switches:
/// the phone's language, Bahasa Indonesia or English. The app switches
/// straight away.
class _LanguagePanel extends StatelessWidget {
  const _LanguagePanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = AppSettingsService.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final current = settings.storedLocale?.languageCode;
        Widget tile(String? code, String label, NoteColor color,
                Widget Function(Color ink) mark) =>
            Expanded(
              child: _PastelTile(
                mark: mark,
                label: label,
                status: current == code
                    ? l10n.profileLanguageInUse
                    : l10n.profileLanguagePick,
                color: color,
                on: current == code,
                radio: true,
                onTap: () {
                  if (current == code) return;
                  settings.setLocale(code == null ? null : Locale(code));
                },
              ),
            );
        return Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  tile(
                      null,
                      l10n.localeSystem,
                      NoteColor.teal,
                      (ink) =>
                          Icon(Icons.smartphone_rounded, size: 22, color: ink)),
                  const SizedBox(width: 10),
                  tile('id', l10n.localeIndonesian, NoteColor.red,
                      (ink) => _LanguageBadge('ID', ink: ink)),
                  const SizedBox(width: 10),
                  tile('en', l10n.localeEnglish, NoteColor.blue,
                      (ink) => _LanguageBadge('EN', ink: ink)),
                ],
              ),
              if (current == null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    l10n.localeSystemCaption,
                    style: AppFonts.body(
                      fontSize: 12,
                      height: 1.4,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A language's two letters in a little outlined box, the size of an
/// icon.
class _LanguageBadge extends StatelessWidget {
  final String code;
  final Color ink;
  const _LanguageBadge(this.code, {required this.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ink, width: 1.6),
      ),
      child: Text(
        code,
        style: AppFonts.body(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          height: 1,
          color: ink,
        ),
      ),
    );
  }
}

/// A big button that lights up in its own pastel while [on]: its [mark]
/// (drawn in the given ink), its [label], and a little lamp with
/// [status] under it. With [radio] it's one choice of a set (selected)
/// rather than a switch (toggled).
class _PastelTile extends StatelessWidget {
  final Widget Function(Color ink) mark;
  final String label;
  final String status;
  final NoteColor color;
  final bool on;
  final bool radio;
  final VoidCallback onTap;
  const _PastelTile({
    required this.mark,
    required this.label,
    required this.status,
    required this.color,
    required this.on,
    required this.onTap,
    this.radio = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final swatch = NoteColorPalette.swatch(color);
    final ink = on
        ? (Color.lerp(swatch, Colors.black, 0.5)!)
        : palette.textTertiary;
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      toggled: radio ? null : on,
      selected: radio ? on : null,
      inMutuallyExclusiveGroup: radio ? true : null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(11, 12, 10, 11),
            decoration: BoxDecoration(
              color: on
                  ? NoteColorPalette.background(color)
                  : palette.bgPrimary,
              borderRadius: radius,
              border: Border.all(
                color: on ? swatch : palette.surfaceStroke,
                width: on ? 1.5 : 1,
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: swatch.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 22,
                  child:
                      Align(alignment: Alignment.centerLeft, child: mark(ink)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: on ? palette.textPrimary : palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Its little lamp: lit while it's on.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? swatch : palette.surfaceStroke,
                        boxShadow: on
                            ? [
                                BoxShadow(
                                  color: swatch.withValues(alpha: 0.7),
                                  blurRadius: 6,
                                ),
                              ]
                            : const [],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
