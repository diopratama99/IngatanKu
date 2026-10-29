import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/sound_service.dart';
import '../../data/pet_hurt.dart';
import '../../domain/companion_style.dart';
import 'food_painter.dart';
import 'mosquito_painter.dart';

part 'blob_painter.dart';
part 'blob_wardrobe_painter.dart';

/// Imperative handle so Beranda (action buttons, the pantry, the save
/// listener) can trigger reactions on a [BlobMascot] it doesn't own —
/// same attach/detach pattern as [ScrollController].
class BlobController {
  _BlobMascotState? _state;

  void pet() => _state?._pet(null);
  void play() => _state?._play();
  void shake() => _state?._shake();

  /// Stars, hearts and a happy bounce — with a level-up jingle, or another
  /// [sound] (a visiting friend cheers).
  void celebrate({Sfx sound = Sfx.levelUp}) => _state?._celebrate(sound);

  /// Food flies from [fromGlobal] (or from below) into the mouth, gets
  /// chewed, then savoured — or, when it isn't [tasty] (a wrong quiz
  /// answer), it pulls a face. A [snack] gets a lighter crunch.
  void eat(FoodKind food,
          {Offset? fromGlobal, bool tasty = true, bool snack = false}) =>
      _state?._eat(food, fromGlobal, tasty: tasty, snack: snack);

  /// A little burp, then a satisfied pat — it's full.
  void burp() => _state?._burp();

  /// First meal: the food sinks into the egg, which rocks, cracks and
  /// pops open. Call before switching the widget's stage to baby.
  void hatch(FoodKind food, {Offset? fromGlobal}) =>
      _state?._hatch(food, fromGlobal);

  /// Food being dragged at [global]; the pet watches it and opens wide
  /// as it gets close. Pass null when the drag leaves.
  void hover(Offset? global) => _state?._hover(global);

  /// Little stepping hops facing [direction] (-1 left, 1 right) while the
  /// parent slides the pet around; 0 stops.
  void walk(int direction) => _state?._walkDir = direction;

  /// Keep looking at [at] (-1..1 on each axis, e.g. down at a book) until
  /// cleared with null. With [scan] the eyes sweep side to side, like
  /// reading or writing line by line.
  void focus(Offset? at, {bool scan = false}) {
    _state?._gaze = at;
    _state?._scan = scan;
  }

  /// Mouth moves as if speaking while true.
  void talk(bool talking) => _state?._talking = talking;

  /// Pulls [expression] for [duration], or until cleared with null when
  /// no duration is given. Petting and other happy moments still show
  /// over it; it takes over from the sulk after a landing.
  void express(BlobExpression? expression, {Duration? duration}) =>
      _state?._express(expression, duration);

  /// Beams for [duration] — happy eyes and an open smile, no hearts — when
  /// it's proud of something (showing you the note it wrote).
  void beam({Duration duration = const Duration(milliseconds: 1600)}) =>
      _state?._beam(duration);

  /// Touches down after being dropped (see [BlobMascot.onDrop]). A [hard]
  /// landing leaves it dizzy for [dizzyFor] and then sulking for
  /// [grumpyFor]; a soft one only sulks, for [softGrumpyFor].
  void land({required bool hard}) => _state?._land(hard);

  /// Plays one of its idle moves (see [BlobIdle]); anything that happens
  /// to it — a pat, a meal, being picked up — cuts it short.
  void idle(BlobIdle move) => _state?._startIdle(move);

  /// In tears: smacked [cryAfter] times in a row, it's bruised and crying,
  /// and only petting calms it down. Pages listen to keep idle moves,
  /// walks and visitors away until it has.
  final crying = ValueNotifier<bool>(false);

  /// Curls up into a ball (on) and rolls along with however the parent
  /// moves it, turning as far as it travels; off uncurls it with a hop.
  /// On again while rolling just gives another "wheee!" (back on screen).
  /// It can't be touched while it rolls.
  void roll(bool on) => _state?._roll(on);

  /// Jumps with its mouth wide open and slurps up whatever's at
  /// [fromGlobal] (a mosquito), then chews and gulps — takes [hapLength].
  void hap({Offset? fromGlobal}) => _state?._hap(fromGlobal);

  /// How long each idle move takes.
  static Duration idleLength(BlobIdle move) => Duration(
        milliseconds: switch (move) {
          BlobIdle.stretch => 2400,
          BlobIdle.wave => 2000,
          BlobIdle.dance => 2800,
          BlobIdle.hum => 6800,
          BlobIdle.doze => 3600,
          BlobIdle.spin => 1300,
          BlobIdle.lookAround => 3000,
          BlobIdle.sneeze => 1700,
        },
      );

  static const dizzyFor = Duration(milliseconds: 2000);

  /// How long eating takes, from the food flying in to the pet's verdict.
  static const eatLength = Duration(milliseconds: 1300);
  static const burpLength = Duration(milliseconds: 1300);
  static const grumpyFor = Duration(milliseconds: 2600);
  static const softGrumpyFor = Duration(milliseconds: 1600);

  /// Smacks in a row (a few seconds apart at most) that make it cry; up to
  /// then it only gets cross.
  static const cryAfter = 6;

  static const hapLength = Duration(milliseconds: 1900);
}

/// Little things the pet does on its own when nothing's going on.
enum BlobIdle {
  /// Crouches, reaches up high with a big yawn, then shakes it off.
  stretch,

  /// Waves at you.
  wave,

  /// Bops side to side to a beat, little music notes popping out.
  dance,

  /// Sways with its eyes shut, humming notes.
  hum,

  /// Eyelids droop, head nods… then it startles awake.
  doze,

  /// Twirls round once with a hop.
  spin,

  /// Looks left, right, up — then back at you.
  lookAround,

  /// Builds up to a sneeze and lets it out.
  sneeze,
}

/// Faces the pet can pull on top of its mood. Short-lived ones come from
/// [BlobController.express] (or from what happens to it); a standing one
/// from [BlobMascot.expression]. Hungry and lonely pets show [hungry] and
/// [sad] on their own.
enum BlobExpression {
  /// Focused: narrowed eyes, level brows, a flat mouth.
  serious,

  /// Brows down, red puffed cheeks, a throbbing anger mark.
  angry,

  /// Worried brows, watery eyes and a tear rolling down.
  sad,

  /// Mouth hanging open, drooling, tummy rumbling.
  hungry,

  /// Wide eyes, a wobbly mouth, a sweat drop, trembling.
  scared,

  /// Spiral eyes and little stars circling its head.
  dizzy,

  /// Big round eyes and a small "o".
  surprised,

  /// Looking down its nose at you: half-lidded eyes, one brow up, chin up
  /// and a lopsided grin showing a few teeth. Teasing.
  smirk,

  /// That didn't taste good: eyes screwed up ("> <"), a wobbly mouth, a
  /// shudder.
  yuck,

  /// Bawling: eyes squeezed shut, mouth wide open, tears streaming down
  /// both cheeks, shaking with sobs. Its own (see [BlobController.crying]).
  crying,
}

/// The IngatanKu pet: a jelly blob drawn entirely in a [CustomPainter]
/// so it can breathe, blink, follow the finger, grow up and eat without
/// shipping any image assets.
///
/// Gestures (when [interactive]):
///  * stroke it (drag a finger back and forth) → petting: hearts and a
///    happy face. Keep stroking and it bounces with joy ([onPlay]).
///  * tap → a smack: it winces, then sulks for a moment ([onBonk]). Too
///    many in a row and it's bruised and in tears until it's petted.
///
/// [size] is the adult body's reference size S; younger [stage]s are
/// drawn smaller inside the same 1.5·S × 1.6·S canvas. The headroom
/// above the body is for jumps, hats and floating particles.
class BlobMascot extends StatefulWidget {
  final double size;
  final BlobColor color;
  final BlobAccessory accessory;

  /// What it's wearing over its body (see [BlobOutfit]).
  final BlobOutfit outfit;
  final PetStage stage;
  final CompanionMood mood;
  final BlobController? controller;
  final VoidCallback? onPet;
  final VoidCallback? onPlay;

  /// Tapped (smacked). Gets how many smacks in a row (within a few
  /// seconds), so the reaction can get crosser.
  final ValueChanged<int>? onBonk;
  final bool interactive;

  /// False renders a single still frame with no ticker — used for the
  /// accessory thumbnails in the wardrobe.
  final bool animate;
  final String? semanticsLabel;

  /// Reading glasses on top of whatever [accessory] it wears — for when
  /// it's busy with something serious, like writing notes.
  final bool glasses;

  /// False leaves out the little arms at its sides, so a scene can draw
  /// its hands somewhere else (on a notebook, holding a pencil).
  final bool showArms;

  /// Standing expression (the serious face at the desk). Reactions still
  /// show over it.
  final BlobExpression? expression;

  /// Somewhere quiet (the library): touches annoy it instead of pleasing
  /// it — a jolt and a glare, no hearts, no playing. [onPet] still fires.
  final bool touchy;

  /// Picking it up (Beranda only): an upward drag or a long press lifts
  /// it. [onCarry] gets every move in pixels and [onDrop] the release; the
  /// parent moves it around and calls [BlobController.land] once it hits
  /// the floor. Null keeps it planted.
  final VoidCallback? onLift;
  final ValueChanged<Offset>? onCarry;
  final VoidCallback? onDrop;

  /// Bundled up for the night (Beranda): it puts on its thick winter
  /// parka, hood up with a fur trim, and takes it off again when this goes
  /// back to false.
  final bool jacket;

  /// Shaken while it's held — quick swings up and down or side to side:
  /// it goes dizzy, and this fires on every swing once it's really being
  /// shaken (a few in a row).
  final VoidCallback? onShaken;

  /// Makes its sounds (squeaks, purrs, snores…). Off for little copies of
  /// it (thumbnails, avatars) so only the "real" pet on a page is heard.
  final bool sounds;

  /// The user's own pet, live on a page (not a visiting friend or a
  /// picture of it): being smacked to tears, bruised and comforted is
  /// shared with every other page it's on ([PetHurt]).
  final bool ownPet;

  const BlobMascot({
    super.key,
    required this.size,
    required this.color,
    required this.accessory,
    this.outfit = BlobOutfit.none,
    this.stage = PetStage.adult,
    this.mood = CompanionMood.content,
    this.controller,
    this.onPet,
    this.onPlay,
    this.onBonk,
    this.interactive = true,
    this.animate = true,
    this.semanticsLabel,
    this.glasses = false,
    this.showArms = true,
    this.expression,
    this.touchy = false,
    this.onLift,
    this.onCarry,
    this.onDrop,
    this.onShaken,
    this.jacket = false,
    this.sounds = false,
    this.ownPet = false,
  });

  static const widthFactor = 1.5;
  static const heightFactor = 1.6;

  @override
  State<BlobMascot> createState() => _BlobMascotState();
}

enum _Eyes { open, happy, closed }

enum _Mouth { smile, open, flat, small, frown, wavy, grin, wail, gape }

enum _PKind { heart, star, dust, zzz, shell, note, puff, tear }

/// Everything the painter needs for one frame. Recomputed on every
/// tick from the reaction timestamps in [_BlobMascotState].
class _Pose {
  double t = 0;
  double jump = 0;
  double squash = 0;
  double tilt = 0;
  double shakeX = 0;
  double arm = 0;

  /// The right arm on its own (raised 0..1.3) while waving, or < 0 to
  /// follow [arm]; [armWave] swings it.
  double armRight = -1;
  double armWave = 0;

  /// Horizontal facing, 1 front … -1 back, while twirling.
  double turn = 1;

  /// Its winter parka: 0 off … 1 on.
  double jacket = 0;
  double eyeOpen = 1;
  double mouthOpen = 0;
  double cheekPuff = 0;
  Offset look = Offset.zero;
  _Eyes eyes = _Eyes.open;
  _Mouth mouth = _Mouth.smile;
  bool sadBrows = false;

  /// The face it's pulling, if any (see [BlobExpression]).
  BlobExpression? expr;

  /// Picked up: feet dangle and the floor shadow goes.
  bool held = false;

  bool egg = false;

  /// 0..1 crack growth while hatching.
  double crack = 0;

  /// 0..1 while food flies into the mouth (or egg), else null.
  double? food;

  /// Eyes screwed shut ("> <") with effort, whatever the face.
  bool squint = false;

  /// 0..1 how bruised it is (a black eye, a bump, a plaster).
  double bruise = 0;

  /// Curled up into a ball (0..1), and how far round it has rolled.
  double ball = 0;
  double roll = 0;

  /// 0..1 while a mosquito is slurped into its mouth, else null.
  double? slurp;
}

class _Particle {
  final _PKind kind;
  final Offset origin;
  final Offset velocity;
  final double born;
  final double life;
  final double spin;
  final double scale;
  const _Particle({
    required this.kind,
    required this.origin,
    required this.velocity,
    required this.born,
    required this.life,
    this.spin = 0,
    this.scale = 1,
  });
}

class _BlobMascotState extends State<BlobMascot>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  final _frame = ValueNotifier<int>(0);
  final _rng = math.Random();
  final _pose = _Pose();
  final _particles = <_Particle>[];

  double _t = 0;
  double _lastT = 0;

  // Reaction start times (seconds on the ticker clock).
  double? _petAt;
  double? _playAt;
  double? _eatAt;
  double? _shakeAt;
  double? _celebrateAt;
  double? _hatchAt;
  double? _burpAt;
  bool _eatTasty = true;
  bool _eatSnack = false;
  double _happyUntil = -1;
  double _wakeUntil = -1;

  FoodKind _food = FoodKind.cookie;
  int _walkDir = 0;
  Offset? _gaze;
  bool _scan = false;
  bool _talking = false;
  Offset? _foodFrom;
  Offset? _hoverLocal;

  // Blinking + gaze.
  double _nextBlink = 1.5;
  double _blinkAt = -10;
  Offset _lookTarget = Offset.zero;
  double _lookHoldUntil = 0;
  double _nextWander = 2;

  // Idle fidgets so the pet never looks frozen.
  double _nextFidget = 6;
  double _fidgetAt = -10;
  int _fidgetKind = 0;
  double _nextZzz = 1;

  // The idle move being played.
  BlobIdle? _idle;
  double _idleAt = -10;

  // Expressions and being carried around.
  BlobExpression? _exprOverride;
  double _exprUntil = double.infinity;
  bool _held = false;
  bool _falling = false;
  double _heldAt = -10;
  Offset? _lastLift;

  /// How far its jacket is on (see [BlobMascot.jacket]).
  double _jacket = 0;

  // Being shaken while held: how far the finger has gone each way (x, y)
  // since it last turned, which way it's going, the times of the recent
  // turns, and dizzy until when.
  final _swingTravel = [0.0, 0.0];
  final _swingDir = [0, 0];
  final _swings = <double>[];
  double _shakenUntil = -10;
  double? _landAt;
  bool _landHard = false;
  double _pokeAt = -10;

  // Gesture bookkeeping.
  double _strokeDist = 0;
  double _lastPetParticle = -1;
  final _recentStrokes = <double>[];

  // Smacks: when, from which side (-1 left … 1 right), and the run of
  // them so it gets crosser.
  double _bonkAt = -10;
  double _bonkSide = 0;
  double _touchAt = -10;
  final _recentBonks = <double>[];

  // In tears: since when (the latest wail), how much petting it's had
  // lately, and when it calmed down (the bruises fade after that).
  bool _crying = false;
  double _cryAt = -10;
  double? _bruisedAt;
  int _comfort = 0;
  double _lastComfort = -10;
  double _calmAt = -10;
  double _nextSob = 0;
  double _nextTear = 0;
  static const _comfortNeeded = 6;

  // Rolling about as a ball: when it curled up / uncurled, how far round
  // it has turned, and where it was on screen last frame.
  bool _rolling = false;
  double _rollAt = -10;
  double _unrollAt = -10;
  double _rollAngle = 0;
  double _unrollFrom = 0;
  double _unrollTo = 0;
  double _rollDir = 1;
  double? _lastRollX;

  // Hap!
  double? _hapAt;
  Offset? _hapFrom;

  static const _hatchFeed = 0.32;
  static const _hatchPop = 1.15;

  double get _s => widget.size;
  double get _w => _s * BlobMascot.widthFactor;
  double get _h => _s * BlobMascot.heightFactor;
  double get _groundY => _h - _s * 0.05;

  bool get _showEgg =>
      widget.stage == PetStage.egg ||
      (_hatchAt != null && _t - _hatchAt! < _hatchPop);

  double get _scale => _showEgg ? PetStage.egg.scale : widget.stage.scale;
  double get _rx => _s * 0.42 * _scale;
  double get _ry => _s * (_showEgg ? 0.5 : 0.37) * _scale;

  bool get _sleeping =>
      !_showEgg &&
      !_crying &&
      widget.mood == CompanionMood.sleepy &&
      _t > _wakeUntil;

  bool get _happing =>
      _hapAt != null && _t - _hapAt! < _secs(BlobController.hapLength);

  /// Rolling, or mid-hap: it can't be touched just now.
  bool get _busyMoving => _rolling || _t - _unrollAt < 0.45 || _happing;

  bool get _sad =>
      widget.mood == CompanionMood.hungry ||
      widget.mood == CompanionMood.lonely;

  static double _secs(Duration d) => d.inMicroseconds / 1e6;

  /// The face from the landing after a drop at [t], while that lasts.
  BlobExpression? _landingExpr(double t) {
    final at = _landAt;
    if (at == null) return null;
    final d = t - at;
    if (_landHard) {
      final dizzy = _secs(BlobController.dizzyFor);
      if (d < dizzy) return BlobExpression.dizzy;
      if (d < dizzy + _secs(BlobController.grumpyFor)) {
        return BlobExpression.angry;
      }
    } else if (d < _secs(BlobController.softGrumpyFor)) {
      return BlobExpression.angry;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    if (widget.ownPet) {
      PetHurt.instance.addListener(_syncHurt);
      _syncHurt();
    }
    if (widget.animate) {
      _ticker = createTicker(_onTick)..start();
    }
    _computePose();
  }

  @override
  void didUpdateWidget(covariant BlobMascot old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller?._state == this) old.controller!._state = null;
      widget.controller?._state = this;
      _tellCrying();
    }
    if (old.ownPet != widget.ownPet) {
      widget.ownPet
          ? PetHurt.instance.addListener(_syncHurt)
          : PetHurt.instance.removeListener(_syncHurt);
    }
    // Lifting switched off mid-carry: let go rather than float forever.
    if (old.onLift != null && widget.onLift == null && _held) _liftEnd();
    if (!widget.animate) _computePose();
  }

  // Sounds that keep going while something lasts.
  bool _trembling = false;
  bool _snoring = false;
  ValueListenable<bool>? _visible;

  bool get _audible => widget.sounds && widget.interactive && widget.animate;

  void _sfx(Sfx sfx, {double delay = 0, double volume = 1}) {
    if (!_audible) return;
    SoundService.instance.play(sfx,
        delay: Duration(milliseconds: (delay * 1000).round()), volume: volume);
  }

  /// Keeps the tremble (held up) and snore (asleep) loops in step with it.
  void _syncLoops() {
    final on = _audible && (_visible?.value ?? true);
    final tremble = on && (_held || _falling) && _t - _heldAt > 0.35;
    final snore = on && _sleeping;
    if (tremble != _trembling) {
      _trembling = tremble;
      SoundService.instance.setLoop(SfxLoop.tremble, tremble);
    }
    if (snore != _snoring) {
      _snoring = snore;
      SoundService.instance.setLoop(SfxLoop.snore, snore);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hushed while its page is covered by another one.
    final visible = TickerMode.getNotifier(context);
    if (visible != _visible) {
      _visible?.removeListener(_syncLoops);
      _visible = visible..addListener(_syncLoops);
    }
  }

  @override
  void dispose() {
    if (widget.ownPet) PetHurt.instance.removeListener(_syncHurt);
    _visible?.removeListener(_syncLoops);
    if (_trembling) SoundService.instance.setLoop(SfxLoop.tremble, false);
    if (_snoring) SoundService.instance.setLoop(SfxLoop.snore, false);
    final controller = widget.controller;
    if (controller?._state == this) {
      controller!._state = null;
      // Gone mid-tears: nobody's crying any more (unless another pet has
      // taken the controller over by then).
      if (_crying) {
        Future.microtask(() {
          if (controller._state == null) controller.crying.value = false;
        });
      }
    }
    _ticker?.dispose();
    _frame.dispose();
    super.dispose();
  }

  /// Takes on the shared hurt state ([PetHurt]) — crying, bruises,
  /// comfort — with its times moved onto this pet's own clock. Runs when
  /// it changes (on any page) and every frame while it lasts.
  void _syncHurt() {
    final hurt = PetHurt.instance;
    final now = DateTime.now();
    hurt.heal(now);
    double? onClock(DateTime? at) =>
        at == null ? null : _t - now.difference(at).inMicroseconds / 1e6;
    final was = _crying;
    _crying = hurt.crying;
    _cryAt = onClock(hurt.cryAt) ?? -10;
    _bruisedAt = onClock(hurt.bruisedAt);
    _calmAt = onClock(hurt.calmAt) ?? -10;
    _comfort = hurt.comfort;
    _lastComfort = onClock(hurt.lastComfort) ?? -10;
    if (_crying == was) return;
    if (_crying) {
      // Set off somewhere else: whatever it was doing here stops.
      _idle = null;
      _exprOverride = null;
      _happyUntil = -1;
      _nextSob = _t + 1.0;
    }
    _tellCrying();
  }

  /// Lets the controller (and the page listening to it) know whether it's
  /// crying — after the current frame's work, so listeners can rebuild.
  void _tellCrying() {
    final controller = widget.controller;
    if (controller == null) return;
    final crying = _crying;
    Future.microtask(() {
      if (controller._state == this) controller.crying.value = crying;
    });
  }

  // ─── clock ──────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    _lastT = _t;
    _t = elapsed.inMicroseconds / 1e6;
    final dt = (_t - _lastT).clamp(0.0, 0.1);

    if (_t >= _nextBlink) {
      _blinkAt = _t;
      _nextBlink = _rng.nextDouble() < 0.2
          ? _t + 0.28
          : _t + 2.2 + _rng.nextDouble() * 3.5;
    }

    // Gaze: food being dragged > the finger > idle wandering. A hungry
    // pet keeps glancing down at the pantry.
    final hover = _hoverLocal;
    final gaze = _gaze;
    if (hover != null) {
      _lookTarget = _lookVector(hover);
      _lookHoldUntil = _t + 0.6;
    } else if (gaze != null && _t > _lookHoldUntil) {
      // Reading / writing: slow sweep along the line, a quick hop back.
      final sweep = _scan ? ((_t * 0.45) % 1.0) * 2 - 1 : 0.0;
      _lookTarget = gaze + Offset(sweep * 0.45, 0);
    } else if (_t > _lookHoldUntil && _t >= _nextWander) {
      final hungry = widget.mood == CompanionMood.hungry;
      _lookTarget = _rng.nextDouble() < 0.35
          ? Offset.zero
          : Offset(
              (_rng.nextDouble() * 2 - 1) * 0.7,
              hungry && _rng.nextBool()
                  ? 0.9
                  : (_rng.nextDouble() * 2 - 1) * 0.4,
            );
      _nextWander = _t + 1.8 + _rng.nextDouble() * 2.6;
    }
    final k = 1 - math.exp(-dt * 9);
    _pose.look = Offset.lerp(_pose.look, _lookTarget, k)!;

    if (_t >= _nextFidget) {
      _fidgetAt = _t;
      _fidgetKind = _rng.nextInt(2);
      _nextFidget = _t + (_sad ? 10 : 7) + _rng.nextDouble() * 6;
    }

    if (_sleeping && _t >= _nextZzz) {
      _spawnZzz();
      _nextZzz = _t + 1.6;
    }

    if (widget.ownPet && PetHurt.instance.active) _syncHurt();
    if (_rolling) _trackRoll();
    if (_crying) _sobAndTear();

    _particles.removeWhere((p) => _t - p.born > p.life);
    _computePose();
    _dress(dt);
    _syncLoops();
    _frame.value++;
  }

  /// Rolling: turns by however far it has moved across the screen, as a
  /// ball would. Big jumps (the parent putting it back on the other side)
  /// don't count.
  void _trackRoll() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final x = box.localToGlobal(Offset(_w / 2, _groundY)).dx;
    final last = _lastRollX;
    _lastRollX = x;
    if (last == null) return;
    final dx = x - last;
    if (dx.abs() > _s) return;
    _rollAngle += dx / (_s * 0.394 * _scale);
    if (dx.abs() > 0.2) _rollDir = dx.sign;
  }

  /// Crying: a sob every so often (softer, and without a sound, while
  /// it's being petted), and tears spraying out while it wails.
  void _sobAndTear() {
    final soothed = _t - _lastComfort < 0.9;
    if (_t >= _nextSob) {
      _nextSob = _t + 1.8;
      if (!soothed && _eatAt == null && !_happing) _sfx(Sfx.sob);
    }
    final wailing = _t - _cryAt < 1.6;
    if (_t >= _nextTear) {
      _nextTear = _t + (wailing ? 0.07 : 0.55);
      _spawnTear(spray: wailing);
    }
  }

  /// True on the tick where the clock passes [start] + [at]. Ignores
  /// moments skipped by a long frame gap (app resumed, route popped)
  /// so stale dust doesn't pop out seconds late.
  bool _crossed(double? start, double at) {
    if (start == null) return false;
    return _lastT - start < at && _t - start >= at && _t - start - at < 0.1;
  }

  // ─── pose ───────────────────────────────────────────────────────────

  void _computePose() {
    final t = _t;
    final s = _s;
    final p = _pose;
    p
      ..t = t
      ..jump = 0
      ..tilt = 0
      ..shakeX = 0
      ..arm = 0
      ..armRight = -1
      ..armWave = 0
      ..turn = 1
      ..mouthOpen = 0
      ..cheekPuff = 0
      ..eyes = _Eyes.open
      ..mouth = _Mouth.smile
      ..sadBrows = false
      ..expr = null
      ..held = false
      ..egg = _showEgg
      ..crack = 0
      ..food = null
      ..squint = false
      ..bruise = 0
      ..ball = 0
      ..roll = 0
      ..slurp = null;

    // Bruised from a beating: there while it cries, fading a few seconds
    // after it has calmed down.
    final bruisedAt = _bruisedAt;
    if (bruisedAt != null) {
      final grow = ((t - bruisedAt) / 0.2).clamp(0.0, 1.0);
      final fade =
          _crying ? 1.0 : (1 - (t - _calmAt - 4) / 4).clamp(0.0, 1.0);
      p.bruise = grow * fade;
      if (!_crying && fade <= 0) _bruisedAt = null;
    }

    if (p.egg) {
      _eggPose(p, t);
      _spawnScheduled();
      return;
    }

    final sleeping = _sleeping;
    final breathHz = sleeping || _sad ? 0.3 : 0.5;
    p.squash = math.sin(t * 2 * math.pi * breathHz) * (sleeping ? 0.03 : 0.016);

    final bd = t - _blinkAt;
    p.eyeOpen = bd >= 0 && bd < 0.16 ? 1 - math.sin(math.pi * bd / 0.16) : 1;

    if (sleeping) {
      p
        ..eyes = _Eyes.closed
        ..mouth = _Mouth.small
        ..tilt = math.sin(t * 0.6) * 0.04;
    } else if (_sad) {
      // Droops a little wider and lower, brows up, mouth down.
      p
        ..squash += 0.035
        ..sadBrows = true
        ..mouth =
            widget.mood == CompanionMood.hungry ? _Mouth.frown : _Mouth.flat
        ..expr = widget.mood == CompanionMood.hungry
            ? BlobExpression.hungry
            : BlobExpression.sad;
    }
    // A face it was asked to pull sits on top of the mood.
    if (!sleeping) {
      if (t >= _exprUntil) _exprOverride = null;
      p.expr = _exprOverride ?? widget.expression ?? p.expr;
    }

    final fd = t - _fidgetAt;
    if (!sleeping && !_crying && !_busyMoving && fd >= 0 && fd < 1.2) {
      if (_fidgetKind == 0 || _sad) {
        p.tilt += math.sin(math.pi * fd / 1.2) * 0.1;
      } else {
        p.jump += _hop(fd, 0.1, 0.35, s * 0.06);
        p.squash += _impulse(fd, 0.45, 0.08);
      }
    }

    if (!sleeping) _idlePose(p, t, s);

    if (_talking && !sleeping) {
      p
        ..sadBrows = false
        ..mouth = _Mouth.open
        ..mouthOpen = 0.15 + 0.55 * math.sin(t * 11).abs();
    }

    // Walking: steady little hops, leaning and looking where it goes.
    if (_walkDir != 0) {
      final step = (t * 2 * math.pi * 2.0) % (2 * math.pi);
      p
        ..jump += math.sin(step).abs() * s * 0.05
        ..squash += (1 - math.sin(step).abs()) * 0.05
        ..tilt += _walkDir * 0.07
        ..eyes = _Eyes.open
        ..sadBrows = false;
      _lookTarget = Offset(_walkDir * 0.9, 0.05);
      _lookHoldUntil = t + 0.3;
    }

    // Rolling: curled up into a round ball, grinning, turning as it goes —
    // then uncurling with a little hop.
    final ud = t - _unrollAt;
    if (_rolling || (ud >= 0 && ud < 0.45)) {
      final tuck = _rolling
          ? ((t - _rollAt) / 0.25).clamp(0.0, 1.0)
          : 1 - (ud / 0.3).clamp(0.0, 1.0);
      final unroll = Curves.easeOut.transform((ud / 0.3).clamp(0.0, 1.0));
      p
        ..ball = tuck
        ..roll = _rolling
            ? _rollAngle
            : _unrollFrom + (_unrollTo - _unrollFrom) * unroll
        ..expr = null
        ..sadBrows = false
        ..eyes = _Eyes.happy
        ..mouth = _Mouth.open
        ..mouthOpen = 0.5
        ..arm = 0
        ..tilt = 0;
      p.squash = p.squash * (1 - tuck) - 0.063 * tuck;
      if (!_rolling) {
        p.jump += _hop(ud, 0.05, 0.3, s * 0.07);
        p.squash += _impulse(ud, 0.35, 0.1);
      }
    }

    // Food dragged nearby: eyes wide, mouth opening with proximity.
    final hover = _hoverLocal;
    if (hover != null) {
      final mouth = Offset(_w / 2, _groundY - _ry * 0.85);
      final near = 1 - ((hover - mouth).distance / (s * 1.3)).clamp(0.0, 1.0);
      p
        ..sadBrows = false
        ..expr = null
        ..eyes = _Eyes.open
        ..mouth = _Mouth.open
        ..mouthOpen = 0.2 + 0.8 * near
        ..arm = near;
    }

    if (_petAt != null) {
      final d = t - _petAt!;
      if (d < 1.0) {
        p.squash += 0.15 * math.exp(-5 * d) * math.cos(15 * d);
        p.arm = math.max(p.arm, 1 - d);
      }
    }
    if (t < _happyUntil) {
      p
        ..sadBrows = false
        ..expr = null
        ..eyes = _Eyes.happy
        ..mouth = _Mouth.open
        ..mouthOpen = 0.45;
    }

    if (_playAt != null) {
      final d = t - _playAt!;
      if (d < 1.4) {
        if (d < 0.12) p.squash += 0.13 * math.sin(math.pi * d / 0.12);
        p.jump += _hop(d, 0.12, 0.5, s * 0.34) + _hop(d, 0.72, 0.3, s * 0.12);
        p.squash -= 0.08 * _arc(d, 0.12, 0.5) + 0.05 * _arc(d, 0.72, 0.3);
        p.squash += _impulse(d, 0.62, 0.17) + _impulse(d, 1.02, 0.1);
        final q = ((d - 0.12) / 0.5).clamp(0.0, 1.0);
        p.tilt += math.sin(q * 2 * math.pi) * 0.2;
        p
          ..arm = 1
          ..expr = null
          ..eyes = _Eyes.happy
          ..mouth = _Mouth.open
          ..mouthOpen = 0.8;
      }
    }

    // Eat — food flies in, chomp chomp, then the verdict: happy, or (not
    // tasty) a screwed-up face that lasts a little longer.
    if (_eatAt != null) {
      final d = t - _eatAt!;
      if (d < (_eatTasty ? 1.3 : 1.9)) {
        p
          ..sadBrows = false
          ..expr = null;
        if (d < 0.32) {
          p
            ..food = d / 0.32
            ..mouth = _Mouth.open
            ..mouthOpen = (0.5 + d / 0.25).clamp(0.0, 1.0);
          p.squash -= 0.06 * math.sin(math.pi * d / 0.32);
        } else if (d < 0.95) {
          final c = (d - 0.32) / 0.63;
          p
            ..mouth = _Mouth.open
            ..mouthOpen = (math.sin(c * 3 * math.pi)).abs() * 0.55
            ..cheekPuff = 1;
          p.squash += 0.05 * math.sin(c * 6 * math.pi);
        } else if (_eatTasty) {
          p
            ..cheekPuff = 1 - (d - 0.95) / 0.35
            ..eyes = _Eyes.happy
            ..mouth = _Mouth.smile;
        } else {
          p
            ..cheekPuff = math.max(0, 1 - (d - 0.95) / 0.2)
            ..eyes = _Eyes.open
            ..expr = BlobExpression.yuck;
          p.squash -= 0.03 * _arc(d, 0.95, 0.35);
        }
      }
    }

    // A burp: cheeks fill up, "burp!" with a little hop, then a pleased
    // pat on the tummy.
    if (_burpAt != null) {
      final d = t - _burpAt!;
      if (d < 1.3) {
        p
          ..sadBrows = false
          ..expr = null;
        if (d < 0.45) {
          final q = d / 0.45;
          p
            ..cheekPuff = q
            ..mouth = _Mouth.flat
            ..eyes = _Eyes.open;
          p.squash += 0.05 * q;
        } else if (d < 0.75) {
          final q = (d - 0.45) / 0.3;
          p
            ..mouth = _Mouth.open
            ..mouthOpen = 0.6 * math.sin(math.pi * q)
            ..eyes = _Eyes.closed;
          p.squash -= 0.07 * math.sin(math.pi * q);
          p.jump += _hop(d, 0.45, 0.25, s * 0.05);
        } else {
          p
            ..eyes = _Eyes.happy
            ..mouth = _Mouth.smile
            ..arm = math.max(p.arm, 0.4);
        }
      }
    }

    // Hap: a crouch, a spring up with the mouth wide open (the mosquito
    // gets slurped in), snap — land, chew, gulp, pleased.
    if (_happing) {
      final d = t - _hapAt!;
      p
        ..expr = null
        ..sadBrows = false
        ..arm = 0;
      if (d < 0.18) {
        p
          ..mouth = _Mouth.small
          ..slurp = 0;
        p.squash += 0.09 * d / 0.18;
        final from = _hapFrom;
        if (from != null) {
          _lookTarget = _lookVector(from);
          _lookHoldUntil = t + 0.2;
        }
      } else if (d < 0.78) {
        p.jump += _hop(d, 0.18, 0.6, s * 0.42);
        p.squash -= 0.07 * _arc(d, 0.18, 0.6);
        p.arm = 1;
        if (d < 0.5) {
          p
            ..mouth = _Mouth.gape
            ..mouthOpen = ((d - 0.18) / 0.1).clamp(0.0, 1.0)
            ..squint = true
            ..slurp = ((d - 0.2) / 0.3).clamp(0.0, 1.0);
        } else {
          p
            ..mouth = _Mouth.flat
            ..cheekPuff = 1
            ..eyes = _Eyes.happy;
        }
      } else {
        final c = d - 0.78;
        p.squash += _impulse(c, 0, 0.14);
        if (d < 1.35) {
          p
            ..cheekPuff = 1
            ..mouth = _Mouth.flat
            ..eyes = _Eyes.happy;
          p.squash += 0.04 * math.sin(c * 6 * math.pi);
        } else {
          final g = d - 1.35;
          p
            ..cheekPuff = math.max(0, 1 - g / 0.15)
            ..eyes = _Eyes.happy
            ..mouth = _Mouth.smile;
          p.squash += _impulse(g, 0, 0.06);
        }
      }
    }

    // In tears: a wail first, then sobbing — gentler while it's being
    // petted, and the more comfort it has had. (Eating still gets its
    // full attention.)
    final eating =
        _eatAt != null && t - _eatAt! < (_eatTasty ? 1.3 : 1.9);
    if (_crying && !eating && !_happing) {
      final d = t - _cryAt;
      final soothed = t - _lastComfort < 0.9;
      final calm = soothed ? 0.4 + 0.6 * _comfort / _comfortNeeded : 0.0;
      p
        ..expr = BlobExpression.crying
        ..eyes = _Eyes.open
        ..sadBrows = true
        ..cheekPuff = 0
        ..arm = 0;
      if (d < 1.6) {
        // "Waaah!": a gulp of air, then the mouth wide and shaking.
        p.squash += _impulse(d, 0, 0.14) - 0.04 * _arc(d, 0.1, 1.5);
        p.shakeX += math.sin(t * 55) * s * 0.007;
        p
          ..mouthOpen = 0.85 + 0.15 * math.sin(t * 24)
          ..squint = true;
      } else {
        // Sobbing: a hiccup every so often, the mouth wobbling. It looks
        // up at you, eyes swimming, while you pet it.
        final sd = (d - 1.6) % 1.8;
        final k = 1 - calm * 0.75;
        p.squash += _impulse(sd, 0, 0.1 * k);
        p.jump += _hop(sd, 0, 0.2, s * 0.03 * k);
        p.shakeX += math.sin(t * 40) * s * 0.003 * k;
        p
          ..mouthOpen = (0.3 + 0.3 * math.sin(t * 8).abs()) * k
          ..squint = !soothed;
      }
      p.tilt += math.sin(t * 1.7) * 0.03;
    }

    // Comforted: a couple of sniffles, then a smile.
    final cd = t - _calmAt;
    if (!_crying && cd >= 0 && cd < 1.8) {
      p
        ..expr = null
        ..sadBrows = false;
      if (cd < 0.8) {
        p
          ..eyes = _Eyes.closed
          ..mouth = _Mouth.small;
        p.squash += _impulse(cd, 0.1, 0.06) + _impulse(cd, 0.45, 0.06);
      } else {
        p
          ..eyes = _Eyes.happy
          ..mouth = _Mouth.smile;
      }
    }

    if (_shakeAt != null) {
      final d = t - _shakeAt!;
      if (d < 0.7) {
        final fall = 1 - d / 0.7;
        p.shakeX = s * 0.05 * math.sin(d / 0.7 * 6 * math.pi) * fall;
        p.tilt += p.shakeX / s * 0.9;
        p
          ..mouth = _Mouth.flat
          ..eyes = _Eyes.open;
      }
    }

    if (_celebrateAt != null) {
      final d = t - _celebrateAt!;
      if (d < 1.6) {
        p.jump += _hop(d, 0.0, 0.42, s * 0.2) + _hop(d, 0.5, 0.42, s * 0.2);
        p.squash += _impulse(d, 0.42, 0.12) + _impulse(d, 0.92, 0.12);
        p
          ..sadBrows = false
          ..expr = null
          ..arm = 1
          ..eyes = _Eyes.happy
          ..mouth = _Mouth.open
          ..mouthOpen = 0.7;
      }
    }

    // Just hatched: big "boing" out of the shell.
    if (_hatchAt != null) {
      final d = t - _hatchAt! - _hatchPop;
      if (d >= 0 && d < 1.2) {
        p.squash += _impulse(d, 0, 0.3);
        p
          ..expr = null
          ..eyes = _Eyes.happy
          ..mouth = _Mouth.open
          ..mouthOpen = 0.6
          ..arm = 1;
      }
    }

    // Held up in the air: stretched, feet dangling, arms flailing, eyes
    // on the floor far below.
    if (_held || _falling) {
      final shaken = _held && t < _shakenUntil;
      p
        ..held = true
        ..expr = shaken
            ? BlobExpression.dizzy
            : t - _heldAt < 0.3
                ? BlobExpression.surprised
                : BlobExpression.scared
        ..eyes = _Eyes.open
        ..arm = 0.7 + 0.3 * math.sin(t * 14).abs()
        // Shaken about: it wobbles all over.
        ..tilt = math.sin(t * (shaken ? 22 : 3)) * (shaken ? 0.16 : 0.06);
      p.squash -= 0.05;
      _lookTarget = const Offset(0, 0.85);
      _lookHoldUntil = t + 0.2;
    }

    // Back on the floor: a bump, then dizzy and/or sulking.
    final landAt = _landAt;
    if (landAt != null) {
      final d = t - landAt;
      p.squash += _impulse(d, 0, _landHard ? 0.3 : 0.15);
      p.jump += _hop(d, 0.1, 0.3, s * (_landHard ? 0.08 : 0.04));
      final face = _landingExpr(t);
      // A face it was asked to pull (see [BlobController.express]) cuts
      // the sulk short.
      if (face != null && _exprOverride == null) {
        p
          ..expr = face
          ..eyes = _Eyes.open
          ..arm = 0;
        if (face == BlobExpression.angry) {
          // "Hmph" — looks away from you.
          _lookTarget = const Offset(-0.8, -0.15);
          _lookHoldUntil = t + 0.2;
        }
      } else if (d > 1) {
        _landAt = null;
      }
    }

    // Smacked: squashed by the hit, leaning away from it, eyes screwed
    // shut — then the sulk (its angry face) takes over.
    final bd2 = t - _bonkAt;
    if (bd2 >= 0 && bd2 < 0.4) {
      final hit = 1 - bd2 / 0.4;
      p
        ..squash += 0.16 * math.exp(-8 * bd2) * math.cos(18 * bd2)
        ..tilt -= _bonkSide * 0.16 * hit
        ..shakeX += math.sin(bd2 * 70) * s * 0.01 * hit
        ..eyes = _Eyes.closed
        ..mouth = _Mouth.wavy;
    }

    // Poked somewhere quiet: a startled jolt.
    final pd = t - _pokeAt;
    if (pd >= 0 && pd < 0.4) {
      p.jump += _hop(pd, 0, 0.26, s * 0.05);
      p.squash += _impulse(pd, 0.26, 0.1);
    }

    if (p.expr != null) _shapeExpression(p, t, s);
    if (bd2 >= 0 && bd2 < 0.4) p.mouth = _Mouth.wavy;

    _spawnScheduled();
  }

  void _idlePose(_Pose p, double t, double s) {
    final move = _idle;
    if (move == null) return;
    final d = t - _idleAt;
    if (d < 0 || d >= _secs(BlobController.idleLength(move))) {
      _idle = null;
      return;
    }
    switch (move) {
      case BlobIdle.stretch:
        // Crouch, reach up with a big yawn, shake it off.
        final up = _arc(d, 0.45, 1.25);
        p.squash += _arc(d, 0, 0.45) * 0.06 - up * 0.11;
        p.jump += up * s * 0.02;
        p.arm = math.max(p.arm, up);
        if (d > 0.6 && d < 1.6) {
          p
            ..eyes = _Eyes.closed
            ..mouth = _Mouth.open
            ..mouthOpen = 0.35 + 0.55 * _arc(d, 0.6, 1.0);
        }
        if (d > 1.7) {
          final q = (d - 1.7) / 0.7;
          p.shakeX += math.sin(q * 6 * math.pi) * s * 0.012 * (1 - q);
        }
      case BlobIdle.wave:
        final len = _secs(BlobController.idleLength(move));
        final up = math.min(1.0, d / 0.25) * math.min(1.0, (len - d) / 0.25);
        p
          ..eyes = _Eyes.happy
          ..mouth = _Mouth.open
          ..mouthOpen = 0.3
          ..armRight = 1.3 * up
          ..armWave = math.sin(d * 13) * 0.45 * up
          ..tilt += 0.06 * up;
        _lookTarget = Offset.zero;
        _lookHoldUntil = t + 0.2;
      case BlobIdle.dance:
        const beat = 0.35;
        final b = (d / beat).floor();
        final f = (d % beat) / beat;
        final bounce = math.sin(f * math.pi);
        p
          ..jump += bounce * s * 0.05
          ..squash += (1 - bounce) * 0.03
          ..tilt += (b.isEven ? 1 : -1) * 0.14 * bounce
          ..eyes = _Eyes.happy
          ..mouth = _Mouth.open
          ..mouthOpen = 0.45
          ..arm = math.max(p.arm, 0.4 + 0.6 * bounce);
      case BlobIdle.hum:
        // Two verses: swaying to the first, then bouncing along to the
        // second with its arms out, a big smile to finish.
        p
          ..tilt += math.sin(d * 2.6) * 0.08
          ..eyes = _Eyes.happy
          ..mouth = _Mouth.small;
        if (d > 3.4) {
          final beat = math.sin((d - 3.4) * 5.2).abs();
          final fade = ((6.8 - d) / 0.4).clamp(0.0, 1.0);
          p
            ..jump += beat * s * 0.03 * fade
            ..arm = math.max(p.arm, 0.5 * fade)
            ..mouth = d > 6.1 ? _Mouth.open : _Mouth.small
            ..mouthOpen = d > 6.1 ? 0.5 : 0;
        }
      case BlobIdle.doze:
        if (d < 2.4) {
          // Eyelids droop, the head nods twice.
          final q = d / 2.4;
          p
            ..eyeOpen = math.max(0.0, 1 - q * 1.25)
            ..mouth = _Mouth.small;
          p.squash +=
              0.04 * q + _impulse(d, 1.2, 0.05) + _impulse(d, 1.9, 0.06);
        } else if (d < 2.9) {
          p.expr = BlobExpression.surprised;
          p.jump += _hop(d, 2.4, 0.35, s * 0.08);
        } else {
          p.eyes = _Eyes.happy;
        }
      case BlobIdle.spin:
        final q = Curves.easeInOut.transform((d / 1.0).clamp(0.0, 1.0));
        p
          ..turn = math.cos(q * 2 * math.pi)
          ..eyes = _Eyes.happy;
        p.jump += _hop(d, 0, 1.0, s * 0.07);
        p.squash += _impulse(d, 1.0, 0.1);
      case BlobIdle.lookAround:
        final at = d < 0.9
            ? const Offset(-0.9, -0.15)
            : d < 1.8
                ? const Offset(0.9, -0.2)
                : d < 2.4
                    ? const Offset(0.15, -0.85)
                    : Offset.zero;
        _lookTarget = at;
        _lookHoldUntil = t + 0.2;
        p.tilt += at.dx * 0.05;
      case BlobIdle.sneeze:
        if (d < 0.75) {
          final q = d / 0.75;
          p
            ..squash += 0.07 * q
            ..tilt -= 0.06 * q
            ..eyes = _Eyes.closed
            ..mouth = _Mouth.small;
        } else if (d < 1.0) {
          p
            ..squash -= 0.12 * math.sin(math.pi * (d - 0.75) / 0.25)
            ..tilt += 0.1
            ..shakeX += math.sin((d - 0.75) * 60) * s * 0.01
            ..eyes = _Eyes.closed
            ..mouth = _Mouth.open
            ..mouthOpen = 0.9;
        } else {
          p.expr = BlobExpression.surprised;
        }
    }
  }

  /// Body language and mouth for the face in [_Pose.expr]; the eyes,
  /// brows and extras (tears, anger mark…) are drawn by the painter.
  void _shapeExpression(_Pose p, double t, double s) {
    final talking = _talking;
    void mouth(_Mouth m, [double open = 0]) {
      if (talking) return;
      p
        ..mouth = m
        ..mouthOpen = open;
    }

    switch (p.expr!) {
      case BlobExpression.serious:
        p.sadBrows = false;
        mouth(_Mouth.flat);
      case BlobExpression.angry:
        p
          ..sadBrows = false
          ..cheekPuff = math.max(p.cheekPuff, 0.6)
          ..shakeX += math.sin(t * 48) * s * 0.004;
        mouth(_Mouth.frown);
      case BlobExpression.sad:
        p.sadBrows = true;
        mouth(_Mouth.frown);
      case BlobExpression.hungry:
        p.sadBrows = true;
        mouth(_Mouth.open, 0.1);
        // Tummy rumbles every few seconds.
        final r = t % 4.0;
        if (r < 0.45) {
          p.shakeX += math.sin(r * 70) * s * 0.008 * (1 - r / 0.45);
        }
      case BlobExpression.scared:
        p
          ..sadBrows = true
          ..shakeX += math.sin(t * 60) * s * 0.006;
        mouth(_Mouth.wavy);
      case BlobExpression.dizzy:
        p
          ..sadBrows = false
          ..tilt += math.sin(t * 5) * 0.1;
        mouth(_Mouth.wavy);
      case BlobExpression.surprised:
        p.sadBrows = false;
        mouth(_Mouth.small);
      case BlobExpression.smirk:
        // Chin up, leaning back a touch, looking right at you.
        p
          ..sadBrows = false
          ..tilt -= 0.06;
        mouth(_Mouth.grin);
        _lookTarget = const Offset(0.1, -0.05);
        _lookHoldUntil = t + 0.2;
      case BlobExpression.yuck:
        p
          ..sadBrows = true
          ..shakeX += math.sin(t * 52) * s * 0.005;
        mouth(_Mouth.wavy);
      case BlobExpression.crying:
        p.sadBrows = true;
        mouth(_Mouth.wail, p.mouthOpen);
    }
  }

  void _eggPose(_Pose p, double t) {
    // Idle: a slow rock every few seconds, as if something inside moves.
    final rock = math.sin(t * 1.3);
    p.tilt = rock > 0.85 ? math.sin(t * 14) * 0.05 : 0;
    if (_petAt != null) {
      final d = t - _petAt!;
      if (d < 0.8) p.tilt += math.sin(d * 20) * 0.1 * (1 - d / 0.8);
    }
    if (_hatchAt != null) {
      final d = t - _hatchAt!;
      if (d < _hatchFeed) p.food = d / _hatchFeed;
      if (d >= _hatchFeed) {
        final k = ((d - _hatchFeed) / (_hatchPop - _hatchFeed)).clamp(0.0, 1.0);
        p
          ..tilt += math.sin(d * 32) * 0.14 * k
          ..crack = k
          ..squash = 0.04 * math.sin(d * 18) * k;
      }
    }
  }

  void _spawnScheduled() {
    switch (_idle) {
      case BlobIdle.dance:
        if (_crossed(_idleAt, 0.35) ||
            _crossed(_idleAt, 1.05) ||
            _crossed(_idleAt, 1.75)) {
          _spawnNote();
        }
      case BlobIdle.hum:
        for (final at in [0.4, 1.2, 2.0, 2.8, 3.8, 4.4, 5.0, 5.6, 6.2]) {
          if (_crossed(_idleAt, at)) _spawnNote();
        }
        // The second verse (only if it's still singing).
        if (_crossed(_idleAt, 3.5)) _sfx(Sfx.hum);
      case BlobIdle.doze:
        if (_crossed(_idleAt, 1.4)) _spawnZzz();
      case BlobIdle.sneeze:
        if (_crossed(_idleAt, 0.78)) _spawnDust();
      default:
        break;
    }
    if (_crossed(_playAt, 0.62) || _crossed(_playAt, 1.02)) _spawnDust();
    // Each little hop of a walk lands with a soft step.
    if (_walkDir != 0 && (_t * 4).floor() != (_lastT * 4).floor()) {
      _sfx(Sfx.step);
    }
    if (_crossed(_celebrateAt, 0.42) || _crossed(_celebrateAt, 0.92)) {
      _spawnDust();
    }
    if (_crossed(_eatAt, 0.95)) {
      if (_eatTasty) {
        _spawnHearts(3);
      } else {
        _sfx(Sfx.yuck);
      }
    }
    // Chewing starts once the food is in.
    if (_crossed(_eatAt, 0.32)) _sfx(_eatSnack ? Sfx.snack : Sfx.eat);
    if (_crossed(_burpAt, 0.47)) {
      _spawnPuff();
      _sfx(Sfx.burp);
      _haptic(HapticFeedback.lightImpact);
    }
    if (_crossed(_playAt, 0.62)) _haptic(HapticFeedback.lightImpact);
    if (_crossed(_hapAt, 0.5)) _haptic(HapticFeedback.lightImpact);
    if (_crossed(_hapAt, 0.78)) _spawnDust();
    if (_crossed(_hapAt, 1.35)) _sfx(Sfx.gulp);
    if (_crossed(_unrollAt, 0.35)) _spawnDust();
    if (_crossed(_hatchAt, _hatchFeed)) _sfx(Sfx.eggCrack);
    if (_crossed(_hatchAt, _hatchPop)) {
      _sfx(Sfx.hatchPop);
      _spawnShells();
      _spawnStars(8);
      _haptic(HapticFeedback.heavyImpact);
    }
  }

  static double _hop(double d, double start, double dur, double h) {
    final q = (d - start) / dur;
    if (q <= 0 || q >= 1) return 0;
    return h * math.sin(math.pi * q);
  }

  static double _arc(double d, double start, double dur) {
    final q = (d - start) / dur;
    if (q <= 0 || q >= 1) return 0;
    return math.sin(math.pi * q);
  }

  /// Landing squash: a quick damped bounce starting at [at].
  static double _impulse(double d, double at, double amp) {
    final x = d - at;
    if (x < 0 || x > 0.6) return 0;
    return amp * math.exp(-7 * x) * math.cos(16 * x);
  }

  // ─── reactions ──────────────────────────────────────────────────────

  void _wake() => _wakeUntil = _t + 5;

  void _pet(Offset? at, {bool stroke = false}) {
    if (_busyMoving) return;
    if (_crying) {
      _soothe(at);
      return;
    }
    // Still dizzy or sulking from being dropped: no cuddles just now.
    if (_landingExpr(_t) != null) {
      if (_t - _pokeAt > 0.5) _pokeAt = _t;
      _haptic(HapticFeedback.selectionClick);
      _sfx(Sfx.grumpy);
      return;
    }
    if (widget.touchy && !_showEgg) {
      _poke(stroke: stroke);
      return;
    }
    _wake();
    _idle = null;
    _petAt = _t;
    if (!_showEgg) _happyUntil = _t + 1.1;
    if (at != null) _lookTarget = _lookVector(at);
    _lookHoldUntil = _t + 1.4;
    if (_t - _lastPetParticle > 0.12) {
      _spawnHearts(stroke ? 1 : 2);
      _lastPetParticle = _t;
    }
    _haptic(HapticFeedback.selectionClick);
    // An egg just gets a little knock.
    _showEgg ? _sfx(Sfx.eggTap) : _sfx(Sfx.pet);
    widget.onPet?.call();

    if (stroke && !_showEgg) {
      _recentStrokes
        ..add(_t)
        ..removeWhere((x) => _t - x > 2.5);
      if (_recentStrokes.length >= 7) {
        _recentStrokes.clear();
        _play();
        widget.onPlay?.call();
      }
    }
  }

  /// Tapped: a smack. It winces away from where it was hit, then sulks —
  /// longer after a few in a row. Keep on and it bursts into tears (see
  /// [_cry]). An egg just rocks.
  void _bonk(Offset? at) {
    if (_busyMoving) return;
    if (_showEgg || widget.touchy || _landingExpr(_t) != null) {
      _pet(at);
      return;
    }
    _wake();
    _idle = null;
    _happyUntil = -1;
    _petAt = null;
    _bonkAt = _t;
    _bonkSide =
        at == null ? 0 : ((at.dx - _w / 2) / math.max(1, _rx)).clamp(-1.0, 1.0);
    _recentBonks
      ..add(_t)
      ..removeWhere((x) => _t - x > 4);
    final run = _recentBonks.length;
    _spawnImpact(at);
    _sfx(Sfx.hit);
    if (_crying || run >= BlobController.cryAfter) {
      _cry();
    } else {
      _express(BlobExpression.angry,
          Duration(milliseconds: run >= 3 ? 2800 : 1700));
      _lookTarget = Offset.zero;
      _lookHoldUntil = _t + 1.6;
      _haptic(HapticFeedback.mediumImpact);
      _sfx(Sfx.ouch, delay: 0.12);
      if (run >= 3) _sfx(Sfx.grumpy, delay: 0.7);
    }
    widget.onBonk?.call(run);
  }

  /// One smack too many: bruised (a black eye, a bump, a plaster) it
  /// bursts into tears, and keeps crying until it's been petted for a
  /// while. Another smack sets it off again.
  void _cry() {
    _idle = null;
    _exprOverride = null;
    _comfort = 0;
    _cryAt = _t;
    _nextSob = _t + 1.6;
    if (!_crying) {
      _crying = true;
      _bruisedAt = _t;
      _calmAt = -10;
      widget.controller?.crying.value = true;
    }
    _haptic(HapticFeedback.heavyImpact);
    _sfx(Sfx.wail, delay: 0.15);
    if (widget.ownPet) PetHurt.instance.cry(DateTime.now());
  }

  /// Petted while crying: it calms down bit by bit — the sobs get softer —
  /// and after enough strokes it sniffles, smiles and stops. Petting has
  /// to keep going: leave it a few seconds and it's back to square one.
  void _soothe(Offset? at) {
    if (_t - _lastComfort > 5) _comfort = 0;
    _comfort++;
    _lastComfort = _t;
    _petAt = _t;
    if (at != null) _lookTarget = _lookVector(at);
    _lookHoldUntil = _t + 1.4;
    _haptic(HapticFeedback.selectionClick);
    widget.onPet?.call();
    if (_comfort < _comfortNeeded) {
      if (widget.ownPet) PetHurt.instance.soothe(DateTime.now(), _comfort);
      return;
    }
    _crying = false;
    _calmAt = _t;
    _comfort = 0;
    _recentBonks.clear();
    _spawnHearts(3);
    _sfx(Sfx.sniffle);
    widget.controller?.crying.value = false;
    if (widget.ownPet) PetHurt.instance.calm(DateTime.now());
  }

  /// Touched somewhere quiet: jumps, glares at you and grumbles.
  void _poke({required bool stroke}) {
    _wake();
    if (!stroke || _t - _pokeAt > 0.8) _pokeAt = _t;
    _express(BlobExpression.angry, const Duration(milliseconds: 1800));
    _lookTarget = Offset.zero;
    _lookHoldUntil = _t + 1.6;
    _haptic(HapticFeedback.lightImpact);
    _sfx(Sfx.shush);
    widget.onPet?.call();
  }

  void _startIdle(BlobIdle move) {
    if (_showEgg ||
        _held ||
        _falling ||
        _landAt != null ||
        _crying ||
        _busyMoving) {
      return;
    }
    _wake();
    _idle = move;
    _idleAt = _t;
    // Lined up with the moves: the yawn as the mouth opens, the "chiu!" on
    // the sneeze, the startle as it jolts awake.
    switch (move) {
      case BlobIdle.stretch:
        _sfx(Sfx.yawn, delay: 0.5);
      case BlobIdle.sneeze:
        _sfx(Sfx.sneeze, delay: 0.25);
      case BlobIdle.doze:
        _sfx(Sfx.dozeStartle, delay: 0.3);
      case BlobIdle.hum:
        _sfx(Sfx.hum);
      case BlobIdle.dance:
        _sfx(Sfx.dance);
      case BlobIdle.spin:
        _sfx(Sfx.spin);
      case BlobIdle.wave:
        _sfx(Sfx.wave, delay: 0.1);
      case BlobIdle.lookAround:
        break;
    }
  }

  void _beam(Duration duration) {
    _wake();
    _happyUntil = _t + _secs(duration);
  }

  void _express(BlobExpression? e, Duration? duration) {
    _exprOverride = e;
    _exprUntil =
        e == null || duration == null ? double.infinity : _t + _secs(duration);
    if (e != null && e != BlobExpression.serious) _wake();
  }

  void _liftStart(Offset global) {
    if (_showEgg || _held || _crying || _busyMoving) return;
    _idle = null;
    _held = true;
    _falling = false;
    _heldAt = _t;
    _landAt = null;
    _lastLift = global;
    _swingTravel.fillRange(0, 2, 0);
    _swingDir.fillRange(0, 2, 0);
    _swings.clear();
    _happyUntil = -1;
    _petAt = null;
    _recentStrokes.clear();
    _wake();
    _haptic(HapticFeedback.mediumImpact);
    _sfx(Sfx.lift);
    widget.onLift?.call();
  }

  void _liftMove(Offset global) {
    if (!_held) return;
    final last = _lastLift ?? global;
    _lastLift = global;
    _trackShake(global - last);
    widget.onCarry?.call(global - last);
  }

  /// Counts the turns of a back-and-forth (either way): each time the
  /// finger reverses after a real swing. A few quick turns in a row is a
  /// shake.
  void _trackShake(Offset d) {
    final swing = _s * 0.12;
    for (var axis = 0; axis < 2; axis++) {
      final v = axis == 0 ? d.dx : d.dy;
      if (v.abs() < 0.5) continue;
      final dir = v > 0 ? 1 : -1;
      if (dir != _swingDir[axis]) {
        if (_swingDir[axis] != 0 && _swingTravel[axis] >= swing) _swingTurn();
        _swingDir[axis] = dir;
        _swingTravel[axis] = 0;
      }
      _swingTravel[axis] += v.abs();
    }
  }

  void _swingTurn() {
    _swings
      ..add(_t)
      ..removeWhere((at) => _t - at > 1.0);
    if (_swings.length < 3) return;
    _shakenUntil = _t + 0.5;
    widget.onShaken?.call();
  }

  void _liftEnd() {
    if (!_held) return;
    _held = false;
    _lastLift = null;
    if (widget.onDrop == null) {
      _land(false);
    } else {
      _falling = true;
      widget.onDrop!.call();
    }
  }

  void _land(bool hard) {
    _held = false;
    _falling = false;
    _landAt = _t;
    _landHard = hard;
    _spawnDust();
    _haptic(hard ? HapticFeedback.heavyImpact : HapticFeedback.lightImpact);
    _sfx(Sfx.land, volume: hard ? 1 : 0.6);
    if (hard) {
      _sfx(Sfx.dizzy, delay: 0.15);
      _sfx(Sfx.grumpy, delay: _secs(BlobController.dizzyFor));
    } else {
      _sfx(Sfx.grumpy, delay: 0.35);
    }
  }

  void _play() {
    if (_showEgg || widget.touchy || _crying) return;
    _wake();
    _playAt = _t;
    _happyUntil = _t + 1.5;
    _spawnStars(6);
    _haptic(HapticFeedback.mediumImpact);
    _sfx(Sfx.happyJump, delay: 0.1);
  }

  void _eat(FoodKind food, Offset? fromGlobal,
      {bool tasty = true, bool snack = false}) {
    _wake();
    _idle = null;
    _burpAt = null;
    _eatTasty = tasty;
    _eatSnack = snack;
    _food = food;
    _foodFrom = _toLocal(fromGlobal);
    _hoverLocal = null;
    _eatAt = _t;
    _lookTarget = const Offset(0.1, 0.9);
    _lookHoldUntil = _t + 0.35;
  }

  void _hatch(FoodKind food, Offset? fromGlobal) {
    _food = food;
    _foodFrom = _toLocal(fromGlobal);
    _hoverLocal = null;
    _hatchAt = _t;
    _wake();
  }

  void _hover(Offset? global) => _hoverLocal = _toLocal(global);

  void _burp() {
    if (_showEgg || _held || _falling) return;
    _wake();
    _idle = null;
    _burpAt = _t;
  }

  void _shake() {
    _wake();
    _shakeAt = _t;
    _hoverLocal = null;
    _haptic(HapticFeedback.heavyImpact);
  }

  void _roll(bool on) {
    if (on) {
      if (_showEgg || _held || _falling || _crying) return;
      _sfx(Sfx.roll);
      if (_rolling) return;
      _wake();
      _idle = null;
      _rolling = true;
      _rollAt = _t;
      _rollAngle = 0;
      _lastRollX = null;
      _happyUntil = -1;
      _petAt = null;
      return;
    }
    if (!_rolling) return;
    _rolling = false;
    _unrollAt = _t;
    // Rolls on to the next time it's the right way up, in the direction
    // it was going — unless that's most of a turn away.
    const turn = 2 * math.pi;
    final ahead = _rollDir > 0
        ? (_rollAngle / turn).ceilToDouble() * turn
        : (_rollAngle / turn).floorToDouble() * turn;
    _unrollFrom = _rollAngle;
    _unrollTo = (ahead - _rollAngle).abs() > math.pi * 1.2
        ? (_rollAngle / turn).roundToDouble() * turn
        : ahead;
    _sfx(Sfx.land, volume: 0.5, delay: 0.35);
  }

  void _hap(Offset? fromGlobal) {
    if (_showEgg || _held || _falling || _crying || _rolling) return;
    _wake();
    _idle = null;
    _exprOverride = null;
    _happyUntil = -1;
    _petAt = null;
    _eatAt = null;
    _burpAt = null;
    _hapAt = _t;
    _hapFrom = _toLocal(fromGlobal);
    _sfx(Sfx.hap, delay: 0.18);
  }

  void _celebrate(Sfx sound) {
    _wake();
    _idle = null;
    _celebrateAt = _t;
    _happyUntil = _t + 1.8;
    _spawnStars(8);
    _spawnHearts(2);
    _sfx(sound);
  }

  void _haptic(Future<void> Function() fn) {
    if (widget.interactive) fn();
  }

  Offset? _toLocal(Offset? global) {
    if (global == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    return box?.hasSize == true ? box!.globalToLocal(global) : null;
  }

  Offset _lookVector(Offset local) {
    final c = Offset(_w / 2, _groundY - _ry);
    final v = (local - c) / (_s * 0.6);
    return Offset(v.dx.clamp(-1.0, 1.0), v.dy.clamp(-1.0, 1.0));
  }

  // ─── particles ──────────────────────────────────────────────────────

  Offset get _headTop => Offset(
        _w / 2 + _pose.shakeX,
        _groundY - _pose.jump - 2 * _ry * (1 - _pose.squash),
      );

  /// Puts its jacket on (or takes it off) over a moment.
  void _dress(double dt) {
    final to = widget.jacket ? 1.0 : 0.0;
    _jacket += (to - _jacket) * (1 - math.exp(-dt * 6));
    if ((_jacket - to).abs() < 0.002) _jacket = to;
    _pose.jacket = _jacket;
  }

  void _spawnHearts(int n) {
    final top = _headTop;
    for (var i = 0; i < n; i++) {
      _particles.add(_Particle(
        kind: _PKind.heart,
        origin:
            top + Offset((_rng.nextDouble() * 2 - 1) * _rx * 0.7, _s * 0.08),
        velocity: Offset(
            (_rng.nextDouble() * 2 - 1) * 18, -55 - _rng.nextDouble() * 30),
        born: _t,
        life: 1.1 + _rng.nextDouble() * 0.4,
        scale: 0.8 + _rng.nextDouble() * 0.5,
      ));
    }
  }

  /// Fan of sparkles bursting up and out from just above the head, so
  /// they never sit on top of the face.
  void _spawnStars(int n) {
    final c = _headTop + Offset(0, _s * 0.02);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 +
          (i / (n - 1) - 0.5) * math.pi * 1.1 +
          (_rng.nextDouble() - 0.5) * 0.25;
      final sp = 90 + _rng.nextDouble() * 60;
      final dir = Offset(math.cos(a), math.sin(a));
      _particles.add(_Particle(
        kind: _PKind.star,
        origin: c + Offset(dir.dx * _rx * 0.6, dir.dy * _s * 0.05),
        velocity: dir * sp,
        born: _t,
        life: 0.9,
        spin: (_rng.nextDouble() * 2 - 1) * 4,
        scale: 0.7 + _rng.nextDouble() * 0.6,
      ));
    }
  }

  void _spawnShells() {
    final c = Offset(_w / 2, _groundY - _s * 0.25);
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (i / 5 - 0.5) * math.pi * 1.4;
      _particles.add(_Particle(
        kind: _PKind.shell,
        origin: c,
        velocity:
            Offset(math.cos(a), math.sin(a)) * (110 + _rng.nextDouble() * 50),
        born: _t,
        life: 0.8,
        spin: (_rng.nextDouble() * 2 - 1) * 8,
        scale: 0.7 + _rng.nextDouble() * 0.5,
      ));
    }
  }

  /// A little cloud puffing out of the mouth (a burp).
  void _spawnPuff() {
    final mouth = Offset(_w / 2, _groundY - _ry * 0.85);
    for (final (dx, scale) in [(-0.6, 0.8), (0.3, 1.0), (0.9, 0.65)]) {
      _particles.add(_Particle(
        kind: _PKind.puff,
        origin: mouth + Offset(dx * _s * 0.05, 0),
        velocity: Offset(dx * 34, -70 - _rng.nextDouble() * 20),
        born: _t,
        life: 1.1,
        scale: scale,
      ));
    }
  }

  void _spawnDust() {
    for (final dir in [-1.0, 1.0]) {
      _particles.add(_Particle(
        kind: _PKind.dust,
        origin: Offset(_w / 2 + dir * _rx * 0.8, _groundY - _s * 0.02),
        velocity: Offset(dir * 40, -8),
        born: _t,
        life: 0.5,
      ));
    }
  }

  void _spawnImpact(Offset? at) {
    final c = at ?? _headTop + Offset(0, _s * 0.1);
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + (i / 3 - 0.5) * math.pi * 1.2;
      _particles.add(_Particle(
        kind: _PKind.star,
        origin: c,
        velocity:
            Offset(math.cos(a), math.sin(a)) * (70 + _rng.nextDouble() * 40),
        born: _t,
        life: 0.5,
        spin: (_rng.nextDouble() * 2 - 1) * 5,
        scale: 0.5 + _rng.nextDouble() * 0.3,
      ));
    }
  }

  void _spawnNote() {
    final dir = _rng.nextBool() ? 1.0 : -1.0;
    _particles.add(_Particle(
      kind: _PKind.note,
      origin: _headTop + Offset(dir * _rx * 0.6, _s * 0.04),
      velocity: Offset(dir * 12, -34),
      born: _t,
      life: 1.4,
      scale: 0.85 + _rng.nextDouble() * 0.4,
    ));
  }

  /// A tear: sprayed out sideways from an eye while it wails, or dripping
  /// off its cheek while it sobs.
  void _spawnTear({required bool spray}) {
    final dir = _rng.nextBool() ? 1.0 : -1.0;
    final face = _headTop + Offset(0, _ry * 0.92);
    final eye = face + Offset(dir * _s * 0.12 * _scale, 0);
    _particles.add(_Particle(
      kind: _PKind.tear,
      origin: spray
          ? eye
          : face + Offset(dir * _s * 0.13 * _scale, _s * 0.14 * _scale),
      velocity: spray
          ? Offset(dir * (70 + _rng.nextDouble() * 50),
              -60 - _rng.nextDouble() * 40)
          : Offset(dir * 6, 10),
      born: _t,
      life: spray ? 0.6 : 0.5,
      scale: 0.7 + _rng.nextDouble() * 0.4,
    ));
  }

  void _spawnZzz() {
    _particles.add(_Particle(
      kind: _PKind.zzz,
      origin: _headTop + Offset(_rx * 0.55, _s * 0.05),
      velocity: const Offset(14, -26),
      born: _t,
      life: 2.2,
    ));
  }

  // ─── build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final painter = _BlobPainter(
      state: this,
      color: widget.color,
      accessory: widget.accessory,
      outfit: widget.outfit,
      stage: widget.stage,
      mood: widget.mood,
      repaint: _frame,
    );
    final canvas = RepaintBoundary(
      child: CustomPaint(size: Size(_w, _h), painter: painter),
    );
    if (!widget.interactive) return canvas;
    final liftable = widget.onLift != null && !_showEgg;
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      onTap: () => _pet(null),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        // A smack only on a quick, clean tap — a finger resting or
        // rubbing gently in place is a stroke, not a hit.
        onTapDown: (_) => _touchAt = _t,
        onTapUp: (d) {
          if (_t - _touchAt < 0.3) _bonk(d.localPosition);
        },
        onVerticalDragStart:
            liftable ? (d) => _liftStart(d.globalPosition) : null,
        onVerticalDragUpdate:
            liftable ? (d) => _liftMove(d.globalPosition) : null,
        onVerticalDragEnd: liftable ? (_) => _liftEnd() : null,
        onVerticalDragCancel: liftable ? _liftEnd : null,
        onLongPressStart: liftable ? (d) => _liftStart(d.globalPosition) : null,
        onLongPressMoveUpdate:
            liftable ? (d) => _liftMove(d.globalPosition) : null,
        onLongPressEnd: liftable ? (_) => _liftEnd() : null,
        onHorizontalDragUpdate: (d) {
          _lookTarget = _lookVector(d.localPosition);
          _lookHoldUntil = _t + 1.4;
          _strokeDist += d.delta.distance;
          if (_strokeDist > _s * 0.3) {
            _strokeDist = 0;
            _pet(d.localPosition, stroke: true);
          }
        },
        onHorizontalDragEnd: (_) => _strokeDist = 0,
        child: canvas,
      ),
    );
  }
}
