import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_fonts.dart';
import 'app_palette.dart';
import 'app_typography.dart';

/// The app's theme, in the cosy style of the pet's rooms: warm paper
/// surfaces, walnut-and-cream controls, pill-shaped buttons, hairline
/// borders and very soft shadows. It registers the [AppPalette] that
/// widgets read through `context.palette.*`.
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(AppPalette.light);

  static const double radius = 20;

  static ThemeData _build(AppPalette palette) {
    final text = AppTypography.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );
    final fieldFill = palette.surface;
    final pill =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final buttonText = AppFonts.body(fontSize: 15, fontWeight: FontWeight.w600);
    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: palette.bgPrimary,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        secondary: palette.accent,
        tertiary: const Color(0xFFC98B8B),
        surface: palette.surface,
        error: palette.danger,
        onPrimary: palette.onPrimary,
        onSurface: palette.textPrimary,
      ),
      extensions: [palette],
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Pushed pages with an AppBar need their own overlay style —
        // Material derives it from the transparent background and gets
        // it wrong otherwise.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: AppFonts.display(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary),
        foregroundColor: palette.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: palette.surfaceStroke),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: AppFonts.body(fontSize: 14, color: palette.textTertiary),
        border: field(palette.surfaceStroke),
        enabledBorder: field(palette.surfaceStroke),
        focusedBorder: field(palette.primary, 1.5),
        errorBorder: field(palette.danger),
        focusedErrorBorder: field(palette.danger, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.surfaceStroke),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
        extendedTextStyle:
            AppFonts.body(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.bgTertiary,
        side: BorderSide.none,
        labelStyle: AppFonts.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary),
        shape: const StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.bgSecondary,
        modalBackgroundColor: palette.bgSecondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppFonts.display(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.textPrimary,
        contentTextStyle: AppFonts.body(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.bgTertiary,
      ),
      // On: walnut with a cream knob. Off: a soft cream track with a
      // quiet knob, no hard black outline.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? palette.onPrimary
                : palette.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? palette.primary
                : palette.primarySoft),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? Colors.transparent
                : palette.surfaceStroke),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: palette.textSecondary,
      ),
      dividerColor: palette.surfaceStroke,
      splashColor: palette.primary.withValues(alpha: 0.06),
      highlightColor: palette.primary.withValues(alpha: 0.05),
    );
  }
}
