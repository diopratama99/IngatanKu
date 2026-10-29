import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's type, in one place so the whole app can change voice by
/// editing this file.
///
/// Both roles use Plus Jakarta Sans — a clean, quiet geometric sans made
/// in Indonesia — so pages read calm and tidy:
/// * [display] — headings and numbers (slightly tighter tracking).
/// * [body] — everything else.
///
/// They take the same named arguments the old Space Grotesk / Inter call
/// sites used. Very heavy weights are toned down; the font tops out at
/// 800 and the calm look wants headings around 600–700.
class AppFonts {
  AppFonts._();

  static TextStyle display({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
  }) =>
      _font(
        color: color,
        fontSize: fontSize,
        fontWeight: _cap(fontWeight ?? FontWeight.w600),
        height: height,
        letterSpacing: letterSpacing == null || letterSpacing >= 0
            ? letterSpacing
            : letterSpacing * 0.5,
        fontStyle: fontStyle,
        shadows: shadows,
        decoration: decoration,
        decorationColor: decorationColor,
      );

  static TextStyle body({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
  }) =>
      _font(
        color: color,
        fontSize: fontSize,
        fontWeight: _cap(fontWeight ?? FontWeight.w400),
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        shadows: shadows,
        decoration: decoration,
        decorationColor: decorationColor,
      );

  static FontWeight _cap(FontWeight w) => w.value > 700 ? FontWeight.w700 : w;

  /// Widget tests can't download fonts, so there the style just names the
  /// family google_fonts would register (`PlusJakartaSans_700`…): a test
  /// can load those files itself, or make do with the test font.
  static final bool _inTest =
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  static TextStyle _font({
    Color? color,
    double? fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    if (!_inTest) {
      return GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        shadows: shadows,
        decoration: decoration,
        decorationColor: decorationColor,
      );
    }
    final weight = fontWeight.value == 400 ? 'regular' : '${fontWeight.value}';
    final italic = fontStyle == FontStyle.italic ? 'italic' : '';
    return TextStyle(
      fontFamily: 'PlusJakartaSans_$weight$italic',
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      shadows: shadows,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }
}
