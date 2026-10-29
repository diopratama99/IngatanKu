import 'package:flutter/material.dart';

/// The app's colours as constants — the same values as
/// `AppPalette.light` — for `const` spots and code without a
/// [BuildContext]. Prefer `context.palette`.
class AppColors {
  AppColors._();

  // Walnut (primary) + honey (secondary).
  static const Color primary = Color(0xFF5B4630); // walnut
  static const Color primaryDark = Color(0xFF47361F);
  static const Color accent = Color(0xFFD9A35B); // honey

  // Semantic.
  static const Color success = Color(0xFF6FA77A); // leaf
  static const Color warning = Color(0xFFE0A54A); // amber
  static const Color danger = Color(0xFFD9675F); // brick

  // Text.
  static const Color textPrimary = Color(0xFF26241F); // ink
  static const Color textSecondary = Color(0xFF6B675E); // stone
  static const Color textTertiary = Color(0xFF9A958A); // pebble
}
