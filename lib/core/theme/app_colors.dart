import 'package:flutter/material.dart';

/// Calm, flat dark palette. No glows, no neon.
/// Indigo + slate base with a single teal accent for primary actions.
class AppColors {
  AppColors._();

  // Backgrounds (flat slate tones, no gradient drift)
  static const Color bgPrimary = Color(0xFF0F172A);   // slate-900
  static const Color bgSecondary = Color(0xFF1E293B); // slate-800
  static const Color bgTertiary = Color(0xFF334155);  // slate-700
  static const Color surface = Color(0xFF1E293B);     // card surface

  // Surface overlays (replaces the old "glass" effect with solid translucents)
  static Color surfaceFill = const Color(0xFF1E293B);
  static Color surfaceStroke = const Color(0xFF334155);

  // Legacy aliases (kept so existing widgets still compile during migration)
  static Color glassFill = const Color(0xFF1E293B);
  static Color glassStroke = const Color(0xFF334155);

  // Single accent — Indigo (primary) + Teal (secondary)
  static const Color primary = Color(0xFF6366F1);     // indigo-500
  static const Color primaryDark = Color(0xFF4F46E5); // indigo-600
  static const Color accent = Color(0xFF14B8A6);      // teal-500

  // Legacy "neon*" aliases mapped to flat colors so older widgets keep building
  static const Color neonCyan = accent;
  static const Color neonPurple = primary;
  static const Color neonPink = Color(0xFFEC4899);    // pink-500
  static const Color neonYellow = Color(0xFFEAB308);  // yellow-500
  static const Color neonBlue = Color(0xFF3B82F6);    // blue-500

  // Semantic
  static const Color success = Color(0xFF22C55E); // green-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color danger = Color(0xFFEF4444);  // red-500

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);   // slate-100
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textTertiary = Color(0xFF64748B);  // slate-500

  // Gradients (kept flat — used as solid-ish accents only)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgPrimary, bgSecondary],
  );

  /// No-op — kept for backwards compatibility with widgets that still call it.
  /// Returns an empty shadow list so nothing glows.
  static List<BoxShadow> neonGlow(Color c, {double radius = 24}) => const [];
}
