import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/services/app_pause.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/pet_inbox.dart';
import '../../data/pet_store.dart';
import '../../domain/companion_style.dart';
import '../pet_labels.dart';
import 'blob_mascot.dart';
import 'notebook_painter.dart';
import 'pet_speech_bubble.dart';

part 'pet_writing_desk.dart';
part 'pet_reading_nook.dart';
part 'pet_chat_corner.dart';
part 'pet_fitting_room.dart';

// ════════════════════════════════════════════════════════════════════════
// The pet at work around the app. Each page gets a small illustrated
// header where the same pet from Beranda is busy with that page's job:
//
//   Catatan  → [PetWritingDesk]  scribbling in a notebook at its desk
//   Pustaka  → [PetReadingNook]  reading on a bean bag in its library
//   Asisten  → [PetChatCorner]   chatting with you over tea
//   Butik    → [PetFittingRoom]  trying on what you pick
//
// They share Beranda's quiet look (soft fills, hairline strokes) and the
// same speech bubble.
// ════════════════════════════════════════════════════════════════════════

/// Palette for the small rooms.
class _Props {
  final Color line;
  final Color wood;
  final Color woodDark;
  final Color paper;
  final Color cushion;
  final Color cushionDark;
  final Color glow;
  final Color leaf;
  final List<Color> books;

  const _Props({
    required this.line,
    required this.wood,
    required this.woodDark,
    required this.paper,
    required this.cushion,
    required this.cushionDark,
    required this.glow,
    required this.leaf,
    required this.books,
  });

  static const room = _Props(
    line: Color(0xFFDCD5C9),
    wood: Color(0xFFEDE4D6),
    woodDark: Color(0xFFDCCFBC),
    paper: Color(0xFFFFFDF8),
    cushion: Color(0xFFE3E4F3),
    cushionDark: Color(0xFFD3D5EC),
    glow: Color(0xFFFFE6B0),
    leaf: Color(0xFF9DBB8A),
    books: [
      Color(0xFFD9DCEF),
      Color(0xFFE7D9C4),
      Color(0xFFD5E0CF),
      Color(0xFFEAD3CF),
      Color(0xFFD8D3C8),
      Color(0xFFCFD9E3),
    ],
  );

  Paint fill(Color c) => Paint()..color = c;
  Paint get stroke => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeJoin = StrokeJoin.round
    ..color = line;

  void rrect(Canvas canvas, Rect r, double radius, Color c) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    canvas.drawRRect(rr, fill(c));
    canvas.drawRRect(rr, stroke);
  }
}

/// Shared behaviour: cycles through [lines] the pet says, shows a short
/// reaction when it's petted, owns the pet's controller — and, like on
/// Beranda, every so often has the pet do something on its own that fits
/// the room ([idleOnce]).
mixin _Chatter<T extends StatefulWidget> on State<T> {
  final pet = BlobController();
  int _line = 0;
  String? _reaction;
  Timer? _cycle;
  Timer? _reactionTimer;
  Timer? _idleTimer;
  final _rng = math.Random();

  List<String> get lines;

  /// One of the pet's idle moments in this room. It's free when this runs
  /// (hatched, not reacting to anything, page on screen); [pause] between
  /// steps and stop as soon as it returns false.
  Future<void> idleOnce(math.Random rng);

  /// Whether the scene has the pet busy with something right now.
  bool get canIdle => true;

  /// A hungry or lonely pet only does the quiet things.
  bool get petLow {
    final mood = sl<PetStore>().state.moodAt(DateTime.now());
    return mood == CompanionMood.hungry || mood == CompanionMood.lonely;
  }

  void startChatter() {
    _cycle = AppTimer.periodic(const Duration(seconds: 7), (_) {
      if (mounted && lines.length > 1) setState(() => _line++);
    });
    _scheduleIdle(first: true);
    pet.crying.addListener(_cryingChanged);
  }

  /// Smacked to tears, or comforted again. The room can stop what it's
  /// animating meanwhile ([onCrying]).
  void _cryingChanged() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final crying = pet.crying.value;
    say(crying ? l10n.petStatusCry : l10n.petStatusComforted,
        ms: crying ? 8000 : 3200);
    onCrying(crying);
  }

  /// The pet started (or stopped) crying.
  void onCrying(bool crying) {}

  /// What it says when smacked: crosser after a few, in tears after more.
  void onBonked(int run) {
    final l10n = AppLocalizations.of(context)!;
    say(pet.crying.value
        ? l10n.petStatusCry
        : run >= 3
            ? l10n.petStatusBonkAngry
            : l10n.petStatusBonk);
  }

  void _scheduleIdle({bool first = false}) {
    _idleTimer?.cancel();
    _idleTimer = AppTimer(
      Duration(seconds: (first ? 5 : 9) + _rng.nextInt(first ? 5 : 9)),
      _runIdle,
    );
  }

  Future<void> _runIdle() async {
    if (!mounted) return;
    final free = TickerMode.of(context) &&
        sl<PetStore>().state.hatched &&
        _reaction == null &&
        !pet.crying.value &&
        canIdle;
    if (free) await idleOnce(_rng);
    if (mounted) _scheduleIdle();
  }

  /// Waits [ms]; false once the scene is gone.
  Future<bool> pause(int ms) async {
    await AppPause.delay(Duration(milliseconds: ms));
    return mounted;
  }

  void onPetted(String reaction) {
    sl<PetStore>().pet();
    // Crying, a stroke soothes it a little instead.
    say(pet.crying.value
        ? AppLocalizations.of(context)!.petStatusCrySoothe
        : reaction);
  }

  /// Says [reaction] for a moment ([ms]), over the usual lines.
  void say(String reaction, {int ms = 2600}) {
    _reactionTimer?.cancel();
    setState(() => _reaction = reaction);
    _reactionTimer = AppTimer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _reaction = null);
    });
  }

  String? get currentLine =>
      _reaction ?? (lines.isEmpty ? null : lines[_line % lines.length]);

  void stopChatter() {
    pet.crying.removeListener(_cryingChanged);
    _cycle?.cancel();
    _reactionTimer?.cancel();
    _idleTimer?.cancel();
  }
}

/// The pet as an actor, dressed from [PetStore] — or in an [accessory] or
/// [outfit] it's trying on.
class _Actor extends StatelessWidget {
  final double size;
  final BlobController controller;
  final VoidCallback onPet;
  final ValueChanged<int>? onBonk;
  final bool glasses;
  final bool showArms;
  final BlobExpression? expression;
  final bool touchy;
  final BlobAccessory? accessory;
  final BlobOutfit? outfit;
  const _Actor({
    required this.size,
    required this.controller,
    required this.onPet,
    this.onBonk,
    this.glasses = false,
    this.showArms = true,
    this.expression,
    this.touchy = false,
    this.accessory,
    this.outfit,
  });

  @override
  Widget build(BuildContext context) {
    final store = sl<PetStore>();
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: store,
      builder: (_, __) {
        final mood = store.state.moodAt(DateTime.now());
        return BlobMascot(
          size: size,
          color: store.color,
          accessory: accessory ?? store.accessory,
          outfit: outfit ?? store.outfit,
          stage: store.state.stage,
          // Busy pets don't nap mid-task.
          mood: mood == CompanionMood.sleepy ? CompanionMood.content : mood,
          controller: controller,
          onPet: onPet,
          onBonk: onBonk,
          semanticsLabel: l10n.petSemantics(l10n.petName(store)),
          glasses: glasses,
          showArms: showArms,
          expression: expression,
          touchy: touchy,
          sounds: true,
          ownPet: true,
        );
      },
    );
  }
}

/// Height of the visible body for the current stage (for placing props
/// relative to the pet).
double _bodyHeight(double s) {
  final stage = sl<PetStore>().state.stage;
  return stage == PetStage.egg
      ? 0.84 * s * PetStage.egg.scale
      : 0.74 * s * stage.scale;
}

/// A room's wall and floor: a line where they meet, the floor in warm cream
/// — deeper by the wall, lighter around [pool], fading out at the sides and
/// into the page below — a lamp's [glow] (centre and radius) on the wall,
/// and soft [shadows] (oval, strength) where things stand.
class _RoomFloorPainter extends CustomPainter {
  final double floorY;
  final Offset pool;
  final (Offset, double)? glow;
  final List<(Rect, double)> shadows;
  final double k;
  _RoomFloorPainter({
    required this.floorY,
    required this.pool,
    required this.k,
    this.glow,
    this.shadows = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const back = Color(0xFFE7D9C5);
    const front = Color(0xFFF2E9DC);
    const light = Color(0xFFFCF8F2);
    const line = Color(0xFFDCD5C9);
    const warm = Color(0xFFFFE6B0);

    final g = glow;
    if (g != null) {
      final (c, r) = g;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            warm.withValues(alpha: 0.4),
            warm.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final floor = Rect.fromLTRB(0, floorY, w, size.height + 12);
    canvas.saveLayer(floor, Paint());
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [back, front],
        ).createShader(floor),
    );
    final glowRect = Rect.fromCenter(
        center: pool, width: w * 1.1, height: floor.height * 2.4);
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(colors: [light, light.withValues(alpha: 0)])
            .createShader(glowRect),
    );
    // Fade into the page at the sides and below.
    for (final (begin, end, stops) in [
      (Alignment.topCenter, Alignment.bottomCenter, const [0.0, 0.6, 1.0]),
      (Alignment.centerLeft, Alignment.centerRight, const [0.0, 0.08, 0.92]),
    ]) {
      final vertical = begin == Alignment.topCenter;
      canvas.drawRect(
        floor,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: begin,
            end: end,
            colors: vertical
                ? const [Colors.black, Colors.black, Colors.transparent]
                : const [Colors.transparent, Colors.black, Colors.black],
            stops: stops,
          ).createShader(floor),
      );
    }
    canvas.drawRect(
      floor,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Colors.transparent, Colors.black],
          stops: [0.0, 0.08],
        ).createShader(floor),
    );
    canvas.restore();
    canvas.drawLine(
        Offset(w * 0.04, floorY),
        Offset(w * 0.96, floorY),
        Paint()
          ..strokeWidth = 1
          ..color = line);

    _ContactShadows(shadows.map((e) => e.$1).toList(),
            strengths: shadows.map((e) => e.$2).toList())
        .paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _RoomFloorPainter old) =>
      old.floorY != floorY ||
      old.pool != pool ||
      old.glow != glow ||
      old.shadows.length != shadows.length;
}

/// Soft dark ovals where things stand (each with a strength, 1 by default).
class _ContactShadows extends CustomPainter {
  final List<Rect> ovals;
  final List<double>? strengths;
  _ContactShadows(this.ovals, {this.strengths});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < ovals.length; i++) {
      final oval = ovals[i];
      final strength = strengths?[i] ?? 1;
      canvas.drawOval(
        oval,
        Paint()
          ..color = Colors.black.withValues(alpha: (0.28) * strength)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, math.max(2, oval.height * 0.6)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ContactShadows old) =>
      old.ovals.length != ovals.length;
}

/// A piece's silhouette blurred onto the wall behind it, shifted by
/// [offset] (away from the light).
class _PropShadow extends StatelessWidget {
  final String asset;
  final Rect rect;
  final Offset offset;
  final double k;
  const _PropShadow({
    required this.asset,
    required this.rect,
    required this.offset,
    required this.k,
  });

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: rect.shift(offset),
        child: IgnorePointer(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
                sigmaX: 5 * k, sigmaY: 5 * k, tileMode: TileMode.decal),
            child: Image.asset(
              'assets/$asset.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              color: Colors.black.withValues(alpha: 0.18),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      );
}

/// One illustrated piece of a room, [asset] being its path under
/// `assets/` without the extension (`library/plank`, `notes/desk`…).
class _Prop extends StatelessWidget {
  final String asset;
  const _Prop(
    this.asset,
  );

  static Widget at(Rect rect, String asset) =>
      Positioned.fromRect(rect: rect, child: _Prop(asset));

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Image.asset(
          'assets/$asset.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),
      );
}
