import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../notes/domain/entities/personal_note.dart';
import '../../../notes/presentation/widgets/note_color_palette.dart';
import '../../../notes/presentation/widgets/note_paper.dart';

/// A group of settings on a sheet of the pet's notepaper, its name on a
/// strip of washi tape stuck over the top edge — like the notes in
/// Catatan.
class SettingsPaper extends StatelessWidget {
  final String label;
  final NoteColor tape;
  final Widget child;
  const SettingsPaper({
    super.key,
    required this.label,
    required this.tape,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 10),
          decoration: notePaperDecoration(context),
          child: child,
        ),
        Positioned(
          top: -11,
          left: 16,
          child: TapeLabel(
            text: label,
            color: NoteColorPalette.swatch(tape),
          ),
        ),
      ],
    );
  }
}

/// A pastel sticker with an icon drawn on it, in one of the notes'
/// colours.
class SettingsSticker extends StatelessWidget {
  final IconData icon;
  final NoteColor color;
  const SettingsSticker({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final swatch = NoteColorPalette.swatch(color);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: NoteColorPalette.background(color),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NoteColorPalette.border(color)),
      ),
      child: Icon(
        icon,
        size: 19,
        color: Color.lerp(swatch, Colors.black, 0.45),
      ),
    );
  }
}

/// A dashed line between rows, like a perforation in the paper.
class SettingsPerforation extends StatelessWidget {
  const SettingsPerforation({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashPainter(NoteColorPalette.border(NoteColor.defaultColor)),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(
          Offset(x, 0.5), Offset(math.min(x + 4, size.width), 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
