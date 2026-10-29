import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/services/app_pause.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/pet_store.dart';
import '../../domain/companion_style.dart';
import '../pet_labels.dart';
import 'blob_mascot.dart';

/// The user's own pet as a small, live avatar (it still blinks and can
/// be petted). Sized so every life stage fills roughly the same box.
///
/// [glasses], [expression] and [controller] dress it for the page it's
/// on (reading glasses over a note, a face for a quiz answer…). With
/// [idle] it does a little something of its own every so often — a wave,
/// a hum, a twirl — like it does on Beranda; [calm] keeps that to small,
/// quiet moves that stay inside a card. [accessory] and [outfit], when
/// given, are tried on instead of what it's wearing (in the wardrobe).
class PetHost extends StatefulWidget {
  final double height;
  final bool glasses;
  final BlobExpression? expression;
  final BlobController? controller;
  final bool idle;
  final BlobAccessory? accessory;
  final BlobOutfit? outfit;

  /// Only a glance round, a wave or a smile, now and then — no hops,
  /// twirls or notes floating off (a pet sitting in a card).
  final bool calm;
  const PetHost({
    super.key,
    this.height = 80,
    this.glasses = false,
    this.expression,
    this.controller,
    this.idle = true,
    this.calm = false,
    this.accessory,
    this.outfit,
  });

  @override
  State<PetHost> createState() => _PetHostState();
}

class _PetHostState extends State<PetHost> {
  final _own = BlobController();
  final _rng = math.Random();
  Timer? _timer;

  BlobController get _pet => widget.controller ?? _own;

  @override
  void initState() {
    super.initState();
    if (widget.idle) _schedule(first: true);
  }

  @override
  void didUpdateWidget(PetHost old) {
    super.didUpdateWidget(old);
    if (widget.idle != old.idle) {
      _timer?.cancel();
      if (widget.idle) _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule({bool first = false}) {
    final (wait, spread) = switch ((widget.calm, first)) {
      (false, true) => (4, 5),
      (false, false) => (10, 10),
      (true, true) => (6, 6),
      (true, false) => (14, 14),
    };
    _timer =
        AppTimer(Duration(seconds: wait + _rng.nextInt(spread)), _idleOnce);
  }

  void _idleOnce() {
    if (!mounted) return;
    final state = sl<PetStore>().state;
    if (TickerMode.of(context) && state.hatched) {
      final mood = state.moodAt(DateTime.now());
      final low = mood == CompanionMood.hungry || mood == CompanionMood.lonely;
      if (widget.calm) {
        _calmOnce(quiet: low || widget.expression != null);
        _schedule();
        return;
      }
      // With a face of its own on (dizzy, sad…) it only glances around;
      // a hungry or lonely pet isn't up for twirling either.
      final moves = widget.expression != null
          ? const [BlobIdle.lookAround]
          : low
              ? const [BlobIdle.lookAround, BlobIdle.stretch]
              : const [
                  BlobIdle.wave,
                  BlobIdle.hum,
                  BlobIdle.lookAround,
                  BlobIdle.stretch,
                  BlobIdle.spin,
                  BlobIdle.dance,
                  BlobIdle.sneeze,
                ];
      _pet.idle(moves[_rng.nextInt(moves.length)]);
    }
    _schedule();
  }

  /// A small, quiet move: a glance round, a wave or a smile ([quiet]: just
  /// the glance).
  void _calmOnce({required bool quiet}) {
    switch (quiet ? 0 : _rng.nextInt(3)) {
      case 0:
        _pet.idle(BlobIdle.lookAround);
      case 1:
        _pet.idle(BlobIdle.wave);
      default:
        _pet.beam(duration: const Duration(milliseconds: 1400));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = sl<PetStore>();
    final l10n = AppLocalizations.of(context)!;
    final height = widget.height;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final stage = store.state.stage;
        // Size from the *visible* body height (the canvas is mostly
        // headroom for jumps), so a baby and a sage fill the box alike.
        final body =
            stage == PetStage.egg ? 0.84 * stage.scale : 0.74 * stage.scale;
        final size = height * 0.72 / body;
        final mood = store.state.moodAt(DateTime.now());
        return SizedBox(
          width: height,
          height: height,
          child: OverflowBox(
            alignment: Alignment.bottomCenter,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: BlobMascot(
              size: size,
              color: store.color,
              accessory: widget.accessory ?? store.accessory,
              outfit: widget.outfit ?? store.outfit,
              stage: stage,
              // A header host never snoozes — it's greeting you.
              mood: mood == CompanionMood.sleepy ? CompanionMood.content : mood,
              onPet: store.pet,
              glasses: widget.glasses,
              expression: widget.expression,
              controller: _pet,
              sounds: true,
              ownPet: true,
              semanticsLabel: l10n.petSemantics(l10n.petName(store)),
            ),
          ),
        );
      },
    );
  }
}
