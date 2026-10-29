import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/services/app_pause.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/source_meta.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/presentation/widgets/blob_mascot.dart';
import '../../../companion/presentation/widgets/notebook_painter.dart';
import '../../../companion/presentation/widgets/pet_speech_bubble.dart';
import '../../../notes/presentation/widgets/sticky_note.dart';
import '../../../vault/domain/entities/note_entity.dart';
import 'coin_drop.dart';
import 'mosquito_hunt.dart';
import 'pet_visitor.dart';
import 'tv_channels.dart';
import 'wall_clock.dart';
import 'wall_gecko.dart';

part 'pet_scene_room.dart';
part 'pet_scene_board.dart';
part 'pet_scene_scribe.dart';
part 'pet_scene_bed.dart';

/// The pet's living room on Beranda, furnished with illustrated pieces
/// (`assets/home/`) so the pet has a cosy place to live.
///
/// * Bookshelf (left) — tap it for all your collections.
/// * TV on a low console (centre) — plays little clips on a loop; tap it
///   to change the channel.
/// * A pegboard with sticky notes over the shelf — the top note says how
///   many links were saved today; tap it and they come off the board,
///   fanned out over the room as sticky notes.
/// * A wall calendar above the TV with today's month and date (tap it and
///   the pet tells you the date).
/// * A wall clock showing the real time, a plant, an armchair with a floor
///   lamp beside it, a side table with a mug, and the rug the pet sits on.
/// * Once in a long while a gecko scuttles across the wall ("cek cek
///   cek") — an easter egg.
///
/// With [canLift] the pet can be picked up (long press or an upward drag)
/// and carried around the room; let go and it drops to the floor.
///
/// Given a link (see [scribe]) it pulls out its notebook, puts its glasses
/// on and writes the note up, then holds the page up to show you.
class PetScene extends StatefulWidget {
  final BlobController controller;

  /// -1..1 — how far the pet has wandered from its cushion, sideways.
  final Animation<double> walk;

  /// 0..1 — how far back towards the wall it has walked (0 on the rug,
  /// 1 right in front of the furniture along the wall). It gets a little
  /// smaller further back, and the chair and side table hide it when it's
  /// behind them.
  final Animation<double> depth;
  final BlobColor color;
  final BlobAccessory accessory;
  final BlobOutfit outfit;
  final PetStage stage;
  final CompanionMood mood;
  final String semanticsLabel;
  final int todayCount;

  /// Notes to fan out over the scene, or null when the fan is closed.
  final List<NoteEntity>? fan;
  final VoidCallback onPet;
  final VoidCallback onPlay;

  /// The pet was smacked (tapped); how many times in a row.
  final ValueChanged<int>? onBonk;

  /// The gecko came out on the wall.
  final VoidCallback? onGecko;
  final VoidCallback onAllCollections;
  final VoidCallback onTodayTap;
  final ValueChanged<NoteEntity> onFanCardTap;

  /// What the pet is saying right now, shown in a bubble over its head
  /// (it walks along with the pet). Null hides the bubble.
  final String? speech;

  /// Whether the pet can be picked up right now.
  final bool canLift;

  /// Picked up.
  final VoidCallback? onLifted;

  /// Hit the floor after being let go; [hard] when it fell from high up.
  final ValueChanged<bool>? onLanded;

  /// Asleep on its spot: in its thick padded jacket, sitting on its
  /// floor cushion.
  final bool sleeping;

  /// The pet's pocket money: shaken about while it's held, it spills coins
  /// on the floor ([CoinFloor]); [onCoinDropped] fires for each one.
  final CoinController? coins;
  final VoidCallback? onCoinDropped;

  /// Where it ended up, as a [walk] value — the parent should set [walk]
  /// to it so the pet stays put.
  final ValueChanged<double>? onSettled;

  /// Writing up a link, or showing you the finished page; null when it
  /// isn't (the notebook goes away).
  final ScribePhase? scribe;

  /// What's on the page it shows you.
  final String? scribeTitle;
  final List<String> scribeTags;

  /// The wall calendar was tapped.
  final VoidCallback? onCalendarTap;

  /// A friend dropping by (see [PetVisit]); [visitInterrupted] sends it
  /// off early. The pet's side of the chat goes through [onHostSay], and
  /// [onVisitDone] fires once the friend has left.
  final VisitPlan? visit;
  final bool visitInterrupted;
  final void Function(String line, Duration hold)? onHostSay;
  final VoidCallback? onVisitDone;

  /// A mosquito buzzing in (see [MosquitoHunt]); [mosquitoInterrupted]
  /// sends it off. [onMosquitoChase] walks the pet after it (to a [walk]
  /// value), its lines go through [onHostSay], and [onMosquitoDone] fires
  /// once it's eaten or gone.
  final MosquitoPlan? mosquito;
  final bool mosquitoInterrupted;
  final Future<void> Function(double walk)? onMosquitoChase;
  final VoidCallback? onMosquitoDone;

  const PetScene({
    super.key,
    required this.controller,
    required this.walk,
    required this.depth,
    required this.color,
    required this.accessory,
    this.outfit = BlobOutfit.none,
    required this.stage,
    required this.mood,
    required this.semanticsLabel,
    required this.todayCount,
    required this.fan,
    required this.onPet,
    required this.onPlay,
    this.onBonk,
    this.onGecko,
    required this.onAllCollections,
    required this.onTodayTap,
    required this.onFanCardTap,
    this.speech,
    this.canLift = false,
    this.onLifted,
    this.onLanded,
    this.sleeping = false,
    this.coins,
    this.onCoinDropped,
    this.onSettled,
    this.scribe,
    this.scribeTitle,
    this.scribeTags = const [],
    this.onCalendarTap,
    this.visit,
    this.visitInterrupted = false,
    this.onHostSay,
    this.onVisitDone,
    this.mosquito,
    this.mosquitoInterrupted = false,
    this.onMosquitoChase,
    this.onMosquitoDone,
  });

  /// Where to stand ([walk] values) to watch the TV or browse the shelf.
  static const tvSpot = (walk: 0.31, depth: 0.85);
  static const shelfSpot = (walk: -0.88, depth: 0.9);

  @override
  State<PetScene> createState() => _PetSceneState();
}

/// What the pet is doing with a link you gave it on Beranda.
enum ScribePhase {
  /// Notebook out, glasses on, writing the note.
  writing,

  /// Holding the finished page up for you to see.
  presenting,
}

class _PetSceneState extends State<PetScene> with TickerProviderStateMixin {
  /// How far the pet has been carried from where it stood (dy < 0 is up).
  final _carry = ValueNotifier<Offset>(Offset.zero);
  late final AnimationController _fall = AnimationController(vsync: this);
  double _fallFrom = 0;
  _Room? _room;

  // Writing a link up: the notebook coming out (and going away), the
  // writing itself, and holding the page up.
  late final AnimationController _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      reverseDuration: const Duration(milliseconds: 450));
  late final AnimationController _write =
      AnimationController(vsync: this, duration: const Duration(seconds: 7));
  late final AnimationController _present = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      reverseDuration: const Duration(milliseconds: 300));

  /// 0: nothing; 1: its hands are on the notebook (so not at its sides);
  /// 2: glasses on too.
  final _gear = ValueNotifier<int>(0);

  /// Asleep on its own spot — not carried off, dropped somewhere else or
  /// walked away: its cushion is out and its parka is on.
  final _inBed = ValueNotifier<bool>(false);

  /// Its cushion coming out (or going away).
  late final AnimationController _bed = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      reverseDuration: const Duration(milliseconds: 280));

  @override
  void initState() {
    super.initState();
    _intro.addListener(_syncGear);
    _write.addListener(_followPen);
    if (widget.scribe != null) _scribeChanged(null);
    for (final l in _whereabouts) {
      l.addListener(_syncInBed);
    }
    _inBed.addListener(() => _inBed.value ? _bed.forward() : _bed.reverse());
    _syncInBed();
    _bed.value = _inBed.value ? 1 : 0;
  }

  /// What says where the pet is.
  List<Listenable> get _whereabouts =>
      [widget.walk, widget.depth, _carry, _fall];

  void _syncInBed() {
    final home = widget.walk.value.abs() < 0.04 &&
        widget.depth.value < 0.04 &&
        !_fall.isAnimating &&
        _carry.value.distance < 1;
    _inBed.value = widget.sleeping && home;
  }

  @override
  void didUpdateWidget(covariant PetScene old) {
    super.didUpdateWidget(old);
    if (old.scribe != widget.scribe) _scribeChanged(old.scribe);
    if (old.walk != widget.walk || old.depth != widget.depth) {
      old.walk.removeListener(_syncInBed);
      old.depth.removeListener(_syncInBed);
      widget.walk.addListener(_syncInBed);
      widget.depth.addListener(_syncInBed);
    }
    if (old.sleeping != widget.sleeping) _syncInBed();
  }

  @override
  void dispose() {
    for (final l in _whereabouts) {
      l.removeListener(_syncInBed);
    }
    _inBed.dispose();
    _fall.dispose();
    _carry.dispose();
    _bed.dispose();
    _intro.dispose();
    _write.dispose();
    _present.dispose();
    _gear.dispose();
    _stopPencil();
    super.dispose();
  }

  void _scribeChanged(ScribePhase? from) {
    final sound = SoundService.instance;
    switch (widget.scribe) {
      case ScribePhase.writing:
        _present.value = 0;
        _intro.forward();
        _write.repeat();
        widget.controller.focus(const Offset(0, 1));
        // The notebook comes out, then the pencil gets going.
        sound.play(Sfx.bookPull);
        _pencilTimer?.cancel();
        _pencilTimer = AppTimer(const Duration(milliseconds: 800), () {
          if (mounted && widget.scribe == ScribePhase.writing) {
            sound.setLoop(SfxLoop.pencil, true);
          }
        });
      case ScribePhase.presenting:
        _write.stop();
        _intro.value = 1;
        _present.forward(from: 0);
        widget.controller.focus(null);
        _stopPencil();
        sound.play(Sfx.paperTadaa, delay: const Duration(milliseconds: 150));
      case null:
        _write.stop();
        _present.reverse();
        _intro.reverse();
        widget.controller.focus(null);
        _stopPencil();
    }
  }

  Timer? _pencilTimer;

  void _stopPencil() {
    _pencilTimer?.cancel();
    SoundService.instance.setLoop(SfxLoop.pencil, false);
  }

  void _syncGear() {
    final v = _intro.value;
    _gear.value = v > 0.6 ? 2 : (v > 0.3 ? 1 : 0);
  }

  /// Eyes follow the pencil along each line once it's writing.
  void _followPen() {
    if (widget.scribe != ScribePhase.writing || _intro.value < 1) return;
    final (_, along) = notebookPenAt(_write.value);
    widget.controller.focus(Offset(0.1 + 0.4 * (1 - along), 1));
  }

  /// How far the pet has walked from its cushion, in pixels.
  double _walkX(_Room room) => widget.walk.value * room.w * 0.24;

  /// How far up the screen it is from walking back towards the wall.
  double _lift(_Room room) => widget.depth.value * room.backLift;

  /// Smaller the further back it is, like the furniture by the wall.
  double get _depthScale => 1 - 0.3 * widget.depth.value;

  bool _watchingGecko = false;

  /// The pet turns to look at the gecko (unless it's busy writing).
  void _geckoAppeared(Offset at) {
    final room = _room;
    if (room == null || widget.scribe != null) return;
    final petX = room.w / 2 + _walkX(room);
    _watchingGecko = true;
    widget.controller.focus(
        Offset(((at.dx - petX) / (room.w * 0.4)).clamp(-1.0, 1.0), -0.9));
    widget.onGecko?.call();
  }

  void _geckoLeft() {
    if (!_watchingGecko) return;
    _watchingGecko = false;
    if (widget.scribe == null) widget.controller.focus(null);
  }

  /// Coins spilled since it was picked up, and when the last one fell.
  int _coinsThisLift = 0;
  DateTime _lastCoin = DateTime(0);

  /// Most coins one shaking gets out of it.
  static const _coinsPerLift = 8;

  /// Shaken about: a coin falls out of it now and then.
  void _onShaken() {
    final room = _room;
    final coins = widget.coins;
    if (room == null || coins == null || _coinsThisLift >= _coinsPerLift) {
      return;
    }
    final now = clock.now();
    if (now.difference(_lastCoin) < const Duration(milliseconds: 140)) return;
    final at = Offset(
      room.w / 2 + _walkX(room) + _carry.value.dx,
      room.groundY -
          _lift(room) +
          _carry.value.dy -
          _bodyHeight(room.petS) * 0.12,
    );
    if (!coins.drop(at)) return;
    _lastCoin = now;
    _coinsThisLift++;
    widget.onCoinDropped?.call();
  }

  void _onLift() {
    _coinsThisLift = 0;
    // Caught mid-fall: pick it up from where it is now.
    if (_fall.isAnimating) {
      final v = _fall.value;
      _carry.value = Offset(_carry.value.dx, _fallFrom * (1 - v * v));
    }
    _fall.stop();
    widget.onLifted?.call();
  }

  /// Follows the finger, but keeps the pet (and its bubble) in the room.
  void _onCarry(Offset delta) {
    final room = _room;
    if (room == null) return;
    final petS = room.petS;
    final reach = room.w / 2 - petS * 0.45;
    final walkX = _walkX(room);
    final maxUp = math.max(
        0.0,
        math.min(
            room.h * 0.5, room.groundY - _bodyHeight(petS) - petS * 0.14 - 64));
    final next = _carry.value + delta;
    _carry.value = Offset(
      (walkX + next.dx).clamp(-reach, reach) - walkX,
      next.dy.clamp(-maxUp, 0.0),
    );
  }

  /// Let go: it falls straight down, faster and faster.
  void _onDrop() {
    final room = _room;
    final height = -_carry.value.dy;
    if (room == null || height < 1) {
      _landed(false);
      return;
    }
    _fallFrom = _carry.value.dy;
    final secs = math.sqrt(2 * height / 2600);
    _fall
      ..duration = Duration(milliseconds: (secs * 1000).round().clamp(80, 900))
      ..value = 0;
    _fall.animateTo(1).whenComplete(() {
      if (!mounted || _fall.value < 1) return;
      _landed(height > room.petS * 0.35);
    });
  }

  void _landed(bool hard) {
    final room = _room;
    _carry.value = Offset(_carry.value.dx, 0);
    widget.controller.land(hard: hard);
    widget.onLanded?.call(hard);
    // Fold the sideways carry into the walk so it stays where it landed.
    if (room != null && _carry.value.dx != 0) {
      widget.onSettled
          ?.call((_walkX(room) + _carry.value.dx) / (room.w * 0.24));
    }
    _carry.value = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final walk = widget.walk;
    final fan = widget.fan;
    return LayoutBuilder(builder: (context, c) {
      final room = _room = _Room(c.biggest);
      const colors = _RoomColors.room;
      final petS = room.petS;
      final petW = petS * BlobMascot.widthFactor;
      final petH = petS * BlobMascot.heightFactor;
      final moving =
          Listenable.merge([walk, widget.depth, _carry, _fall, _bed]);
      // Where its feet are within its canvas, to scale it about them.
      final feet = Alignment(0, ((petH - petS * 0.05) / petH) * 2 - 1);
      // Where the pet is relative to where it stands — up in the air while
      // carried or falling.
      Offset carried() => _fall.isAnimating
          ? Offset(_carry.value.dx, _fallFrom * (1 - _fall.value * _fall.value))
          : _carry.value;
      // The bed, made only on its own spot (carried or walked off, it's
      // gone).
      _BedLayout bed() {
        final home = widget.walk.value.abs() < 0.04 &&
            widget.depth.value < 0.04 &&
            carried().distance < 1;
        return _BedLayout(room, _bodyHeight(petS), home ? _bed.value : 0);
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LivingRoomPainter(room: room, colors: colors),
            ),
          ),
          // Each piece's silhouette, blurred onto the wall behind it, under
          // all the furniture. (Floor shadows are in the room painter.)
          for (final sh in room.wallShadows) _WallShadow(shadow: sh),
          Positioned.fromRect(
            rect: room.clock,
            child: WallClock(
              shadowOffset: room.shadowOn(room.clock, 2),
              semanticsLabel: l10n.homeClockSemantics(
                MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay.now(),
                    alwaysUse24HourFormat: true),
              ),
            ),
          ),
          // The gecko lives on the wall: under the pegboard (it hides
          // behind it) and the lamp.
          Positioned.fill(
            child: WallGecko(
              enabled: room.h >= 280 && widget.scribe == null,
              routes: room.geckoRoutes,
              pickRoute: (rng) {
                final h = DateTime.now().hour;
                final night = h >= 18 || h < 5;
                // At night it goes for the insects round the lamp.
                if (night && rng.nextDouble() < 0.6) return 2;
                return rng.nextInt(2);
              },
              length: 30 * room._k,
              chirp: l10n.homeGeckoChirp,
              onAppear: _geckoAppeared,
              onLeave: _geckoLeft,
            ),
          ),
          // Back to front: wall pieces, then the furniture along the wall,
          // then the rug and the pieces standing in front of it.
          Positioned.fromRect(
            rect: room.pegboard,
            child: _Pegboard(
              count: widget.todayCount,
              onTap: widget.onTodayTap,
            ),
          ),
          _Furniture.at(
            room.shelf,
            'bookshelf',
            semanticsLabel: l10n.homeShelfSemantics,
            onTap: widget.onAllCollections,
          ),
          _Furniture.at(room.lamp, 'floor_lamp'),
          _Furniture.at(room.console, 'tv_console'),
          _Furniture.at(room.tv, 'tv'),
          Positioned.fromRect(
            rect: room.screen,
            child: TvChannels(semanticsLabel: l10n.homeTvChannel),
          ),
          _Furniture.at(room.plant, 'plant'),
          Positioned.fromRect(
            rect: room.calendar.inflate(6),
            child: _WallCalendar(
              onTap: widget.onCalendarTap,
            ),
          ),
          _Furniture.at(room.rug, 'rug'),
          // On top of the rug, under the pieces that throw them.
          for (final sh in room.castShadows) _CastShadow(shadow: sh),
          _Furniture.at(room.sideTable, 'side_table'),
          _Furniture.at(room.chair, 'armchair'),
          // Its floor cushion, under it.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ZabutonPainter(bed, repaint: moving),
              ),
            ),
          ),
          // Its shadow stays on the floor while it's up in the air.
          Positioned(
            left: room.w / 2 - petS * 0.45,
            top: room.groundY - petS * 0.05,
            width: petS * 0.9,
            height: petS * 0.1,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: moving,
                builder: (_, __) {
                  final at = carried();
                  if (at.dy > -1) return const SizedBox();
                  final up = (-at.dy / (room.h * 0.5)).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(_walkX(room) + at.dx, -_lift(room)),
                    child: Transform.scale(
                      scale: (1 - up * 0.5) * _depthScale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.all(Radius.elliptical(petS, petS)),
                          color: Colors.black
                              .withValues(alpha: 0.12 * (1 - up * 0.5)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            key: const ValueKey('pet'),
            left: room.w / 2 - petW / 2,
            top: room.groundY - petH + petS * 0.05,
            child: AnimatedBuilder(
              animation: moving,
              builder: (_, child) => Transform.translate(
                // Up on its cushion when it's out.
                offset:
                    Offset(_walkX(room), -_lift(room) - bed().seat) + carried(),
                child: Transform.scale(
                  scale: _depthScale,
                  alignment: feet,
                  child: child,
                ),
              ),
              child: ListenableBuilder(
                listenable: Listenable.merge([_gear, _inBed]),
                builder: (_, __) => BlobMascot(
                  size: petS,
                  color: widget.color,
                  accessory: widget.accessory,
                  outfit: widget.outfit,
                  stage: widget.stage,
                  mood: widget.mood,
                  controller: widget.controller,
                  onPet: widget.onPet,
                  onPlay: widget.onPlay,
                  onBonk: widget.onBonk,
                  sounds: true,
                  ownPet: true,
                  semanticsLabel: widget.semanticsLabel,
                  onLift: widget.canLift ? _onLift : null,
                  onCarry: _onCarry,
                  onDrop: _onDrop,
                  onShaken: widget.coins == null ? null : _onShaken,
                  glasses: _gear.value >= 2,
                  showArms: _gear.value < 1,
                  jacket: _inBed.value,
                  expression: widget.scribe == ScribePhase.writing
                      ? BlobExpression.serious
                      : null,
                ),
              ),
            ),
          ),
          // Gone round behind the side table or the armchair (on its way to
          // the shelf or the TV): those pieces are drawn again on top of it.
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: moving,
                  builder: (_, __) {
                    final at = carried();
                    if (at.dy < -1 || widget.depth.value < 0.02) {
                      return const SizedBox.shrink();
                    }
                    final footY = room.groundY - _lift(room);
                    final x = room.w / 2 + _walkX(room) + at.dx;
                    final half = petS * 0.5 * _depthScale;
                    bool hides(Rect r) =>
                        footY < r.bottom - 4 &&
                        x + half > r.left &&
                        x - half < r.right;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (hides(room.sideTable))
                          _Furniture.at(room.sideTable, 'side_table'),
                        if (hides(room.chair))
                          _Furniture.at(room.chair, 'armchair'),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Its spilled coins, on the floor in front.
          if (widget.coins != null)
            Positioned.fill(
              child: CoinFloor(
                controller: widget.coins!,
                sceneWidth: room.w,
                groundY: room.groundY,
                petS: petS,
                walkScale: room.w * 0.24,
                bodyHeight: _bodyHeight(petS),
                walk: walk,
              ),
            ),
          // Its notebook, pencil and the page it holds up.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScribePainter(
                  room: room,
                  colors: colors,
                  petX: () => _walkX(room) + carried().dx,
                  stage: widget.stage,
                  hands:
                      widget.stage == PetStage.egg ? null : widget.color.shade,
                  intro: _intro,
                  write: _write,
                  present: _present,
                  title: widget.scribeTitle,
                  tags: widget.scribeTags,
                  ink: context.palette.textPrimary,
                  accent: context.palette.primary,
                  repaint: Listenable.merge([moving, _intro, _write, _present]),
                ),
              ),
            ),
          ),
          // A friend popping by, on the same floor (needs a room tall
          // enough to stand in; it leaves if the room shrinks).
          if (widget.visit != null)
            Positioned.fill(
              child: PetVisit(
                key: ObjectKey(widget.visit),
                plan: widget.visit!,
                sceneWidth: room.w,
                sceneHeight: room.h,
                groundY: room.groundY,
                petS: petS,
                host: widget.controller,
                interrupted: widget.visitInterrupted || room.h < 280,
                onHostSay: (line, hold) => widget.onHostSay?.call(line, hold),
                onDone: () => widget.onVisitDone?.call(),
              ),
            ),
          // A mosquito, flying about in front of everything.
          if (widget.mosquito != null)
            Positioned.fill(
              child: MosquitoHunt(
                key: ObjectKey(widget.mosquito),
                plan: widget.mosquito!,
                sceneWidth: room.w,
                groundY: room.groundY,
                petS: petS,
                walk: walk,
                walkScale: room.w * 0.24,
                host: widget.controller,
                interrupted: widget.mosquitoInterrupted || room.h < 280,
                onChase: (to) async => widget.onMosquitoChase?.call(to),
                onSay: (line, hold) => widget.onHostSay?.call(line, hold),
                onDone: () => widget.onMosquitoDone?.call(),
              ),
            ),
          // Speech bubble just above the head (and any hat). It walks with
          // the pet but stops at the scene's edges so it never runs off
          // screen; the tail still points down at the pet.
          Positioned(
            left: 0,
            right: 0,
            bottom: room.h - room.groundY + _bodyHeight(petS) + petS * 0.14,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: moving,
                builder: (_, child) {
                  final at = carried();
                  final bubbleW = math.min(210.0, room.w * 0.66);
                  final reach = math.max(0.0, room.w / 2 + 12 - bubbleW / 2);
                  final dx = (_walkX(room) + at.dx).clamp(-reach, reach);
                  final shrink =
                      (_bodyHeight(petS) + petS * 0.14) * (1 - _depthScale);
                  return Transform.translate(
                      offset: Offset(dx, at.dy - _lift(room) + shrink),
                      child: child);
                },
                child: Center(
                  child: PetSpeechBubble(
                    text: widget.speech,
                    maxWidth: math.min(210.0, room.w * 0.66),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: fan == null,
              // The notes fly out by themselves; on the way back they fade.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: fan == null
                    ? const SizedBox.shrink()
                    : _Fan(
                        key: ValueKey(fan.map((n) => n.id).join()),
                        notes: fan,
                        from: room.pegboard.center,
                        centerY: room.tv.bottom + room.h * 0.04,
                        onTap: widget.onFanCardTap,
                      ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Visible height of the pet's body for the current life stage.
  double _bodyHeight(double petS) => widget.stage == PetStage.egg
      ? 0.84 * petS * PetStage.egg.scale
      : 0.74 * petS * widget.stage.scale;
}
