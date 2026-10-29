import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';

/// The pegboard your notes hang on in Catatan: a warm board with rows of
/// peg holes in a wooden frame, and a vine (`assets/notes/vine.png`)
/// trailing down over its corner, swaying a little.
class NotesBoard extends StatefulWidget {
  final Widget child;
  const NotesBoard({super.key, required this.child});

  @override
  State<NotesBoard> createState() => _NotesBoardState();
}

class _NotesBoardState extends State<NotesBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _BoardColors.frame,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _BoardColors.frameEdge, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: const _BoardPainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
                child: widget.child,
              ),
            ),
          ),
        ),
        // Draped over the top corner, swinging gently from where it hooks
        // over the frame.
        Positioned(
          top: -16,
          right: -16,
          width: 52,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _sway,
              builder: (_, child) => Transform.rotate(
                alignment: Alignment.topCenter,
                angle: math.sin(_sway.value * 2 * math.pi) * 0.03,
                child: child,
              ),
              child: Image.asset(
                'assets/notes/vine.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardColors {
  static const frame = Color(0xFFD7BA8C);
  static const frameEdge = Color(0xFFE6CFA6);
  static const board = Color(0xFFE8D4B4);
  static const holes = Color(0xFFCDB28A);
  static const label = Color(0xFFFFFBF2);
  static const labelInk = Color(0xFF7A6548);
}

/// The board: rows of peg holes, and the frame's shadow along the top.
class _BoardPainter extends CustomPainter {
  const _BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _BoardColors.board);
    const gap = 18.0;
    final hole = Paint()..color = _BoardColors.holes;
    final cols = (size.width / gap).floor();
    final x0 = (size.width - (cols - 1) * gap) / 2;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var i = 0; i < cols; i++) {
        canvas.drawCircle(Offset(x0 + i * gap, y), 1.8, hole);
      }
    }
    final top = Rect.fromLTWH(0, 0, size.width, 12);
    canvas.drawRect(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0),
          ],
        ).createShader(top),
    );
  }

  @override
  bool shouldRepaint(_BoardPainter old) => false;
}

/// A little paper label pinned to the board over a group of notes
/// ("TERSEMAT", "LAINNYA").
class BoardLabel extends StatelessWidget {
  final String text;
  const BoardLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.rotate(
        angle: -0.025,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          decoration: BoxDecoration(
            color: _BoardColors.label,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Text(
            text,
            style: AppFonts.body(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: _BoardColors.labelInk,
            ),
          ),
        ),
      ),
    );
  }
}
