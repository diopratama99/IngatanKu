part of 'dashboard_page.dart';

/// One quiet line under the room: three small rings for how full, happy
/// and grown the pet is plus its stage on the left, its name (with an ⓘ —
/// tap for its profile) in the middle, wardrobe and rest on the right.
class _StatusStrip extends StatelessWidget {
  final String name;
  final String stage;
  final bool hatched;
  final double fullness;
  final double happiness;
  final double growth;
  final bool resting;
  final VoidCallback onProfile;
  final VoidCallback onWardrobe;
  final VoidCallback onToggleRest;
  const _StatusStrip({
    super.key,
    required this.name,
    required this.stage,
    required this.hatched,
    required this.fullness,
    required this.happiness,
    required this.growth,
    required this.resting,
    required this.onProfile,
    required this.onWardrobe,
    required this.onToggleRest,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    // Left: how it's doing and its stage. Middle: its name, with an ⓘ for
    // its profile. Right: wardrobe and rest. The two sides share the
    // space evenly so the name sits in the middle.
    final vitals = GestureDetector(
      onTap: onProfile,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hatched) ...[
            _Ring(
              icon: Icons.restaurant_rounded,
              value: fullness,
              color: palette.accent,
              label: l10n.petMeterFullness,
            ),
            const SizedBox(width: 5),
            _Ring(
              icon: Icons.favorite_rounded,
              value: happiness,
              color: const Color(0xFFD9898C),
              label: l10n.petMeterHappiness,
            ),
            const SizedBox(width: 5),
            _Ring(
              icon: Icons.spa_rounded,
              value: growth,
              color: palette.success,
              label: l10n.petMeterGrowth,
              warn: false,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            stage,
            maxLines: 1,
            style: AppFonts.body(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: palette.textTertiary,
            ),
          ),
        ],
      ),
    );
    final title = Semantics(
      button: true,
      label: l10n.homePetInfo(name),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onProfile,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A long name shrinks a little rather than getting cut off.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: AppFonts.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.info_outline_rounded,
                  size: 16, color: palette.textTertiary),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10),
      child: LayoutBuilder(builder: (context, c) {
        return Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(fit: BoxFit.scaleDown, child: vitals),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: c.maxWidth * 0.44),
              child: title,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SmallIcon(
                      icon: Icons.checkroom_rounded,
                      tooltip: l10n.homeActionWardrobe,
                      onTap: onWardrobe,
                    ),
                    _SmallIcon(
                      icon: resting
                          ? Icons.bedtime_rounded
                          : Icons.bedtime_outlined,
                      tooltip: resting ? l10n.homeWake : l10n.homeRest,
                      onTap: onToggleRest,
                      active: resting,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// A small ring that fills up as [value] (0..1) grows, its icon inside.
/// Turns red when it's running low (unless [warn] is off).
class _Ring extends StatelessWidget {
  final IconData icon;
  final double value;
  final Color color;
  final String label;
  final bool warn;
  const _Ring({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
    this.warn = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final v = value.clamp(0.0, 1.0);
    final c = warn && v < 0.25 ? palette.danger : color;
    return Semantics(
      label: '$label ${(v * 100).round()}%',
      excludeSemantics: true,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(
          painter:
              _RingPainter(value: v, color: c, track: palette.surfaceStroke),
          child: Center(child: Icon(icon, size: 11, color: c)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  _RingPainter({required this.value, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.4;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track);
    if (value <= 0) return;
    canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// For the first visit's coachmark: Share in another app, then
/// IngatanKu in the list.
class _ShareHowTo extends StatelessWidget {
  const _ShareHowTo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    Widget tile(Widget icon, String label) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.bgPrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.surfaceStroke),
              ),
              child: icon,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppFonts.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
          ],
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile(Icon(Icons.share_rounded, size: 24, color: palette.textPrimary),
            l10n.coachShareTap),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
          child: Icon(Icons.arrow_forward_rounded,
              size: 20, color: palette.textTertiary),
        ),
        tile(const PetHost(height: 34, idle: false), AppConstants.appName),
      ],
    );
  }
}

/// The boutique, where the premium accessories and outfits hang.
class _ShopButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShopButton({required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: AppLocalizations.of(context)!.shopTooltip,
        onPressed: onTap,
        icon: Icon(Icons.storefront_outlined,
            size: 24, color: context.palette.textPrimary),
      );
}

/// The weekly feast (the weekly quiz) by the bell, with a red dot while
/// this week's hasn't been had.
class _FeastButton extends StatelessWidget {
  final bool pending;
  final VoidCallback onTap;
  const _FeastButton({required this.pending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return IconButton(
      tooltip: '${l10n.homeFeastReady} · ${l10n.homeFeastReadySub}',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.celebration_outlined,
              size: 24, color: palette.textPrimary),
          if (pending)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.danger,
                  border: Border.all(color: palette.bgPrimary, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The pet's inbox bell, with a red dot while there's something new.
class _Bell extends StatelessWidget {
  final bool unread;
  final VoidCallback onTap;
  const _Bell({required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return IconButton(
      tooltip: unread ? l10n.homeInboxUnread : l10n.homeInbox,
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 24, color: palette.textPrimary),
          if (unread)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.danger,
                  border: Border.all(color: palette.bgPrimary, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  const _SmallIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon,
          size: 20, color: active ? palette.primary : palette.textSecondary),
    );
  }
}

class _FanControls extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onClose;
  final VoidCallback onLibrary;
  const _FanControls({
    super.key,
    required this.page,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onClose,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final from = page * 3 + 1;
    final to = math.min(page * 3 + 3, total);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeTodayTitle,
                      style: AppFonts.body(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.homeTodayRange(from, to, total),
                      style: AppFonts.body(
                          fontSize: 12, color: palette.textTertiary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
                icon: Icon(Icons.close_rounded,
                    size: 20, color: palette.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded),
                color: palette.textSecondary,
              ),
              Expanded(
                child: Center(
                  child: TextButton.icon(
                    onPressed: onLibrary,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.north_east_rounded, size: 15),
                    label: Text(l10n.homeTodayOpenLibrary),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      textStyle: AppFonts.body(
                          fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
                color: palette.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
