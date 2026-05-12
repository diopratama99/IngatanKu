import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Static flat dark background. Name kept for backwards compatibility.
class AnimatedGradientBackground extends StatelessWidget {
  final Widget child;
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: child,
    );
  }
}
