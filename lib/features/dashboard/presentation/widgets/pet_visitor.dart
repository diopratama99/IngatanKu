import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/services/app_pause.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/presentation/widgets/blob_mascot.dart';
import '../../../companion/presentation/widgets/pet_speech_bubble.dart';

/// One of the pet's friends: another blob, in its own colour and outfit.
class VisitorPet {
  final String name;
  final BlobColor color;
  final BlobAccessory accessory;
  final PetStage stage;
  const VisitorPet(this.name, this.color, this.accessory, this.stage);

  static const friends = [
    VisitorPet('Moci', BlobColor.taro, BlobAccessory.bow, PetStage.kid),
    VisitorPet('Pipi', BlobColor.peach, BlobAccessory.beanie, PetStage.teen),
    VisitorPet('Bubu', BlobColor.sky, BlobAccessory.headphones, PetStage.adult),
    VisitorPet('Kiko', BlobColor.matcha, BlobAccessory.scarf, PetStage.teen),
    VisitorPet('Coco', BlobColor.mocha, BlobAccessory.sprout, PetStage.kid),
  ];

  /// Someone who doesn't look like the pet itself.
  static VisitorPet pick(math.Random rng, BlobColor host) {
    final others = friends.where((f) => f.color != host).toList();
    return others[rng.nextInt(others.length)];
  }
}

/// A friend dropping by, as Beranda asks for it.
class VisitPlan {
  final VisitorPet friend;

  /// Comes in from the left (and leaves that way), or from the right.
  final bool fromLeft;
  final String hostName;

  /// Notes the pet ate today — it tells its friend.
  final int todayCount;
  const VisitPlan({
    required this.friend,
    required this.fromLeft,
    required this.hostName,
    required this.todayCount,
  });
}

/// A friend popping by on Beranda — an easter egg. It walks in from one
/// side, says hi to the pet, they chat for a bit (the pet's lines go in
/// its own bubble through [onHostSay]), then it waves and walks off the
/// way it came. Lives in the room's stack, on the same floor as the pet.
///
/// When the pet gets busy ([interrupted]: picked up, writing a link
/// up…), the friend leaves straight away.
class PetVisit extends StatefulWidget {
  final VisitPlan plan;
  final double sceneWidth;
  final double sceneHeight;

  /// The floor line the pets stand on, and their reference size.
  final double groundY;
  final double petS;

  /// The pet, to turn it towards its friend and have it wave and talk.
  final BlobController host;
  final bool interrupted;
  final void Function(String line, Duration hold) onHostSay;
  final VoidCallback onDone;

  const PetVisit({
    super.key,
    required this.plan,
    required this.sceneWidth,
    required this.sceneHeight,
    required this.groundY,
    required this.petS,
    required this.host,
    required this.interrupted,
    required this.onHostSay,
    required this.onDone,
  });

  @override
  State<PetVisit> createState() => _PetVisitState();
}

class _PetVisitState extends State<PetVisit>
    with SingleTickerProviderStateMixin {
  final _friend = BlobController();
  late final AnimationController _x =
      AnimationController.unbounded(vsync: this, value: _offstage);
  final _rng = math.Random();
  String? _line;
  bool _leaving = false;
  bool _done = false;

  /// -1 on the left of the pet, 1 on the right.
  double get _side => widget.plan.fromLeft ? -1 : 1;

  double get _scale => widget.plan.friend.stage.scale;
  double get _halfBody => widget.petS * 0.5 * _scale;

  /// Just outside the room, on its side.
  double get _offstage =>
      widget.sceneWidth / 2 +
      _side * (widget.sceneWidth / 2 + widget.petS * 0.9);

  /// Next to the pet (standing on its cushion in the middle), but still
  /// inside the room.
  double get _standX {
    final gap =
        math.min(widget.petS * 1.0, widget.sceneWidth / 2 - _halfBody - 6);
    return widget.sceneWidth / 2 + _side * gap;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void didUpdateWidget(PetVisit old) {
    super.didUpdateWidget(old);
    if (widget.interrupted && !old.interrupted) _leave();
  }

  @override
  void dispose() {
    _x.dispose();
    widget.host
      ..focus(null)
      ..talk(false);
    super.dispose();
  }

  bool get _going => mounted && !_leaving && !widget.interrupted;

  Future<bool> _wait(int ms) async {
    await AppPause.delay(Duration(milliseconds: ms));
    return _going;
  }

  /// The friend says [text] in its own bubble, in its own voice.
  Future<bool> _friendSays(String text, {int ms = 2500}) async {
    if (!_going) return false;
    setState(() => _line = text);
    SoundService.instance.chatter(text, friend: true);
    _friend.talk(true);
    AppTimer(const Duration(milliseconds: 1100), () {
      if (mounted) _friend.talk(false);
    });
    final ok = await _wait(ms);
    if (mounted) setState(() => _line = null);
    return ok && await _wait(250);
  }

  /// The pet answers, in its own bubble.
  Future<bool> _hostSays(String text, {int ms = 2500}) async {
    if (!_going) return false;
    widget.onHostSay(text, Duration(milliseconds: ms));
    widget.host.talk(true);
    AppTimer(const Duration(milliseconds: 1100), () {
      if (mounted) widget.host.talk(false);
    });
    return await _wait(ms) && await _wait(250);
  }

  Future<bool> _walkTo(double x) async {
    final distance = (x - _x.value).abs();
    _friend.walk(x > _x.value ? 1 : -1);
    try {
      await _x
          .animateTo(x,
              duration: Duration(
                  milliseconds: (distance / widget.petS * 2000)
                      .round()
                      .clamp(1400, 3600)),
              curve: Curves.easeInOut)
          .orCancel;
    } on TickerCanceled {
      return false;
    } finally {
      if (mounted) _friend.walk(0);
    }
    return _going;
  }

  Future<void> _run() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final plan = widget.plan;
    final host = widget.host;
    final s = _side;
    // Knock knock — then in it comes.
    SoundService.instance.play(Sfx.friendKnock);
    if (!await _wait(700) || !await _walkTo(_standX)) return _leave();

    // Face each other.
    _friend.focus(Offset(-s * 0.9, 0.05));
    host.focus(Offset(s * 0.9, 0.05));

    _friend.idle(BlobIdle.wave);
    if (!await _friendSays(l10n.visitHello(plan.hostName))) return _leave();
    host.idle(BlobIdle.wave);
    if (!await _hostSays(l10n.visitHelloBack(plan.friend.name))) {
      return _leave();
    }

    // A little chat: what it ate, what it learned, or the room.
    final topic = _rng.nextInt(3);
    final ate = plan.todayCount > 0;
    final ask = switch (topic) {
      0 => l10n.visitAskFood,
      1 => l10n.visitAskLearn,
      _ => l10n.visitAskRoom,
    };
    if (!await _friendSays(ask)) return _leave();
    if (topic == 2) {
      host.beam();
      if (!await _hostSays(l10n.visitReplyRoom)) return _leave();
    } else if (ate) {
      host.beam();
      if (!await _hostSays(l10n.visitReplyAte(plan.todayCount))) {
        return _leave();
      }
      _friend.celebrate(sound: Sfx.friendCheer);
      if (!await _friendSays(l10n.visitWow, ms: 2000)) return _leave();
    } else {
      host.express(BlobExpression.sad,
          duration: const Duration(milliseconds: 2400));
      if (!await _hostSays(l10n.visitReplyHungry)) return _leave();
      if (!await _friendSays(l10n.visitAww, ms: 2200)) return _leave();
    }

    // Goodbyes.
    _friend.idle(BlobIdle.wave);
    if (!await _friendSays(l10n.visitBye, ms: 2100)) return _leave();
    host.idle(BlobIdle.wave);
    widget.onHostSay(l10n.visitByeBack, const Duration(milliseconds: 2200));
    await _leave();
  }

  /// Off it goes, the way it came.
  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    setState(() => _line = null);
    _friend
      ..focus(null)
      ..talk(false);
    try {
      await _walkTo(_offstage);
    } finally {
      if (mounted && !_done) {
        _done = true;
        widget.host.focus(null);
        widget.onDone();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friend = widget.plan.friend;
    final s = widget.petS;
    final w = s * BlobMascot.widthFactor;
    final h = s * BlobMascot.heightFactor;
    final body = 0.74 * s * _scale;
    final bubbleW = math.min(170.0, widget.sceneWidth * 0.5);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _x,
          builder: (_, child) => Positioned(
            left: _x.value - w / 2,
            top: widget.groundY - h + s * 0.05,
            child: child!,
          ),
          child: BlobMascot(
            size: s,
            color: friend.color,
            accessory: friend.accessory,
            stage: friend.stage,
            controller: _friend,
            sounds: true,
            semanticsLabel: l10n.visitSemantics(friend.name),
          ),
        ),
        // Its bubble over its head, kept inside the room.
        AnimatedBuilder(
          animation: _x,
          builder: (_, child) => Positioned(
            left: (_x.value - bubbleW / 2)
                .clamp(0.0, math.max(0.0, widget.sceneWidth - bubbleW)),
            width: bubbleW,
            bottom: widget.sceneHeight - widget.groundY + body + s * 0.14,
            child: child!,
          ),
          child: IgnorePointer(
            child: Center(
              child: PetSpeechBubble(text: _line, maxWidth: bubbleW),
            ),
          ),
        ),
      ],
    );
  }
}
