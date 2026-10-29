import 'package:flutter/foundation.dart';

import '../../../core/services/app_pause.dart';

/// Whether the user's pet is in tears — one pet, whichever page it's on.
/// Smack it to tears in Catatan and it's still crying (and bruised) on
/// Beranda, until it's been petted better, wherever that happens. Kept
/// for the session: a fresh start next time the app opens.
///
/// Times are wall-clock, so each page's pet can put them on its own clock.
/// While the app is out of sight they wait, like the pet does ([AppPause]).
class PetHurt extends ChangeNotifier {
  PetHurt._() {
    AppPause.instance.addListener(_onAppPause);
  }
  static final instance = PetHurt._();

  bool crying = false;

  /// The latest wail, when the bruises came up, and when it was calmed.
  DateTime? cryAt;
  DateTime? bruisedAt;
  DateTime? calmAt;

  /// Strokes it has had since it started calming down, and the latest.
  int comfort = 0;
  DateTime? lastComfort;

  /// How long the bruises last once it's calm (they fade towards the end).
  static const healIn = Duration(seconds: 8);

  /// Crying, or still bruised.
  bool get active => crying || bruisedAt != null;

  /// Bursts into tears — or wails again if it already was.
  void cry(DateTime now) {
    if (!crying) {
      bruisedAt = now;
      calmAt = null;
    }
    crying = true;
    cryAt = now;
    comfort = 0;
    notifyListeners();
  }

  /// One more stroke of comfort ([strokes] so far).
  void soothe(DateTime now, int strokes) {
    comfort = strokes;
    lastComfort = now;
    notifyListeners();
  }

  /// Petted enough: it stops crying.
  void calm(DateTime now) {
    crying = false;
    calmAt = now;
    comfort = 0;
    lastComfort = now;
    notifyListeners();
  }

  /// Back from the background: its tears and bruises are where they were,
  /// so their times move on by the time away.
  void _onAppPause() {
    final pause = AppPause.instance;
    if (pause.paused || !active) return;
    final gap = pause.lastGap;
    DateTime? later(DateTime? at) => at?.add(gap);
    cryAt = later(cryAt);
    bruisedAt = later(bruisedAt);
    calmAt = later(calmAt);
    lastComfort = later(lastComfort);
    notifyListeners();
  }

  /// Forgets the bruises once they've healed.
  void heal(DateTime now) {
    final calmed = calmAt;
    if (!crying && calmed != null && now.difference(calmed) > healIn) {
      bruisedAt = null;
    }
  }
}
