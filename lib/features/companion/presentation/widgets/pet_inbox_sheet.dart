import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/pet_inbox.dart';
import '../../data/pet_store.dart';
import '../pet_labels.dart';
import 'pet_host.dart';

/// Opens the pet's inbox (the bell on Beranda). Everything in it counts as
/// seen once it's open. Returns the note that was tapped, so the caller can
/// take you where it points (feed it, open the quiz, its profile…).
Future<PetNotice?> showPetInbox(BuildContext context) {
  SoundService.instance.play(Sfx.sheetOpen);
  return showModalBottomSheet<PetNotice>(
    context: context,
    // Above the shell so the floating nav bar doesn't cover it.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _PetInboxSheet(),
  );
}

class _PetInboxSheet extends StatefulWidget {
  const _PetInboxSheet();

  @override
  State<_PetInboxSheet> createState() => _PetInboxSheetState();
}

class _PetInboxSheetState extends State<_PetInboxSheet> {
  final _inbox = sl<PetInbox>();
  final _now = DateTime.now();

  /// What was new when it opened — still marked as new while it's open.
  late final Set<String> _unread = _inbox.unreadIds(_now);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _inbox.markAllSeen(_now));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final name = l10n.petName(sl<PetStore>());
    final notices = _inbox.notices(_now);
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Text(
              l10n.inboxTitle(name),
              style: AppFonts.display(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: palette.textPrimary,
              ),
            ),
          ),
          if (notices.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Center(
                child: Column(
                  children: [
                    const PetHost(height: 72),
                    const SizedBox(height: 12),
                    Text(
                      l10n.inboxEmptyTitle,
                      style: AppFonts.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.inboxEmptyBody(name),
                      textAlign: TextAlign.center,
                      style: AppFonts.body(
                          fontSize: 13, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: notices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _NoticeTile(
                  notice: notices[i],
                  name: name,
                  now: _now,
                  isNew: _unread.contains(notices[i].id),
                  onTap: () => Navigator.of(context).pop(notices[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  final PetNotice notice;
  final String name;
  final DateTime now;
  final bool isNew;
  final VoidCallback onTap;
  const _NoticeTile({
    required this.notice,
    required this.name,
    required this.now,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final n = notice;
    final (IconData icon, Color color, String title, String body) =
        switch (n.kind) {
      PetNoticeKind.hungry => (
          Icons.restaurant_rounded,
          palette.accent,
          l10n.noticeHungryTitle(name),
          l10n.noticeHungryBody,
        ),
      PetNoticeKind.lonely => (
          Icons.favorite_rounded,
          const Color(0xFFD9898C),
          l10n.noticeLonelyTitle(name),
          l10n.noticeLonelyBody,
        ),
      PetNoticeKind.unfed => (
          Icons.spa_rounded,
          palette.warning,
          l10n.noticeUnfedTitle,
          l10n.noticeUnfedBody(n.days ?? 0),
        ),
      PetNoticeKind.quiz => (
          Icons.event_note_rounded,
          const Color(0xFFE5675A),
          l10n.noticeQuizTitle,
          l10n.noticeQuizBody,
        ),
      PetNoticeKind.hatched => (
          Icons.egg_alt_rounded,
          palette.primary,
          l10n.noticeHatchedTitle(name),
          l10n.noticeHatchedBody,
        ),
      PetNoticeKind.evolved => (
          Icons.auto_awesome_rounded,
          palette.primary,
          l10n.noticeEvolvedTitle(
              name, n.stage == null ? '' : l10n.stageLabel(n.stage!)),
          l10n.noticeEvolvedBody,
        ),
      PetNoticeKind.streak => (
          Icons.local_florist_rounded,
          palette.success,
          l10n.noticeStreakTitle(n.days ?? 0),
          l10n.noticeStreakBody(name),
        ),
    };
    return Material(
      color: isNew ? palette.primary.withValues(alpha: 0.06) : palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.surfaceStroke),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppFonts.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _when(l10n),
                          style: AppFonts.body(
                              fontSize: 11.5, color: palette.textTertiary),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.danger,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: AppFonts.body(
                        fontSize: 13,
                        height: 1.35,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _when(AppLocalizations l10n) {
    if (notice.isCurrent) return l10n.inboxNow;
    final d = now.difference(notice.at);
    if (d.inMinutes < 1) return l10n.inboxNow;
    if (d.inMinutes < 60) return l10n.inboxMinutesAgo(d.inMinutes);
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(notice.at.year, notice.at.month, notice.at.day))
        .inDays;
    if (days == 0) return l10n.inboxHoursAgo(d.inHours);
    if (days == 1) return l10n.inboxYesterday;
    return l10n.inboxDaysAgo(days);
  }
}
