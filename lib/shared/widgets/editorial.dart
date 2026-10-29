import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════
// Shared UI primitives — calm & tidy.
// Small tracked labels with hairline rules, white cards with very soft
// shadows, flat pill buttons that dip slightly when pressed. One accent.
// (The file keeps its historical name and API so every page picks up the
// look without call-site changes.)
// ════════════════════════════════════════════════════════════════════════

/// Small uppercase tracked label. Use as a quiet caption / eyebrow.
///
/// Pass [context] (recommended) so the color flips with the active
/// theme. An explicit [color] always wins.
TextStyle eyebrowStyle({BuildContext? context, Color? color}) {
  final resolved = color ??
      (context != null
          ? context.palette.textSecondary
          : AppColors.textSecondary);
  return AppFonts.body(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    color: resolved,
  );
}

/// Large number / hero text.
TextStyle displayNumberStyle({
  double size = 56,
  BuildContext? context,
  Color? color,
}) {
  final resolved = color ??
      (context != null ? context.palette.textPrimary : AppColors.textPrimary);
  return AppFonts.display(
    fontSize: size * 0.8,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.0,
    color: resolved,
  );
}

/// Page hero title.
TextStyle pageTitleStyle({
  double size = 36,
  FontWeight? weight,
  BuildContext? context,
  Color? color,
}) {
  final resolved = color ??
      (context != null ? context.palette.textPrimary : AppColors.textPrimary);
  return AppFonts.display(
    fontSize: size * 0.78,
    fontWeight: weight ?? FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.15,
    color: resolved,
  );
}

/// Soft card decoration used across the app.
BoxDecoration softCard(BuildContext context,
    {double radius = 20, Color? color}) {
  final palette = context.palette;
  return BoxDecoration(
    color: color ?? palette.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: palette.surfaceStroke),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.045),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/// 1px hairline rule used between rows.
class ThinDivider extends StatelessWidget {
  final double opacity;
  const ThinDivider({super.key, this.opacity = 0.7});
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: context.palette.surfaceStroke.withValues(alpha: opacity),
      );
}

/// Small tracked label + hairline rule + optional trailing link.
class SectionHeader extends StatelessWidget {
  final String label;
  final String? trailingLabel;
  final VoidCallback? onTrailing;
  const SectionHeader({
    super.key,
    required this.label,
    this.trailingLabel,
    this.onTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: eyebrowStyle(context: context)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: palette.surfaceStroke),
        ),
        if (trailingLabel != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTrailing,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailingLabel!,
                  style: AppFonts.body(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: palette.textSecondary),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Primary call-to-action: a flat accent pill.
class EditorialButton extends StatelessWidget {
  final String label;
  final IconData? icon;

  /// A picture before the label instead of [icon] (a brand's logo).
  final Widget? leading;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final bool primary;
  const EditorialButton({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.onPressed,
    this.loading = false,
    this.fullWidth = false,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disabled = onPressed == null || loading;
    final bg = primary
        ? (disabled ? palette.bgTertiary : palette.primary)
        : palette.surface;
    final fg = primary
        ? (disabled ? palette.textTertiary : palette.onPrimary)
        : palette.textPrimary;
    return SoftButton(
      onTap: disabled ? null : onPressed,
      color: bg,
      bordered: !primary,
      shadow: false,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            else if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 10),
            ],
            if (loading) const SizedBox(width: 10),
            Text(
              loading ? 'Memuat…' : label,
              style: AppFonts.body(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded surface that dips slightly when pressed. The quiet base for
/// buttons and tappable cards throughout the app.
class SoftButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final bool bordered;
  final bool shadow;
  final double radius;
  final BoxShape shape;
  const SoftButton({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.color,
    this.bordered = true,
    this.shadow = true,
    this.radius = 20,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<SoftButton> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<SoftButton> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final round = widget.shape == BoxShape.circle;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            color: widget.color ?? palette.surface,
            shape: widget.shape,
            borderRadius: round ? null : BorderRadius.circular(widget.radius),
            border: widget.bordered
                ? Border.all(color: palette.surfaceStroke)
                : null,
            boxShadow: widget.shadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Centered, widely-tracked uppercase page title ("PUSTAKA •") — the
/// quiet header every tab shares.
class SpacedTitle extends StatelessWidget {
  final String text;

  /// Optional status dot after the title.
  final Color? dot;
  const SpacedTitle(this.text, {super.key, this.dot});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text.toUpperCase(),
            style: AppFonts.body(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 4.5,
              color: palette.textPrimary,
            ),
          ),
          if (dot != null) ...[
            const SizedBox(width: 6),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
          ],
        ],
      ),
    );
  }
}

/// A round button with an icon — the back button and other single
/// actions in a page's top bar.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SoftButton(
        onTap: onTap,
        shape: BoxShape.circle,
        child: SizedBox(
          width: 44,
          height: 44,
          child:
              Icon(icon, size: 21, color: color ?? context.palette.textPrimary),
        ),
      ),
    );
  }
}

/// The top bar every pushed page shares: a round back button, the page's
/// name spaced out in the middle (like the tabs' titles) and optional
/// [trailing] actions. Use it as a `Scaffold.appBar`.
class PageTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  const PageTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final canPop = onBack != null || Navigator.of(context).canPop();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SpacedTitle(title),
                ),
              ),
              Row(
                children: [
                  if (canPop)
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
