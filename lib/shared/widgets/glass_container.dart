import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Flat surface card. Name kept for backwards compatibility — no longer uses
/// a backdrop blur or any glow.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur; // ignored, kept for API compatibility
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? shadows; // ignored
  final double? width;
  final double? height;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 0,
    this.radius = 16,
    this.padding,
    this.margin,
    this.tint,
    this.border,
    this.shadows,
    this.width,
    this.height,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (tint ?? AppColors.surfaceFill) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: AppColors.surfaceStroke, width: 1),
      ),
      child: child,
    );

    final wrapped = Container(margin: margin, child: content);

    if (onTap == null) return wrapped;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: wrapped,
      ),
    );
  }
}
