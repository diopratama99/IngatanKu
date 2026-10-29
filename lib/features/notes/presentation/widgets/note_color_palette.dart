import 'package:flutter/material.dart';

import '../../domain/entities/personal_note.dart';

/// Maps the abstract [NoteColor] tokens to concrete `Color`s — soft
/// pastel paper, like the sticky notes on the pet's pinboard, so text
/// stays easy to read on every colour.
class NoteColorPalette {
  NoteColorPalette._();

  /// (paper, edge, swatch) for each colour.
  static (Color, Color, Color) _tones(NoteColor c) {
    return switch (c) {
      NoteColor.defaultColor => (
          const Color(0xFFFFFDF8),
          const Color(0xFFECE5D8),
          const Color(0xFFF6F1E7)
        ),
      NoteColor.red => (
          const Color(0xFFFBE3E0),
          const Color(0xFFF0C9C4),
          const Color(0xFFEE9F98)
        ),
      NoteColor.orange => (
          const Color(0xFFFCE7D3),
          const Color(0xFFF1CDA9),
          const Color(0xFFF2B07A)
        ),
      NoteColor.yellow => (
          const Color(0xFFFBF1CB),
          const Color(0xFFEEDDA0),
          const Color(0xFFF0C565)
        ),
      NoteColor.green => (
          const Color(0xFFE3F0DF),
          const Color(0xFFC6DDBF),
          const Color(0xFF8FC4A0)
        ),
      NoteColor.teal => (
          const Color(0xFFDBF0EB),
          const Color(0xFFB8DDD4),
          const Color(0xFF7CC6B8)
        ),
      NoteColor.blue => (
          const Color(0xFFDFEBF7),
          const Color(0xFFC0D5EC),
          const Color(0xFF8DB8E6)
        ),
      NoteColor.purple => (
          const Color(0xFFE9E6F8),
          const Color(0xFFD0CBEF),
          const Color(0xFFA9AEE6)
        ),
      NoteColor.pink => (
          const Color(0xFFF9E2EC),
          const Color(0xFFEFC4D7),
          const Color(0xFFE99BBE)
        ),
      NoteColor.brown => (
          const Color(0xFFF0E5D5),
          const Color(0xFFDCCBB0),
          const Color(0xFFC9A57A)
        ),
      NoteColor.gray => (
          const Color(0xFFEDEBE6),
          const Color(0xFFD9D5CD),
          const Color(0xFFB5B0A5)
        ),
    };
  }

  /// The note's paper.
  static Color background(NoteColor c) => _tones(c).$1;

  /// The paper's edge — a little deeper than [background].
  static Color border(NoteColor c) => _tones(c).$2;

  /// The colour's swatch in the picker, and the tape on its card.
  static Color swatch(NoteColor c) => _tones(c).$3;
}
