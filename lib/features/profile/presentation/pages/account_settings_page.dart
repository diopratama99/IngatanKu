import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_settings_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';
import '../../../notes/domain/entities/personal_note.dart';
import '../../../notes/presentation/widgets/note_color_palette.dart';
import '../../../notes/presentation/widgets/note_paper.dart';
import '../../domain/user_avatar.dart';
import '../widgets/settings_paper.dart';
import '../widgets/user_avatar_view.dart';

/// Your account — avatar, display name, password, language — on the
/// pet's notepaper: a member card up top (your blob-friend avatar, name
/// and email), then a sheet for each group. Name and avatar live in the
/// account (`user_metadata`), shared with the web dashboard.
///
/// Flow per field:
///   * Tap a row → an edit sheet (avatar picker, name, password,
///     language).
///   * Bloc emits `AuthProfileUpdateSuccess` → we toast + the auth
///     state stream pushes the refreshed user into the rest of the
///     app.
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  /// Pending action types we kicked off so we can scope the
  /// success-toast routing — otherwise unrelated AuthBloc emissions
  /// (e.g. avatar update emitting a Loading on top of name update)
  /// would compete for the same banner.
  String? _pendingAction;

  Future<void> _editAvatar(BuildContext context, UserEntity user) async {
    if (!await ensureOnline(context, OnlineFeature.account) ||
        !context.mounted) {
      return;
    }
    final picked = await showAvatarPicker(context,
        current: UserAvatar.of(user.avatarId, userId: user.id));
    if (picked == null || !context.mounted) return;
    setState(() => _pendingAction = 'avatar');
    context.read<AuthBloc>().add(AuthAvatarUpdateRequested(picked));
  }

  Future<void> _editName(BuildContext context, UserEntity user) async {
    if (!await ensureOnline(context, OnlineFeature.account) ||
        !context.mounted) {
      return;
    }
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditNameSheet(initial: user.displayName),
    );
    if (next == null || next.trim().isEmpty || next == user.displayName) {
      return;
    }
    if (!context.mounted) return;
    setState(() => _pendingAction = 'name');
    context.read<AuthBloc>().add(AuthDisplayNameUpdateRequested(next.trim()));
  }

  Future<void> _editPassword(BuildContext context) async {
    if (!await ensureOnline(context, OnlineFeature.account) ||
        !context.mounted) {
      return;
    }
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    ).then((submitted) {
      if (submitted == true) setState(() => _pendingAction = 'password');
    });
  }

  Future<void> _editLocale(BuildContext context) async {
    final svc = AppSettingsService.instance;
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<_LocalePick?>(
      context: context,
      backgroundColor: context.palette.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet<_LocalePick>(
        eyebrow: l10n.pickerTitleLanguage,
        current: _LocalePick.fromStored(svc.storedLocale),
        options: [
          _PickerOption(
            value: _LocalePick.system,
            label: l10n.localeSystem,
            caption: l10n.localeSystemCaption,
          ),
          _PickerOption(
            value: _LocalePick.id,
            label: l10n.localeIndonesian,
          ),
          _PickerOption(
            value: _LocalePick.en,
            label: l10n.localeEnglish,
          ),
        ],
      ),
    );
    if (picked == null) return;
    await svc.setLocale(picked.toLocale());
  }

  /// Map the persisted locale value to a row caption.
  String _localeLabel(BuildContext context, Locale? stored) {
    final l10n = AppLocalizations.of(context)!;
    if (stored == null) return l10n.localeSystem;
    switch (stored.languageCode) {
      case 'id':
        return l10n.localeIndonesian;
      case 'en':
        return l10n.localeEnglish;
      default:
        return l10n.localeSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthProfileUpdateSuccess || curr is AuthError,
      listener: (ctx, state) {
        if (state is AuthProfileUpdateSuccess && _pendingAction != null) {
          context.showSnack(state.message);
          setState(() => _pendingAction = null);
        } else if (state is AuthError && _pendingAction != null) {
          context.showSnack(state.message, error: true);
          setState(() => _pendingAction = null);
        }
      },
      buildWhen: (prev, curr) =>
          curr is Authenticated ||
          curr is AuthLoading ||
          curr is AuthProfileUpdateSuccess,
      builder: (_, state) {
        final user = _userFrom(state);
        final loading = state is AuthLoading;
        final l10n = AppLocalizations.of(context)!;
        final palette = context.palette;

        return Scaffold(
          appBar: PageTopBar(
            title: l10n.profileNavAccount,
            onBack: () => context.pop(),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                _MemberCard(
                  user: user,
                  busy: loading && _pendingAction == 'avatar',
                  onAvatar:
                      user == null ? null : () => _editAvatar(context, user),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    l10n.accountSubtitle,
                    style: AppFonts.body(
                      fontSize: 12,
                      height: 1.5,
                      color: palette.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SettingsPaper(
                  label: l10n.accountSectionIdentity,
                  tape: NoteColor.pink,
                  child: Column(
                    children: [
                      _FieldRow(
                        icon: Icons.badge_outlined,
                        sticker: NoteColor.orange,
                        label: l10n.accountFieldName,
                        value: user?.displayName ?? '-',
                        busy: loading && _pendingAction == 'name',
                        onTap: user == null
                            ? null
                            : () => _editName(context, user),
                      ),
                      const SettingsPerforation(),
                      _FieldRow(
                        icon: Icons.alternate_email_rounded,
                        sticker: NoteColor.blue,
                        label: l10n.accountFieldEmail,
                        value: user?.email ?? '-',
                        caption: l10n.accountFieldEmailCaption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SettingsPaper(
                  label: l10n.accountSectionSecurity,
                  tape: NoteColor.green,
                  // An account that only signs in with Google has no
                  // password to change: how it signs in instead.
                  child: user != null && !user.hasPassword
                      ? _FieldRow(
                          icon: Icons.lock_outline_rounded,
                          sticker: NoteColor.purple,
                          label: l10n.accountFieldSignIn,
                          value: 'Google',
                          caption: l10n.accountFieldSignInGoogleCaption,
                        )
                      : _FieldRow(
                          icon: Icons.lock_outline_rounded,
                          sticker: NoteColor.purple,
                          label: l10n.accountFieldPassword,
                          value: '•••••••',
                          busy: loading && _pendingAction == 'password',
                          onTap: () => _editPassword(context),
                        ),
                ),
                const SizedBox(height: 30),
                // The language lives on the phone, not in the account.
                SettingsPaper(
                  label: l10n.accountSectionPreferences,
                  tape: NoteColor.yellow,
                  child: AnimatedBuilder(
                    animation: AppSettingsService.instance,
                    builder: (_, __) => _FieldRow(
                      icon: Icons.translate_rounded,
                      sticker: NoteColor.teal,
                      label: l10n.accountFieldLanguage,
                      value: _localeLabel(
                          context, AppSettingsService.instance.storedLocale),
                      onTap: () => _editLocale(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pull the user out of whichever state we're in. We don't want
  /// `AuthLoading` to blank the page.
  UserEntity? _userFrom(AuthState state) {
    if (state is Authenticated) return state.user;
    if (state is AuthProfileUpdateSuccess) return state.user;
    final cached = context.read<AuthBloc>().state;
    if (cached is Authenticated) return cached.user;
    if (cached is AuthProfileUpdateSuccess) return cached.user;
    return null;
  }
}

// ════════════════════════════════════════════════════════════════
//                      MEMBER CARD
// ════════════════════════════════════════════════════════════════

/// Your card for the library: a band in your avatar's pastel, the
/// avatar (tap it to pick another), your name and email, and a little
/// barcode with your member number.
class _MemberCard extends StatelessWidget {
  final UserEntity? user;
  final bool busy;
  final VoidCallback? onAvatar;
  const _MemberCard({
    required this.user,
    required this.busy,
    required this.onAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final avatar = UserAvatar.of(user?.avatarId, userId: user?.id ?? '');
    final swatch = NoteColorPalette.swatch(avatar.paper);
    final ink = Color.lerp(swatch, Colors.black, 0.55)!;
    final number = _memberNumber(user?.id ?? '');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: notePaperDecoration(context, radius: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The card's band.
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  color: NoteColorPalette.background(avatar.paper),
                  child: Row(
                    children: [
                      Icon(Icons.local_library_outlined, size: 15, color: ink),
                      const SizedBox(width: 8),
                      Text(
                        l10n.accountCardEyebrow.toUpperCase(),
                        style: AppFonts.body(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'IngatanKu',
                        style: AppFonts.display(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ink.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Row(
                    children: [
                      _AvatarButton(
                        avatar: avatar,
                        busy: busy,
                        onTap: onAvatar,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? '-',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.display(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.2,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(
                                fontSize: 12.5,
                                color: palette.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (onAvatar != null)
                              GestureDetector(
                                onTap: busy ? null : onAvatar,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: NoteColorPalette.background(
                                        avatar.paper),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: NoteColorPalette.border(
                                            avatar.paper)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded,
                                          size: 14, color: ink),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.accountChangeAvatar,
                                        style: AppFonts.body(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // A barcode and the member number, like a real card.
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 22,
                          child: CustomPaint(
                            painter: _BarcodePainter(
                              seed: user?.id ?? '',
                              color:
                                  palette.textTertiary.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'No. $number',
                        style: AppFonts.body(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -9,
          right: 26,
          child: WashiTape(color: swatch, width: 60, angle: 0.08),
        ),
      ],
    );
  }

  /// Four digits that stay the same for the user.
  static String _memberNumber(String id) {
    var hash = 7;
    for (final c in id.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return (hash % 10000).toString().padLeft(4, '0');
  }
}

/// The avatar on the card, with a little pencil sticker to say it can be
/// changed; a spinner over it while the new one is saved.
class _AvatarButton extends StatelessWidget {
  final UserAvatar avatar;
  final bool busy;
  final VoidCallback? onTap;
  const _AvatarButton({
    required this.avatar,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatarView(avatar: avatar, size: 88),
            if (busy)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
            if (onTap != null)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primary,
                    border: Border.all(
                        color:
                            NoteColorPalette.background(NoteColor.defaultColor),
                        width: 2.5),
                  ),
                  child: Icon(Icons.edit_rounded,
                      size: 14, color: palette.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bars of different widths, the same every time for [seed].
class _BarcodePainter extends CustomPainter {
  final String seed;
  final Color color;
  const _BarcodePainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var hash = 17;
    for (final c in seed.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final rng = math.Random(hash);
    final paint = Paint()..color = color;
    var x = 0.0;
    while (x < size.width) {
      final w = 1.0 + rng.nextInt(3);
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w + 1.5 + rng.nextInt(3);
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) =>
      old.seed != seed || old.color != color;
}

// ════════════════════════════════════════════════════════════════
//                      ROW
// ════════════════════════════════════════════════════════════════

/// One field on a sheet: its sticker, what it is, its value (and a note
/// under it), and a chevron when it can be changed — or a spinner while
/// it's being saved.
class _FieldRow extends StatelessWidget {
  final IconData icon;
  final NoteColor sticker;
  final String label;
  final String value;
  final String? caption;
  final bool busy;
  final VoidCallback? onTap;
  const _FieldRow({
    required this.icon,
    required this.sticker,
    required this.label,
    required this.value,
    this.caption,
    this.busy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SettingsSticker(icon: icon, color: sticker),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppFonts.body(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      style: AppFonts.body(
                        fontSize: 11.5,
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (busy)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: palette.primary,
                ),
              )
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                      EDIT NAME SHEET
// ════════════════════════════════════════════════════════════════

class _EditNameSheet extends StatefulWidget {
  final String initial;
  const _EditNameSheet({required this.initial});

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetGrabber(),
              Text('UBAH NAMA', style: eyebrowStyle(context: context)),
              const SizedBox(height: 14),
              TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: AppFonts.body(
                  fontSize: 16,
                  color: context.palette.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Nama tampilan',
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.primary,
                  foregroundColor: context.palette.onPrimary,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'SIMPAN',
                  style: AppFonts.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.palette.surfaceStroke,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                  CHANGE PASSWORD SHEET
// ════════════════════════════════════════════════════════════════

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthChangePasswordRequested(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          ),
        );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetGrabber(),
                Text('UBAH KATA SANDI', style: eyebrowStyle(context: context)),
                const SizedBox(height: 4),
                Text(
                  'Masukkan kata sandi saat ini sebagai konfirmasi.',
                  style: AppFonts.body(
                    fontSize: 12,
                    color: context.palette.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                _PasswordField(
                  controller: _currentCtrl,
                  label: 'Kata sandi saat ini',
                  obscure: !_showCurrent,
                  onToggle: () =>
                      setState(() => _showCurrent = !_showCurrent),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _newCtrl,
                  label: 'Kata sandi baru',
                  obscure: !_showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Minimal 6 karakter';
                    }
                    if (v == _currentCtrl.text) {
                      return 'Tidak boleh sama dengan kata sandi saat ini';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _confirmCtrl,
                  label: 'Konfirmasi kata sandi baru',
                  obscure: !_showConfirm,
                  onToggle: () =>
                      setState(() => _showConfirm = !_showConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v != _newCtrl.text) return 'Tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'SIMPAN KATA SANDI',
                    style: AppFonts.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: false,
      style: AppFonts.body(
        fontSize: 15,
        color: context.palette.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                  PREFERENCE PICKER SHEET
// ════════════════════════════════════════════════════════════════

/// Tri-state locale value because [Locale] doesn't model "follow
/// system" — that's our null marker — and we need a single enum that
/// the picker sheet can compare with `==`.
enum _LocalePick {
  system,
  id,
  en;

  static _LocalePick fromStored(Locale? stored) {
    if (stored == null) return _LocalePick.system;
    return switch (stored.languageCode) {
      'id' => _LocalePick.id,
      'en' => _LocalePick.en,
      _ => _LocalePick.system,
    };
  }

  Locale? toLocale() => switch (this) {
        _LocalePick.system => null,
        _LocalePick.id => const Locale('id'),
        _LocalePick.en => const Locale('en'),
      };
}

/// Plain data class for sheet options. Kept generic on `T` so the
/// same widget renders both locale and theme pickers — both surfaces
/// look identical so the user learns the affordance once.
class _PickerOption<T> {
  final T value;
  final String label;
  final String? caption;
  const _PickerOption({
    required this.value,
    required this.label,
    this.caption,
  });
}

/// Bottom sheet with a list of selectable options. Tap a row to pop
/// the sheet with that value; tap the grabber/scrim to dismiss with
/// `null`. The currently-selected option gets a check mark.
class _PickerSheet<T> extends StatelessWidget {
  final String eyebrow;
  final T current;
  final List<_PickerOption<T>> options;
  const _PickerSheet({
    required this.eyebrow,
    required this.current,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetGrabber(),
            Text(eyebrow, style: eyebrowStyle(context: context)),
            const SizedBox(height: 8),
            for (var i = 0; i < options.length; i++) ...[
              _PickerRow(
                option: options[i],
                selected: options[i].value == current,
                onTap: () => Navigator.pop(context, options[i].value),
              ),
              if (i != options.length - 1) const ThinDivider(opacity: 0.25),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickerRow<T> extends StatelessWidget {
  final _PickerOption<T> option;
  final bool selected;
  final VoidCallback onTap;
  const _PickerRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: AppFonts.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  if (option.caption != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      option.caption!,
                      style: AppFonts.body(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                size: 18,
                color: context.palette.primary,
              ),
          ],
        ),
      ),
    );
  }
}
