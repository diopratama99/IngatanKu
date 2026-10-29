import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme = TextTheme(
    displayLarge: AppFonts.display(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      color: AppColors.textPrimary,
    ),
    displayMedium: AppFonts.display(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: AppColors.textPrimary,
    ),
    headlineLarge: AppFonts.display(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    headlineMedium: AppFonts.display(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: AppFonts.body(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: AppFonts.body(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: AppFonts.body(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    bodyMedium: AppFonts.body(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.45,
    ),
    bodySmall: AppFonts.body(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiary,
    ),
    labelLarge: AppFonts.body(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.textPrimary,
    ),
  );

  /// Monospace style for code / hashes / debug
  static TextStyle mono({double size = 13, Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color ?? AppColors.textSecondary);
}
