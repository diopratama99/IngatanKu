import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/services/app_pause.dart';
import '../../../../core/services/sound_service.dart';

/// What's on the pet's TV: the clips in `assets/tv/optimized/` (tiny, soft
/// and pixelated, so they don't steal the show) on a loop
/// (1 → 2 → … → 5 → 1 …) with a burst of static between them, like
/// changing channels. Tap it to skip to the next one.
///
/// Muted, and mixed with whatever else the phone is playing. It pauses
/// while the page is covered (or the app is in the background). Until the
/// first clip is ready — or if video can't play at all — it shows nothing,
/// so the TV image's own picture shows through.
class TvChannels extends StatefulWidget {
  final String semanticsLabel;
  const TvChannels({super.key, required this.semanticsLabel});

  static const clips = [
    'assets/tv/optimized/tv_1.mp4',
    'assets/tv/optimized/tv_2.mp4',
    'assets/tv/optimized/tv_3.mp4',
    'assets/tv/optimized/tv_4.mp4',
    'assets/tv/optimized/tv_5.mp4',
  ];
  static const staticClip = 'assets/tv/optimized/tv_static.mp4';

  /// How long the static between clips lasts.
  static const staticFor = Duration(milliseconds: 900);

  @override
  State<TvChannels> createState() => _TvChannelsState();
}

class _TvChannelsState extends State<TvChannels> {
  VideoPlayerController? _clip;
  VideoPlayerController? _upcoming;
  VideoPlayerController? _static;
  int _index = 0;

  /// Showing static: between clips, or until the next one has started.
  bool _onStatic = false;
  bool _switching = false;
  Timer? _staticTimer;
  ValueListenable<bool>? _visible;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Holds still while the app is out of sight.
    AppPause.instance.addListener(_syncPlaying);
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Paused while the page is covered by another one.
    final visible = TickerMode.getNotifier(context);
    if (visible != _visible) {
      _visible?.removeListener(_syncPlaying);
      _visible = visible..addListener(_syncPlaying);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    AppPause.instance.removeListener(_syncPlaying);
    _staticTimer?.cancel();
    _visible?.removeListener(_syncPlaying);
    _clip?.dispose();
    _upcoming?.dispose();
    _static?.dispose();
    super.dispose();
  }

  /// On screen, with the app in sight.
  bool get _canPlay => (_visible?.value ?? true) && !AppPause.instance.paused;

  /// A muted controller for [asset], ready to play — or null if it can't
  /// be loaded on this device.
  Future<VideoPlayerController?> _load(String asset,
      {bool loop = false}) async {
    final c = VideoPlayerController.asset(
      asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(loop);
    } catch (_) {
      await c.dispose();
      return null;
    }
    if (_disposed) {
      await c.dispose();
      return null;
    }
    return c;
  }

  Future<void> _start() async {
    final first = await _load(TvChannels.clips[0]);
    if (first == null || _disposed) return;
    setState(() => _clip = first..addListener(_watchClip));
    if (_canPlay) await first.play();
    _static = await _load(TvChannels.staticClip, loop: true);
    _preloadNext();
  }

  void _preloadNext() {
    final next = (_index + 1) % TvChannels.clips.length;
    _load(TvChannels.clips[next]).then((c) {
      if (c == null) return;
      if (_disposed) {
        c.dispose();
        return;
      }
      _upcoming?.dispose();
      _upcoming = c;
    });
  }

  /// The clip ran out: time for static.
  void _watchClip() {
    final c = _clip;
    if (c == null || _switching || _onStatic) return;
    final v = c.value;
    if (!v.isInitialized || v.duration == Duration.zero) return;
    final ended = v.isCompleted ||
        v.position >= v.duration - const Duration(milliseconds: 80);
    if (ended) _changeChannel();
  }

  /// Static for a moment, then the next clip. Changed [byYou], with a
  /// click and a burst of static; on its own between clips, only a soft
  /// hiss.
  void _changeChannel({bool byYou = false}) {
    if (_switching || _clip == null) return;
    final sound = SoundService.instance;
    if (byYou) sound.play(Sfx.tvClick);
    // A softer hiss when it flips over by itself.
    sound.play(byYou ? Sfx.tvStatic : Sfx.tvStaticSoft);
    _switching = true;
    _clip!.pause();
    final s = _static;
    if (s != null) {
      s.seekTo(Duration.zero);
      if (_canPlay) s.play();
    }
    setState(() => _onStatic = s != null);
    _staticTimer?.cancel();
    _staticTimer = AppTimer(TvChannels.staticFor, _nextClip);
  }

  Future<void> _nextClip() async {
    if (_disposed) return;
    final next = _upcoming;
    if (next == null) {
      // Still loading — let the static run a little longer.
      _staticTimer = AppTimer(const Duration(milliseconds: 300), _nextClip);
      return;
    }
    _upcoming = null;
    final old = _clip;
    old?.removeListener(_watchClip);
    _index = (_index + 1) % TvChannels.clips.length;
    await next.seekTo(Duration.zero);
    if (_canPlay) await next.play();
    if (_disposed) return;
    setState(() {
      _clip = next..addListener(_watchClip);
      _onStatic = false;
    });
    _static?.pause();
    _switching = false;
    old?.dispose();
    _preloadNext();
  }

  void _syncPlaying() {
    final on = _canPlay;
    final active = _onStatic ? _static : _clip;
    if (active == null) return;
    on ? active.play() : active.pause();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _onStatic ? _static : _clip;
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _changeChannel(byYou: true),
        child: shown == null
            ? const SizedBox.expand()
            : ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: shown.value.size.width,
                        height: shown.value.size.height,
                        child: VideoPlayer(shown),
                      ),
                    ),
                    // The screen's glass: a little darker towards the
                    // bottom and a soft diagonal glare, so the picture sits
                    // back in the room instead of grabbing attention.
                    const IgnorePointer(child: _Glass()),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.06),
                Colors.black.withValues(alpha: 0.22),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1, -1),
              end: const Alignment(1, 1),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.35, 0.5, 0.62],
            ),
          ),
        ),
      ],
    );
  }
}
