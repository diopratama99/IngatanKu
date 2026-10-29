import 'package:flutter/material.dart';

/// A note's colour in Pustaka, like the books on the pet's shelves: the
/// [spine] on its card and the soft [chip] / [ink] for its tag. Picked from
/// the first tag (or the source when it has none), so every note in a
/// collection shares a colour.
class BookColor {
  final Color spine;
  final Color chip;
  final Color ink;
  const BookColor(this.spine, this.chip, this.ink);

  static const _shelf = [
    BookColor(
        Color(0xFFA9AEE6), Color(0xFFE3E5F8), Color(0xFF4F559E)), // lavender
    BookColor(
        Color(0xFFF0C565), Color(0xFFF8EBC4), Color(0xFF7D5A12)), // butter
    BookColor(Color(0xFF8FC4A0), Color(0xFFDCEDE1), Color(0xFF3A6B4A)), // sage
    BookColor(Color(0xFFEE9F98), Color(0xFFF8DEDB), Color(0xFF9C433C)), // rose
    BookColor(Color(0xFF8DB8E6), Color(0xFFDCE9F7), Color(0xFF365F8C)), // sky
    BookColor(Color(0xFFD9B88A), Color(0xFFF1E5D2), Color(0xFF75582F)), // sand
  ];

  /// The colour for [key] (a tag or a source), the same every time.
  static BookColor of(String key) {
    var hash = 0;
    for (final c in key.toLowerCase().codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return _shelf[hash % _shelf.length];
  }

  /// "All notes" gets the plain sand one.
  static BookColor all() => _shelf[5];
}
