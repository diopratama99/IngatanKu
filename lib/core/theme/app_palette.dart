import 'package:flutter/material.dart';

/// The app's colours, delivered through `Theme.of(context).extension` and
/// read as `context.palette.*` (see [AppPaletteContext]). [AppColors] has
/// the same values as constants, for `const` spots.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color surface;
  final Color surfaceFill;
  final Color surfaceStroke;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Brand: warm walnut brown, like the furniture in
  // the pet's rooms. [onPrimary] is the text on it; [primarySoft] and
  // [primaryMuted] are the cream tints of the nav bar's active tab.
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color primarySoft;
  final Color primaryMuted;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;

  const AppPalette({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.surface,
    required this.surfaceFill,
    required this.surfaceStroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.primarySoft,
    required this.primaryMuted,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
  });

  // Legacy aliases — keep API parity with AppColors.
  Color get glassFill => surfaceFill;
  Color get glassStroke => surfaceStroke;
  Color get neonCyan => accent;
  Color get neonPurple => primary;

  // ── Light — warm paper, walnut and cream ─────────────────────
  static const light = AppPalette(
    bgPrimary: Color(0xFFF7F5F1),
    bgSecondary: Color(0xFFFFFFFF),
    bgTertiary: Color(0xFFEFECE6),
    surface: Color(0xFFFFFFFF),
    surfaceFill: Color(0xFFFFFFFF),
    surfaceStroke: Color(0xFFECE8E1),
    textPrimary: Color(0xFF26241F),
    textSecondary: Color(0xFF6B675E),
    textTertiary: Color(0xFF9A958A),
    primary: Color(0xFF5B4630),
    primaryDark: Color(0xFF47361F),
    onPrimary: Color(0xFFFBF6EC),
    primarySoft: Color(0xFFF1E8D8),
    primaryMuted: Color(0xFFDCC7A4),
    accent: Color(0xFFD9A35B),
    success: Color(0xFF6FA77A),
    warning: Color(0xFFE0A54A),
    danger: Color(0xFFD9675F),
  );

  @override
  AppPalette copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? surface,
    Color? surfaceFill,
    Color? surfaceStroke,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? primaryDark,
    Color? onPrimary,
    Color? primarySoft,
    Color? primaryMuted,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppPalette(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      surface: surface ?? this.surface,
      surfaceFill: surfaceFill ?? this.surfaceFill,
      surfaceStroke: surfaceStroke ?? this.surfaceStroke,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgTertiary: Color.lerp(bgTertiary, other.bgTertiary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceFill: Color.lerp(surfaceFill, other.surfaceFill, t)!,
      surfaceStroke: Color.lerp(surfaceStroke, other.surfaceStroke, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Sugar so call sites can read `context.palette.textPrimary` instead
/// of `Theme.of(context).extension<AppPalette>()!.textPrimary`.
///
/// We deliberately use `palette` (not `colors`) because the existing
/// `context.colors` extension in `lib/core/utils/extensions.dart`
/// returns `ColorScheme`. Two extensions with the same name on the
/// same type would collide and the Dart resolver picks the wrong one.
extension AppPaletteContext on BuildContext {
  AppPalette get palette {
    final ext = Theme.of(this).extension<AppPalette>();
    // Defensive fallback for a widget rendered before the theme is wired
    // (rare, e.g. error screens): the colours rather than a crash.
    return ext ?? AppPalette.light;
  }
}
