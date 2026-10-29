import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_pause.dart';

/// The app's short sounds. Files live in `assets/sounds/`, one folder per
/// part of the app: `mascot/`, `chatter/` (its babble), `friend/` (a pet
/// dropping by), `scribe/` (writing a link up), `notes/`, `quiz/`, `room/`
/// (Beranda), `library/` and `ui/`. Each page's music and background sound
/// ([SoundScene]) are in `music/` and `ambience/`.
enum Sfx {
  // The pet.
  pet,
  happyJump,
  hit,
  ouch,
  grumpy,
  lift,
  land,
  dizzy,
  eat,
  eggCrack,
  hatchPop,
  levelUp,
  yawn,
  sneeze,
  hum,
  dance,
  dozeStartle,
  spin,
  wave,
  snack,
  yuck,
  burp,
  refuse,
  eggTap,
  roll,
  wail,
  sob,
  sniffle,
  hap,
  gulp,
  coinPick,
  step,
  sip,
  idea,
  giggle,

  // A friend dropping by on Beranda.
  friendKnock,
  friendCheer,

  // Writing a note.
  notePaper,
  noteTape,
  noteColor,
  notePhoto,
  noteClip,
  noteCrumple,

  // The daily quiz (the pet's meal) and the weekly feast.
  quizSelect,
  quizCorrect,
  quizWrong,
  quizComplete,
  quizFeast,
  quizXp,

  // Writing a link up on Beranda.
  bookPull,
  paperTadaa,

  // Beranda's living room.
  tvClick,
  tvStatic,
  tvStaticSoft,
  geckoChirp,
  geckoScurry,
  lampClick,
  coinDrop,

  // Pustaka's reading nook.
  pageFlip,
  shush,

  // Around the app.
  tabTick,
  noteSaved,
  error,
  bell,
  sheetOpen,
  swipe,
  start,
  equip,
}

/// Sounds that keep going while something lasts.
enum SfxLoop { tremble, snore, pencil, typing, buzz }

/// The pages with their own music and background sound.
enum SoundScene { home, notes, library, assistant }

/// The mix: how far (dB) under the pet's own voice each kind of sound
/// plays. The pet is the loudest thing in the app; the room, the page and
/// your taps sit well under it.
enum _Mix {
  /// The pet reacting: touched, picked up, eating, sulking. Its friend too.
  pet(0),

  /// Big moments: hatching, growing up, a finished quiz, starting out.
  moment(-1),

  /// The pet's quiet moments on its own: humming, yawning, a sip of tea,
  /// snoring.
  petQuiet(-3),

  /// Answers to what you did: saved, right or wrong, the bell, an outfit.
  feedback(-5),

  /// Little voices: the pet's babble as it talks, the gecko's chirp.
  voice(-6),

  /// Taps, page changes, sheets, paper and tape, clicks around the room,
  /// the pencil writing up the link you just gave it.
  ui(-10),

  /// Going on behind everything: keys typing while the AI's words come
  /// in, footsteps, a page turning while it reads.
  background(-14),

  /// Further back still: the TV changing channel by itself.
  far(-18);

  final double db;
  const _Mix(this.db);
}

/// Plays the app's sound effects: one place that knows the files, how loud
/// each one is (and so how loud to play it, see [_Mix]), and whether sound
/// is on.
///
/// Short sounds play in low-latency mode so they land with the animation.
/// They go wherever the phone's audio is going (earbuds, speaker), mix with
/// whatever else is playing without pausing it, and on iPhone stay quiet
/// when it's on silent. While the app is out of sight ([AppPause]) every
/// sound holds still, and carries on when it's back.
/// Sound can be switched off in Profile ([enabled]).
class SoundService extends ChangeNotifier {
  SoundService._();
  static final instance = SoundService._();

  static const _keyEnabled = 'sound.effects';

  /// How the app's sounds sit with the phone's audio.
  ///
  /// Android: "game" sounds on the media volume — routed to whatever is
  /// connected (Bluetooth earbuds, wired headphones), never forced onto the
  /// speaker, and without taking audio focus, so music keeps playing.
  /// (Ringtone/notification usage, which a "respect silence" setting would
  /// pick, plays on the speaker *and* the earbuds.)
  ///
  /// iOS: the "ambient" category — mixes with other audio and follows the
  /// silent switch.
  static final _context = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );
  static const _dir = 'sounds/';

  /// The files for each sound (a random one plays each time) and how loud.
  /// How loud the pet's voice plays (max momentary loudness, LUFS). It's
  /// the loudest thing in the app; every other sound is set from it by its
  /// [_Mix] (see "Aturan volume" in docs/sound-effects.md).
  static const _petLufs = -13.0;

  /// Volume that brings a file [lufs] loud to [db] under the pet.
  static double _gain(double lufs, double db) =>
      math.min(1.0, math.pow(10, (_petLufs + db - lufs) / 20).toDouble());

  /// Each sound: its file(s), how loud the file is (max momentary
  /// loudness in LUFS, the average for variants — measured with
  /// `tools/sound-kit/loudness.sh`; update it when a file is replaced) and
  /// where it sits in the mix.
  static const _files = <Sfx, (List<String>, double, _Mix)>{
    Sfx.pet: (
      ['mascot/pet_v1', 'mascot/pet_v2', 'mascot/pet_v3'],
      -8.5,
      _Mix.pet,
    ),
    Sfx.happyJump: (['mascot/happy_jump'], -9.7, _Mix.pet),
    Sfx.hit: (['mascot/hit'], -13.0, _Mix.pet),
    Sfx.ouch: (['mascot/ouch'], -11.4, _Mix.pet),
    Sfx.grumpy: (
      ['mascot/grumpy', 'mascot/grumpy_v2', 'mascot/grumpy_v3'],
      -9.3,
      _Mix.pet,
    ),
    Sfx.lift: (['mascot/lift'], -6.0, _Mix.pet),
    Sfx.land: (['mascot/land'], -13.3, _Mix.pet),
    Sfx.dizzy: (['mascot/dizzy'], -11.3, _Mix.pet),
    Sfx.eat: (['mascot/eat'], -11.6, _Mix.pet),
    Sfx.eggCrack: (['mascot/egg_crack'], -13.8, _Mix.moment),
    Sfx.hatchPop: (['mascot/hatch_pop'], -10.9, _Mix.moment),
    Sfx.levelUp: (['mascot/level_up'], -11.8, _Mix.moment),
    Sfx.yawn: (['mascot/yawn'], -13.3, _Mix.petQuiet),
    Sfx.sneeze: (['mascot/sneeze'], -11.1, _Mix.pet),
    Sfx.hum: (['mascot/hum'], -9.4, _Mix.petQuiet),
    Sfx.dance: (['mascot/dance'], -12.6, _Mix.petQuiet),
    Sfx.dozeStartle: (['mascot/doze_startle'], -11.3, _Mix.petQuiet),
    Sfx.spin: (['mascot/spin'], -11.0, _Mix.petQuiet),
    Sfx.wave: (['mascot/wave'], -9.2, _Mix.petQuiet),
    Sfx.snack: (['mascot/snack'], -12.1, _Mix.pet),
    Sfx.yuck: (['mascot/yuck'], -11.3, _Mix.pet),
    Sfx.burp: (['mascot/burp'], -11.3, _Mix.pet),
    Sfx.refuse: (['mascot/refuse'], -6.8, _Mix.pet),
    Sfx.eggTap: (['mascot/egg_tap'], -15.4, _Mix.pet),
    Sfx.step: (
      ['mascot/step_v1', 'mascot/step_v2', 'mascot/step_v3'],
      -14.7,
      _Mix.background,
    ),
    Sfx.sip: (['mascot/sip'], -11.8, _Mix.petQuiet),
    Sfx.idea: (['mascot/idea'], -10.2, _Mix.petQuiet),
    Sfx.giggle: (['mascot/giggle'], -8.4, _Mix.petQuiet),
    Sfx.friendKnock: (['friend/knock'], -14.5, _Mix.feedback),
    Sfx.friendCheer: (['friend/cheer'], -10.9, _Mix.pet),
    Sfx.notePaper: (['notes/paper'], -7.7, _Mix.ui),
    Sfx.noteTape: (['notes/tape'], -11.2, _Mix.ui),
    Sfx.noteColor: (['notes/color'], -12.6, _Mix.ui),
    Sfx.notePhoto: (['notes/photo'], -13.4, _Mix.ui),
    Sfx.noteClip: (['notes/clip'], -11.5, _Mix.ui),
    Sfx.noteCrumple: (['notes/crumple'], -10.1, _Mix.ui),
    Sfx.quizSelect: (['quiz/select'], -19.0, _Mix.ui),
    Sfx.quizCorrect: (['quiz/correct'], -10.7, _Mix.feedback),
    Sfx.quizWrong: (['quiz/wrong'], -12.8, _Mix.feedback),
    Sfx.quizComplete: (['quiz/complete'], -12.1, _Mix.moment),
    Sfx.quizFeast: (['quiz/feast'], -14.4, _Mix.moment),
    Sfx.quizXp: (['quiz/xp'], -11.2, _Mix.feedback),
    Sfx.bookPull: (['scribe/book_pull'], -10.8, _Mix.ui),
    Sfx.paperTadaa: (['scribe/paper_tadaa'], -14.3, _Mix.feedback),
    Sfx.tvClick: (['room/tv_click'], -17.3, _Mix.ui),
    Sfx.tvStatic: (['room/tv_static'], -2.9, _Mix.ui),
    Sfx.tvStaticSoft: (['room/tv_static_soft'], -8.8, _Mix.far),
    Sfx.geckoChirp: (['room/gecko_chirp'], -5.2, _Mix.voice),
    Sfx.geckoScurry: (['room/gecko_scurry'], -11.9, _Mix.background),
    Sfx.lampClick: (['room/lamp_click'], -16.7, _Mix.ui),
    Sfx.pageFlip: (['library/page_flip'], -10.5, _Mix.background),
    Sfx.shush: (['library/shush'], -12.2, _Mix.petQuiet),
    Sfx.tabTick: (['ui/tab_tick'], -18.3, _Mix.ui),
    Sfx.noteSaved: (['ui/note_saved'], -11.8, _Mix.feedback),
    Sfx.error: (['ui/error'], -12.0, _Mix.feedback),
    Sfx.bell: (['ui/bell'], -11.3, _Mix.feedback),
    Sfx.sheetOpen: (['ui/sheet_open'], -15.3, _Mix.ui),
    Sfx.swipe: (['ui/swipe'], -10.2, _Mix.ui),
    Sfx.start: (['ui/start'], -11.1, _Mix.moment),
    Sfx.equip: (['ui/equip'], -11.2, _Mix.feedback),
    // Not made yet: -11 stands in until each file is in and measured.
    Sfx.roll: (['mascot/roll'], -11.0, _Mix.petQuiet),
    Sfx.wail: (['mascot/wail'], -11.0, _Mix.pet),
    Sfx.sob: (['mascot/sob'], -11.0, _Mix.petQuiet),
    Sfx.sniffle: (['mascot/sniffle'], -11.0, _Mix.petQuiet),
    Sfx.hap: (['mascot/hap'], -11.0, _Mix.pet),
    Sfx.gulp: (['mascot/gulp'], -11.0, _Mix.petQuiet),
    Sfx.coinPick: (['mascot/coin_pick'], -11.0, _Mix.petQuiet),
    Sfx.coinDrop: (
      ['room/coin_drop_v1', 'room/coin_drop_v2', 'room/coin_drop_v3'],
      -11.0,
      _Mix.feedback
    ),
  };

  /// Sounds still waiting for their own file (see docs/sound-effects.md):
  /// until it's in `assets/sounds/`, each borrows another sound, quieter.
  static const _borrow = <Sfx, (Sfx, double)>{
    Sfx.roll: (Sfx.spin, 1.0),
    Sfx.wail: (Sfx.ouch, 1.0),
    Sfx.sob: (Sfx.ouch, 0.5),
    Sfx.sniffle: (Sfx.pet, 0.9),
    Sfx.hap: (Sfx.eat, 1.0),
    Sfx.gulp: (Sfx.snack, 0.7),
    Sfx.coinPick: (Sfx.quizXp, 0.6),
    Sfx.coinDrop: (Sfx.noteClip, 0.8),
  };

  /// Files that couldn't be loaded (not made yet).
  final _missing = <String>{};

  /// Like [_files]: file, its loudness, place in the mix.
  static const _loops = <SfxLoop, (String, double, _Mix)>{
    SfxLoop.tremble: ('mascot/tremble_loop', -11.0, _Mix.petQuiet),
    SfxLoop.snore: ('mascot/snore_loop', -8.7, _Mix.petQuiet),
    SfxLoop.pencil: ('scribe/writing_loop', -18.7, _Mix.ui),
    SfxLoop.typing: ('ui/typing_loop', -26.3, _Mix.background),
    // Not made yet (silent until it's in): -11 stands in.
    SfxLoop.buzz: ('room/mosquito_loop', -11.0, _Mix.ui),
  };

  /// How loud the babble files are (LUFS, both voices): one syllable, and
  /// a whole phrase.
  static const _syllableLufs = -12.6;
  static const _phraseLufs = -11.3;

  static const _syllables = [
    'chatter/syllable_bi',
    'chatter/syllable_bu',
    'chatter/syllable_mi',
    'chatter/syllable_wa',
    'chatter/syllable_pu',
    'chatter/syllable_ri',
    'chatter/syllable_yo',
    'chatter/syllable_nu',
  ];
  /// A visiting friend's own voice.
  static const _friendSyllables = [
    'chatter/friend_syllable_bi',
    'chatter/friend_syllable_mo',
    'chatter/friend_syllable_ki',
    'chatter/friend_syllable_pa',
    'chatter/friend_syllable_ru',
    'chatter/friend_syllable_ya',
  ];
  static const _friendPhrases = [
    'chatter/friend_phrase_v1',
    'chatter/friend_phrase_v2',
  ];
  static const _phrases = [
    'chatter/phrase_v1',
    'chatter/phrase_v2',
    'chatter/phrase_v3',
    'chatter/phrase_v4',
  ];

  /// Each page's music and background sound (null for none), each with
  /// how loud the file is (integrated loudness, LUFS). Long tracks, so they
  /// stream instead of sitting in memory like the short sounds.
  static const _scenes = <SoundScene, ((String, double)?, (String, double)?)>{
    SoundScene.home: (
      ('music/home_warm_room', -16.0),
      ('ambience/home_cozy', -14.8),
    ),
    SoundScene.notes: (
      ('music/notes_cozy_study', -16.2),
      ('ambience/notes_quiet_room', -14.4),
    ),
    SoundScene.library: (
      ('music/library_quiet', -16.1),
      ('ambience/library_air', -14.7),
    ),
    // The tea corner: just rain on the window, so answers are easy to read.
    SoundScene.assistant: (null, ('ambience/assistant_rain', -12.5)),
  };

  /// The beds play this far (dB) under the pet: the music well under it,
  /// the room sound under the music — or in the music's place when there's
  /// none.
  static const _musicDb = -11.0;
  static const _ambienceDb = -14.0;

  /// Repeats of the same sound closer together than this are dropped (so
  /// stroking the pet doesn't turn into a buzz).
  static const _minGap = <Sfx, Duration>{
    Sfx.pet: Duration(milliseconds: 220),
    Sfx.hit: Duration(milliseconds: 80),
    Sfx.grumpy: Duration(milliseconds: 900),
    Sfx.shush: Duration(milliseconds: 1200),
    Sfx.tabTick: Duration(milliseconds: 60),
    Sfx.sheetOpen: Duration(milliseconds: 300),
    Sfx.error: Duration(milliseconds: 600),
    Sfx.bell: Duration(seconds: 2),
    Sfx.step: Duration(milliseconds: 150),
    Sfx.quizSelect: Duration(milliseconds: 80),
    Sfx.sob: Duration(seconds: 1),
    Sfx.coinDrop: Duration(milliseconds: 70),
  };

  /// Widget tests have no audio plugin.
  static final bool _silent =
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  final _rng = math.Random();
  final _players = <String, AudioPlayer>{};
  final _lastPlayed = <Sfx, DateTime>{};
  final _loopsOn = <SfxLoop>{};
  DateTime _lastChatter = DateTime(0);
  SharedPreferences? _prefs;

  /// Whether sound effects are on (Profile → Sound effects).
  bool get enabled => _prefs?.getBool(_keyEnabled) ?? true;

  Future<void> setEnabled(bool on) async {
    await _prefs?.setBool(_keyEnabled, on);
    if (!on) _stopShort();
    notifyListeners();
  }

  // ─── music & background sound ───────────────────────────────────────

  static const _keyMusic = 'sound.music';
  static const _keyAmbience = 'sound.ambience';

  /// Background music (Profile → Background music). Off until switched on.
  bool get musicEnabled => _prefs?.getBool(_keyMusic) ?? false;

  /// Each room's quiet background sound (Profile → Room ambience). Off
  /// until switched on.
  bool get ambienceEnabled => _prefs?.getBool(_keyAmbience) ?? false;

  Future<void> setMusicEnabled(bool on) async {
    await _prefs?.setBool(_keyMusic, on);
    _syncBeds();
    notifyListeners();
  }

  Future<void> setAmbienceEnabled(bool on) async {
    await _prefs?.setBool(_keyAmbience, on);
    _syncBeds();
    notifyListeners();
  }

  final _beds = <String, _LoopBed>{};
  SoundScene? _scene;
  Timer? _sceneTimer;
  bool _foreground = true;

  /// A page with its own sound came on screen ([SceneSound] does this).
  void enterScene(SoundScene scene) {
    _scene = scene;
    _sceneSoon();
  }

  /// That page went away (only counts if it's still the current one).
  void leaveScene(SoundScene scene) {
    if (_scene != scene) return;
    _scene = null;
    _sceneSoon();
  }

  /// Switching tabs leaves one page and enters the next a moment later;
  /// waiting a beat avoids fading out what's about to come straight back.
  void _sceneSoon() {
    _sceneTimer?.cancel();
    _sceneTimer = Timer(const Duration(milliseconds: 180), _syncBeds);
  }

  /// Fades in what the current page should play and fades out the rest.
  void _syncBeds() {
    // Out of sight they hold still; this catches up once the app's back.
    if (_silent || !_foreground) return;
    final pair = _scene == null ? null : _scenes[_scene];
    final music = musicEnabled ? pair?.$1 : null;
    final ambience = ambienceEnabled ? pair?.$2 : null;
    final want = <String, double>{
      if (music != null) music.$1: _gain(music.$2, _musicDb),
      if (ambience != null)
        ambience.$1:
            _gain(ambience.$2, music != null ? _ambienceDb : _musicDb),
    };
    for (final MapEntry(key: asset, value: bed) in _beds.entries) {
      if (!want.containsKey(asset)) bed.stop();
    }
    for (final MapEntry(key: asset, value: level) in want.entries) {
      (_beds.putIfAbsent(
              asset, () => _LoopBed('$_dir$asset.m4a', level, _context))
            ..level = level)
          .start();
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (_silent) return;
    AppPause.instance.addListener(_onPause);
    try {
      await AudioPlayer.global.setAudioContext(_context);
    } catch (_) {/* platform without audio */}
    unawaited(_preload());
  }

  /// Sounds worth having ready before they're first needed: the ones that
  /// answer a touch straight away. Everything else loads the first time it
  /// plays (a few milliseconds late, once) — loading all ~100 up front
  /// kept the app busy for a while after every start.
  static const _warm = [
    Sfx.pet,
    Sfx.hit,
    Sfx.ouch,
    Sfx.step,
    Sfx.eat,
    Sfx.snack,
    Sfx.tabTick,
    Sfx.sheetOpen,
    Sfx.quizSelect,
  ];

  Future<void> _preload() async {
    // Let the first screens settle first.
    await Future<void>.delayed(const Duration(seconds: 2));
    final files = {
      for (final sfx in _warm) ..._files[sfx]!.$1,
      // Sounds that borrow another until their own file is made: trying
      // them now means the borrowing starts on their very first play.
      for (final sfx in _borrow.keys) ..._files[sfx]!.$1,
      ..._syllables,
    };
    for (final f in files) {
      await _player(f);
    }
  }

  Future<AudioPlayer?> _player(String file, {bool loop = false}) async {
    final existing = _players[file];
    if (existing != null) return existing;
    if (_missing.contains(file)) return null;
    try {
      final p = AudioPlayer();
      _players[file] = p;
      await p.setAudioContext(_context);
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await p.setSource(AssetSource('$_dir$file.wav'));
      return p;
    } catch (_) {
      _players.remove(file)?.dispose();
      _missing.add(file);
      return null;
    }
  }

  Future<void> _start(String file, double volume, {double rate = 1}) async {
    if (!_foreground) return;
    final p = await _player(file);
    if (p == null || !_foreground) return;
    try {
      await p.stop();
      await p.setVolume(volume);
      if (rate != 1) await p.setPlaybackRate(rate);
      await p.resume();
    } catch (_) {/* a missed sound is fine */}
  }

  /// Plays [sfx], after [delay] if given, at [volume] × its own level.
  void play(Sfx sfx, {Duration delay = Duration.zero, double volume = 1}) {
    if (_silent || !enabled) return;
    final now = DateTime.now();
    final gap = _minGap[sfx];
    final last = _lastPlayed[sfx];
    if (gap != null && last != null && now.difference(last) < gap) return;
    _lastPlayed[sfx] = now;
    final (files, lufs, mix) = _files[sfx]!;
    final borrow = _borrow[sfx];
    if (borrow != null && files.every(_missing.contains)) {
      play(borrow.$1, delay: delay, volume: volume * borrow.$2);
      return;
    }
    final file = files[_rng.nextInt(files.length)];
    // A touch of pitch wobble on the sounds that repeat a lot.
    final rate = sfx == Sfx.pet || sfx == Sfx.step
        ? 0.94 + _rng.nextDouble() * 0.12
        : 1.0;
    void go() {
      if (enabled) _start(file, _gain(lufs, mix.db) * volume, rate: rate);
    }

    delay == Duration.zero ? go() : AppTimer(delay, go);
  }

  /// Turns [loop] on or off (no-op when it's already that way).
  void setLoop(SfxLoop loop, bool on) {
    if (_silent) return;
    on = on && enabled;
    if (on == _loopsOn.contains(loop)) return;
    final (file, lufs, mix) = _loops[loop]!;
    if (on) {
      _loopsOn.add(loop);
      _player(file, loop: true).then((p) async {
        if (p == null || !_loopsOn.contains(loop) || !_foreground) return;
        try {
          await p.setVolume(_gain(lufs, mix.db));
          await p.resume();
        } catch (_) {}
      });
    } else {
      _loopsOn.remove(loop);
      _players[file]?.stop().catchError((_) {});
    }
  }

  /// The pet "says" [text]: a little babble of made-up syllables (or a
  /// ready-made phrase for longer lines), the way game characters talk.
  /// A visiting [friend] has its own voice; [pitch] shifts it up or down.
  void chatter(String text, {double pitch = 1, bool friend = false}) {
    if (_silent || !enabled || text.trim().isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastChatter) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastChatter = now;
    final syllables = friend ? _friendSyllables : _syllables;
    final phrases = friend ? _friendPhrases : _phrases;
    if (text.length > 32 && _rng.nextBool()) {
      _start(phrases[_rng.nextInt(phrases.length)],
          _gain(_phraseLufs, _Mix.voice.db),
          rate: pitch);
      return;
    }
    final count = (text.length / 9).round().clamp(2, 5);
    final volume = _gain(_syllableLufs, _Mix.voice.db);
    var at = 0;
    for (var i = 0; i < count; i++) {
      final file = syllables[_rng.nextInt(syllables.length)];
      final rate = (0.92 + _rng.nextDouble() * 0.2) * pitch;
      AppTimer(Duration(milliseconds: at), () {
        if (enabled) _start(file, volume, rate: rate);
      });
      at += 85 + _rng.nextInt(40);
    }
  }

  /// Stops the short sounds and loops (not the room ambience).
  void _stopShort() {
    _loopsOn.clear();
    _held.clear();
    for (final p in _players.values) {
      p.stop().catchError((_) {});
    }
  }

  /// Sounds caught mid-play when the app went out of sight.
  final _held = <AudioPlayer>[];

  /// Out of sight, every sound holds still — the music and room sound
  /// too; back in sight, they all carry on from there.
  void _onPause() {
    _foreground = !AppPause.instance.paused;
    if (!_foreground) {
      for (final p in _players.values) {
        if (p.state == PlayerState.playing) {
          _held.add(p);
          p.pause().catchError((_) {});
        }
      }
      for (final bed in _beds.values) {
        bed.hold();
      }
    } else {
      for (final p in _held) {
        p.resume().catchError((_) {});
      }
      _held.clear();
      for (final bed in _beds.values) {
        bed.carryOn();
      }
      // The page may have changed meanwhile.
      _syncBeds();
    }
  }
}

/// A long track that loops without a seam: each track fades in and out
/// over its first and last 1.5 s, so the next copy starts (on a second
/// player) as this one begins to fade — the two fades cross. Fades in when
/// started, out when stopped. Holds still while the app is out of sight
/// ([hold], [carryOn]).
class _LoopBed {
  _LoopBed(this.asset, this._level, this.context);

  final String asset;
  final AudioContext context;

  /// Its volume at full fade.
  double _level;
  double get level => _level;
  set level(double v) {
    if (v == _level) return;
    _level = v;
    for (final p in _players) {
      p.setVolume(_level * _gain).catchError((_) {});
    }
  }

  static const _overlap = Duration(milliseconds: 1500);
  static const _fade = Duration(milliseconds: 900);
  static const _step = Duration(milliseconds: 60);

  final _players = <AudioPlayer>[];
  int _current = 0;
  Duration _length = const Duration(seconds: 60);
  Timer? _nextCopy;
  Timer? _ramp;
  double _gain = 0;
  bool _on = false;
  Future<void>? _preparing;

  /// Bumped whenever playback is cut off, so anything still on its way
  /// (loading, the next copy) knows not to start.
  int _gen = 0;

  Future<void> _prepare() => _preparing ??= () async {
        for (var i = 0; i < 2; i++) {
          final p = AudioPlayer();
          await p.setAudioContext(context);
          await p.setReleaseMode(ReleaseMode.stop);
          await p.setSource(AssetSource(asset));
          _players.add(p);
        }
        _length = await _players.first.getDuration() ?? _length;
      }();

  Future<void> start() async {
    if (_on) return;
    _on = true;
    try {
      await _prepare();
      if (!_on) return;
      // Still going (stopped mid-fade and started again): just fade back
      // up; otherwise start from the top.
      if (_gain <= 0) {
        final gen = _gen;
        _current = 0;
        await _playCopy(_players[_current], gen);
        if (gen != _gen) return;
      }
      _rampTo(1);
    } catch (_) {/* no background sound is fine */}
  }

  void stop() {
    if (!_on) return;
    _on = false;
    _rampTo(0, then: _cut);
  }

  /// Copies paused by [hold].
  final _held = <AudioPlayer>[];

  /// Pauses where it is (its fades and next copy wait too: [AppTimer]).
  void hold() {
    for (final p in _players) {
      if (p.state == PlayerState.playing) {
        _held.add(p);
        p.pause().catchError((_) {});
      }
    }
  }

  /// Plays on from where [hold] paused it.
  void carryOn() {
    for (final p in _held) {
      p.resume().catchError((_) {});
    }
    _held.clear();
  }

  void _cut() {
    _gen++;
    _held.clear();
    _nextCopy?.cancel();
    for (final p in _players) {
      p.stop().catchError((_) {});
    }
  }

  Future<void> _playCopy(AudioPlayer p, int gen) async {
    await p.setVolume(level * _gain);
    await p.seek(Duration.zero);
    if (gen != _gen) return;
    if (AppPause.instance.paused) {
      // Went out of sight just now: it starts when the app is back.
      _held.add(p);
    } else {
      await p.resume();
    }
    _nextCopy?.cancel();
    _nextCopy = AppTimer(_length - _overlap, () {
      if (gen != _gen) return;
      _current = 1 - _current;
      _playCopy(_players[_current], gen).catchError((_) {});
    });
  }

  /// Moves the volume to [target] (0..1 of [level]) over [_fade].
  void _rampTo(double target, {VoidCallback? then}) {
    _ramp?.cancel();
    final delta = _step.inMicroseconds / _fade.inMicroseconds;
    _ramp = AppTimer.periodic(_step, (t) {
      _gain = target > _gain
          ? math.min(target, _gain + delta)
          : math.max(target, _gain - delta);
      for (final p in _players) {
        p.setVolume(level * _gain).catchError((_) {});
      }
      if (_gain == target) {
        t.cancel();
        then?.call();
      }
    });
  }
}

/// Marks a page with its own music and background sound: plays them while
/// the page is on screen (not covered by another page), and lets them fade
/// when it goes.
class SceneSound extends StatefulWidget {
  final SoundScene scene;
  final Widget child;
  const SceneSound({super.key, required this.scene, required this.child});

  @override
  State<SceneSound> createState() => _SceneSoundState();
}

class _SceneSoundState extends State<SceneSound> {
  ValueListenable<bool>? _visible;

  void _sync() {
    final sound = SoundService.instance;
    (_visible?.value ?? false)
        ? sound.enterScene(widget.scene)
        : sound.leaveScene(widget.scene);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.getNotifier(context);
    if (visible != _visible) {
      _visible?.removeListener(_sync);
      _visible = visible..addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    _visible?.removeListener(_sync);
    SoundService.instance.leaveScene(widget.scene);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
