import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../domain/entities/personal_note.dart';
import 'note_color_palette.dart';

/// A sheet of the pet's notepaper in the note's colour, held on by a
/// strip of washi tape at the top.
class NotePaper extends StatelessWidget {
  final NoteColor color;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Tape across the top edge (off for small cards that don't need it).
  final bool tape;
  const NotePaper({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 26, 20, 20),
    this.radius = 22,
    this.tape = true,
  });

  @override
  Widget build(BuildContext context) {
    final paper = NoteColorPalette.background(color);
    final edge = NoteColorPalette.border(color);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: padding,
          decoration: BoxDecoration(
            color: paper,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: edge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
        if (tape)
          Positioned(
            top: -9,
            left: 0,
            right: 0,
            child: Center(
              child: WashiTape(color: tapeFor(color, context)),
            ),
          ),
      ],
    );
  }

  /// Tape that stands out a little on [color]'s paper: the swatch itself,
  /// or lavender on plain paper.
  static Color tapeFor(NoteColor color, BuildContext context) =>
      color == NoteColor.defaultColor
          ? NoteColorPalette.swatch(NoteColor.purple)
          : NoteColorPalette.swatch(color);
}

/// A short strip of washi tape: see-through, faintly striped, with torn
/// ends, at a slight tilt.
class WashiTape extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final double angle;
  const WashiTape({
    super.key,
    required this.color,
    this.width = 64,
    this.height = 18,
    this.angle = -0.06,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: angle,
        child: CustomPaint(
          size: Size(width, height),
          painter: _TapePainter(color),
        ),
      ),
    );
  }
}

/// A plain sheet of the pet's notepaper as a box decoration: cream paper
/// with a soft edge and shadow (cards that sit with the notes' look).
BoxDecoration notePaperDecoration(BuildContext context, {double radius = 18}) {
  return BoxDecoration(
    color: NoteColorPalette.background(NoteColor.defaultColor),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: NoteColorPalette.border(NoteColor.defaultColor)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/// A word written on a strip of washi tape — a label stuck over the top
/// edge of a sheet (the groups on the profile page).
class TapeLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double angle;
  const TapeLabel({
    super.key,
    required this.text,
    required this.color,
    this.angle = -0.03,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        painter: _TapePainter(color),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
          child: Text(
            text.toUpperCase(),
            style: AppFonts.body(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              height: 1.2,
              color: const Color(0xFF3F3424),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapePainter extends CustomPainter {
  final Color color;
  _TapePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Torn ends: a little zigzag on each side.
    const teeth = 4;
    final path = Path()..moveTo(0, 0);
    path.lineTo(w, 0);
    for (var i = 0; i < teeth; i++) {
      final y0 = h * i / teeth;
      path
        ..lineTo(w - 2.5, y0 + h / teeth / 2)
        ..lineTo(w, y0 + h / teeth);
    }
    path.lineTo(0, h);
    for (var i = teeth; i > 0; i--) {
      final y0 = h * i / teeth;
      path
        ..lineTo(2.5, y0 - h / teeth / 2)
        ..lineTo(0, y0 - h / teeth);
    }
    path.close();
    canvas.drawPath(
      path.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.78));
    // Faint diagonal stripes.
    canvas.save();
    canvas.clipPath(path);
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 3;
    for (var x = -h; x < w + h; x += 9) {
      canvas.drawLine(Offset(x, h), Offset(x + h, 0), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TapePainter old) => old.color != color;
}

/// The rules of lined notepaper behind a block of text: one every
/// [lineHeight], [baseline] down into each line.
class RuledLines extends CustomPainter {
  final double lineHeight;
  final double baseline;
  final Color color;
  RuledLines({
    required this.lineHeight,
    required this.baseline,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = baseline; y <= size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(RuledLines old) =>
      old.lineHeight != lineHeight ||
      old.baseline != baseline ||
      old.color != color;
}
