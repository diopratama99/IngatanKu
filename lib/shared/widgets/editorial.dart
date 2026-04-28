import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

// ════════════════════════════════════════════════════════════════════════
// Shared editorial / Notion-esque primitives.
// Used across all pages so the visual language stays consistent: small
// uppercase tracked eyebrows, big serif-grotesk numbers, hairline rules,
// minimal card chrome, single accent (AppColors.primary).
// ════════════════════════════════════════════════════════════════════════

/// Small uppercase tracked label. Use as a quiet caption / eyebrow.
TextStyle eyebrowStyle({Color? color}) => GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: color ?? AppColors.textTertiary,
    );

/// Display-style number / hero text using Space Grotesk.
TextStyle displayNumberStyle({double size = 56, Color? color}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -2,
      height: 0.95,
      color: color ?? AppColors.textPrimary,
    );

/// Large editorial heading (page hero title).
TextStyle pageTitleStyle({double size = 36, FontWeight? weight, Color? color}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w700,
      letterSpacing: -1.2,
      height: 1.1,
      color: color ?? AppColors.textPrimary,
    );

/// 1px hairline rule used between rows.
class ThinDivider extends StatelessWidget {
  final double opacity;
  const ThinDivider({super.key, this.opacity = 0.4});
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: AppColors.surfaceStroke.withOpacity(opacity),
      );
}

/// Section eyebrow + hairline rule + optional trailing action label.
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
    final eyebrow = eyebrowStyle();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: eyebrow),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.surfaceStroke.withOpacity(0.5),
          ),
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
                  style: eyebrow.copyWith(color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 12, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Hero number with caption — used for Level / Streak / counters.
class BigStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? accent;
  final double size;
  const BigStat({
    super.key,
    required this.value,
    required this.label,
    this.accent,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: displayNumberStyle(
            size: size,
            color: accent ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Editorial stat list-row: large number on the left, label on the right,
/// optional chevron when tappable.
class StatRow extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;
  const StatRow({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Full-width action row: optional primary fill, otherwise outline only.
class ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: primary ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: primary
                ? null
                : Border.all(color: AppColors.surfaceStroke, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: fg.withOpacity(0.75)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plain editorial list row: title + meta + outward arrow. Use for note
/// rows, search results, etc.
class EditorialRow extends StatelessWidget {
  final String title;
  final String? meta;
  final VoidCallback onTap;
  final IconData trailingIcon;
  final int titleMaxLines;
  const EditorialRow({
    super.key,
    required this.title,
    required this.onTap,
    this.meta,
    this.trailingIcon = Icons.arrow_outward_rounded,
    this.titleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (meta != null && meta!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(trailingIcon,
                  size: 16, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editorial filled button — replacement for NeonButton with the same
/// API surface used by auth pages and add-note bottom bar.
class EditorialButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final bool primary;
  const EditorialButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.fullWidth = false,
    this.primary = true,
  });

  @override
  State<EditorialButton> createState() => _EditorialButtonState();
}

class _EditorialButtonState extends State<EditorialButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    final bg = widget.primary
        ? (disabled
            ? AppColors.bgTertiary
            : (_pressed ? AppColors.primaryDark : AppColors.primary))
        : Colors.transparent;
    final fg = widget.primary ? Colors.white : AppColors.textPrimary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: widget.primary
              ? null
              : Border.all(color: AppColors.surfaceStroke, width: 1),
        ),
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            else if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: fg),
              const SizedBox(width: 10),
            ],
            Text(
              widget.loading ? 'Memuat…' : widget.label,
              style: GoogleFonts.inter(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
