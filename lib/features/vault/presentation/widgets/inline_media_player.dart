import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/media_download_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/source_meta.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';
import '../../../notes/domain/entities/personal_note.dart';
import '../../../notes/presentation/widgets/note_color_palette.dart';

/// Inline preview widget for the note detail page. Behaviour by platform:
///
///   • instagram / tiktok / x / youtube / threads / facebook → if a
///     previously downloaded local file exists, plays directly from
///     disk (instant, no network). Otherwise calls `resolve-media` and
///     streams via Cobalt's tunnel URL on demand.
///   • everything else → falls back to the thumbnail (if any) and renders
///     nothing when none is available.
///
/// Two presentations:
///   * default — 16:9 framed card (used for sub-page placement).
///   * fullBleed — fills its parent with no aspect-ratio constraint and
///     uses BoxFit.cover for portrait reels content. Used by the
///     IG-style detail page.
class InlineMediaPlayer extends StatefulWidget {
  /// Note ID — used to look up any previously-downloaded local file via
  /// [MediaDownloadService]. When provided and a file exists, playback
  /// uses that file directly (zero network).
  final String? noteId;

  /// Source URL of the note.
  final String sourceUrl;

  /// `youtube`, `tiktok`, `instagram`, `x`, `article`, …
  final String sourceType;

  /// Pre-fetched thumbnail (from `fetch-meta`). Used as the placeholder
  /// behind the play button and the final cover when no video is
  /// playable.
  final String? thumbnailUrl;

  /// When true, any active playback is paused. Used by the Reels-style
  /// detail feed: when the user swipes to a different note, the previous
  /// page's player auto-pauses so audio doesn't bleed across pages.
  final bool autoPause;

  /// When true, the widget fills its parent (no rounded 16:9 frame) and
  /// the video/thumbnail uses BoxFit.cover so the content sits flush
  /// against the screen edges.
  final bool fullBleed;

  /// When true, video playback loops indefinitely — matches IG reels and
  /// TikTok behaviour. Only respected for video resolutions (photos
  /// don't loop).
  final bool loop;

  const InlineMediaPlayer({
    super.key,
    this.noteId,
    required this.sourceUrl,
    required this.sourceType,
    this.thumbnailUrl,
    this.autoPause = false,
    this.fullBleed = false,
    this.loop = false,
  });

  @override
  State<InlineMediaPlayer> createState() => _InlineMediaPlayerState();
}

class _InlineMediaPlayerState extends State<InlineMediaPlayer> {
  VideoPlayerController? _controller;
  MediaResolution? _resolution;
  bool _resolving = false;
  bool _autoPlayPending = false;
  String? _error;

  /// Local file matched by `noteId`. When non-null, we play directly
  /// from disk instead of streaming via Cobalt — instant start and no
  /// chance of an expired tunnel URL mid-playback.
  File? _localFile;

  /// True when the local file is a still image (jpg/png/webp/etc) —
  /// rendered as a static cover instead of routed through video_player.
  bool get _localIsImage {
    final f = _localFile;
    if (f == null) return false;
    final ext = f.path.split('.').last.toLowerCase();
    return ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'png' ||
        ext == 'webp' ||
        ext == 'gif' ||
        ext == 'heic';
  }

  /// Whether the platform is supported by the resolve-media path.
  /// Articles don't have a playable artifact; everything else (including
  /// YouTube via Cobalt's adaptive stream) goes through resolve-media.
  bool get _supportsResolve =>
      SourceMeta.supportsCobaltResolve(widget.sourceType);

  @override
  void initState() {
    super.initState();
    _hydrateLocalFile();
  }

  /// Look up any previously-downloaded file for this note. If found we
  /// surface a "PUTAR (TERSIMPAN)" cover so the user knows playback
  /// will be instant; tapping plays from disk via [_playLocal].
  Future<void> _hydrateLocalFile() async {
    final id = widget.noteId;
    if (id == null) return;
    try {
      final f = await sl<MediaDownloadService>().existingFile(id);
      if (!mounted || f == null) return;
      setState(() => _localFile = f);
    } catch (_) {/* non-fatal — caller still gets the streaming path */}
  }

  /// Initialise the controller against the local file. Same lifecycle
  /// as the streaming path but without a network round-trip.
  Future<void> _playLocal() async {
    final f = _localFile;
    if (f == null || _resolving) return;
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final controller = VideoPlayerController.file(
        f,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.setLooping(widget.loop);
      _controller = controller;
      _autoPlayPending = !widget.autoPause;
      setState(() => _resolving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _controller != null &&
            _autoPlayPending &&
            !widget.autoPause) {
          _controller!.play();
          _autoPlayPending = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = _friendlyError(e);
      });
    }
  }

  @override
  void didUpdateWidget(covariant InlineMediaPlayer old) {
    super.didUpdateWidget(old);
    final c = _controller;
    // React to autoPause toggling — when the page becomes inactive, pause
    // playback; we deliberately don't auto-resume on activation so the
    // user is in control of when audio starts again.
    if (c != null && widget.autoPause && c.value.isPlaying) {
      c.pause();
    }
    // Re-probe for a local file if either the noteId changed or the
    // user has just downloaded the artifact via the offline sheet (we
    // don't get an explicit notification, but a parent rebuild will
    // land us here). Skip the probe when playback is already active.
    if (_controller == null && _localFile == null) {
      _hydrateLocalFile();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// HTTP headers to send when fetching the resolved tunnel URL. Cobalt
  /// streams sometimes route through CDNs that reject the default
  /// ExoPlayer UA — the most common symptom is `401 Unauthorized` on
  /// Instagram and `403 Forbidden` on TikTok. Pretending to be a
  /// desktop Chrome request avoids that gate.
  ///
  /// We deliberately don't set `Referer` for Instagram (their CDN cross
  /// -checks it against the rendered page and rejects ours) but do for
  /// TikTok / X / YouTube since their CDNs whitelist their own host.
  static Map<String, String> _playbackHeaders(String sourceType) {
    const ua =
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
    final base = <String, String>{'User-Agent': ua};
    switch (sourceType) {
      case 'tiktok':
        base['Referer'] = 'https://www.tiktok.com/';
        break;
      case 'x':
        base['Referer'] = 'https://twitter.com/';
        break;
      case 'youtube':
        base['Referer'] = 'https://www.youtube.com/';
        break;
      case 'threads':
        base['Referer'] = 'https://www.threads.net/';
        break;
      // instagram + facebook → no referer; Meta CDN cross-checks against
      // the rendered page and rejects ours.
    }
    return base;
  }

  Future<void> _resolveAndPlay() async {
    if (kIsWeb) {
      setState(() => _error = AppLocalizations.of(context)!.playerErrWeb);
      return;
    }
    if (_resolving) return;
    if (!await ensureOnline(context, OnlineFeature.video) || !mounted) return;
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final svc = sl<MediaDownloadService>();
      final res = await svc.resolve(widget.sourceUrl);
      if (!mounted) return;
      _resolution = res;

      if (res.isPhoto) {
        // For photo posts we just swap the thumbnail to the
        // higher-resolution download URL — no video controller needed.
        setState(() => _resolving = false);
        return;
      }

      // Initialise the video controller from the resolved tunnel URL.
      // Cobalt URLs are short-lived but each new resolve call mints a
      // fresh one, so we re-resolve on every page open.
      //
      // ExoPlayer (video_player on Android) by default sends a Java UA
      // string, which Instagram/TikTok CDNs reject with a 401. We pass
      // a desktop browser UA and a platform-appropriate Referer so the
      // CDN treats the request like a normal embed.
      final headers = _playbackHeaders(widget.sourceType);
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(res.downloadUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        httpHeaders: headers,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.setLooping(widget.loop);
      _controller = controller;
      _autoPlayPending = !widget.autoPause;
      setState(() => _resolving = false);
      // Kick off playback after the next frame so the layout has time
      // to apply the new aspect ratio without flashing audio first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _controller != null &&
            _autoPlayPending &&
            !widget.autoPause) {
          _controller!.play();
          _autoPlayPending = false;
        }
      });
    } on MediaDownloadException catch (e) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = isOfflineError(e.message) ? null : e.message;
      });
      if (isOfflineError(e.message)) _offline();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = isOfflineError(e) ? null : _friendlyError(e);
      });
      if (isOfflineError(e)) _offline();
    }
  }

  /// No connection: the pet says so (the play button stays, to try again).
  void _offline() => showPetOffline(context, OnlineFeature.video);

  /// Map low-level player/network exceptions to friendly copy. video_player surfaces ExoPlayer errors as "PlatformException"
  /// with messages like `Source error` or `Unauthorized` — which mean
  /// nothing to a user.
  String _friendlyError(Object e) {
    final l10n = AppLocalizations.of(context)!;
    final raw = e.toString().toLowerCase();
    if (raw.contains('401') || raw.contains('unauthorized')) {
      return l10n.playerErrRefused;
    }
    if (raw.contains('403') || raw.contains('forbidden')) {
      return l10n.playerErrForbidden;
    }
    if (raw.contains('404')) return l10n.playerErrNotFound;
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return l10n.playerErrTimeout;
    }
    if (raw.contains('source error') || raw.contains('exoplayback')) {
      return l10n.playerErrLoad;
    }
    return l10n.playerErrOther;
  }

  /// Hand the user off to the platform's native app for the source URL.
  /// Used as the fallback CTA when inline playback fails — Instagram /
  /// TikTok / YouTube apps handle the auth gates we can't.
  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.sourceUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget wrap(Widget child) =>
        widget.fullBleed ? child : _Frame(child: child);

    // For platforms we don't resolve, only show a thumbnail cover.
    if (!_supportsResolve) {
      if (widget.thumbnailUrl == null) return const SizedBox.shrink();
      return wrap(_Thumbnail(url: widget.thumbnailUrl!, cover: true));
    }

    // 1) Playable video controller is ready → render the player.
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      return wrap(_PlayerSurface(
        controller: c,
        cover: widget.fullBleed,
        showProgress: !widget.fullBleed,
      ));
    }

    // 2a) Local file is a still image → render directly from disk.
    if (_localFile != null && _localIsImage) {
      return wrap(_LocalImage(file: _localFile!));
    }

    // 2b) Cobalt returned a photo (no local) → render the higher-res
    //     image inline.
    final res = _resolution;
    if (res != null && res.isPhoto) {
      return wrap(_Thumbnail(url: res.downloadUrl, cover: true));
    }

    // 3) Cover state — thumbnail behind a play CTA. When a local video
    //    file exists we route the tap to the zero-network playback
    //    path; otherwise we fall back to resolve + stream.
    final hasLocalVideo = _localFile != null && !_localIsImage;
    return wrap(Stack(
      fit: StackFit.expand,
      children: [
        // Prefer a local frame thumbnail when we have the file but
        // haven't started playback yet — falls back to the network
        // thumbnail or a flat backdrop.
        if (widget.thumbnailUrl != null)
          _Thumbnail(url: widget.thumbnailUrl!, cover: true)
        else
          Container(color: context.palette.bgTertiary),
        // Subtle dim so the play button sits on a darker gradient and
        // remains legible against bright thumbnails.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.32),
              ],
            ),
          ),
        ),
        Center(
          child: _PlayCta(
            busy: _resolving,
            error: _error,
            onTap: hasLocalVideo ? _playLocal : _resolveAndPlay,
            onOpenExternal: _error != null ? _openExternal : null,
            isLocal: hasLocalVideo,
          ),
        ),
      ],
    ));
  }
}

/// 16:9 rounded container — kept consistent across all states so the
/// page doesn't reflow between cover ↔ player.
class _Frame extends StatelessWidget {
  final Widget child;
  const _Frame({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: context.palette.bgSecondary,
          child: child,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;
  final bool cover;
  const _Thumbnail({required this.url, this.cover = true});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: cover ? BoxFit.cover : BoxFit.contain,
      placeholder: (_, __) => Container(color: context.palette.bgTertiary),
      errorWidget: (_, __, ___) => Container(
        color: context.palette.bgTertiary,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined,
            size: 28, color: context.palette.textTertiary),
      ),
    );
  }
}

/// Renders a downloaded photo straight from disk. Used when the user
/// has saved an Instagram/Facebook still post offline.
class _LocalImage extends StatelessWidget {
  final File file;
  const _LocalImage({required this.file});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Container(
        color: context.palette.bgTertiary,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined,
            size: 28, color: context.palette.textTertiary),
      ),
    );
  }
}

class _PlayerSurface extends StatefulWidget {
  final VideoPlayerController controller;

  /// When true, fill the parent and crop the video (BoxFit.cover) — the
  /// fullscreen reels presentation. When false, the video is contained
  /// inside an aspect-correct box (the legacy framed presentation).
  final bool cover;

  /// When true, paint a thin scrubbable progress bar at the bottom of
  /// the player. Disabled in fullBleed mode where the bottom UI overlay
  /// already crowds the area.
  final bool showProgress;

  const _PlayerSurface({
    required this.controller,
    this.cover = false,
    this.showProgress = true,
  });

  @override
  State<_PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends State<_PlayerSurface> {
  bool _showPlayOverlay = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final size = c.value.size;
    final hasSize = size.width > 0 && size.height > 0;
    final videoBox = hasSize
        ? SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(c),
          )
        : const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        c.value.isPlaying ? c.pause() : c.play();
        if (mounted) setState(() => _showPlayOverlay = !c.value.isPlaying);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Black backdrop so any letterboxing in cover-mode reads as
          // intentional (matches reels conventions).
          Container(color: Colors.black),
          if (widget.cover)
            // BoxFit.cover behaviour — the FittedBox+SizedBox combo gives
            // us the same crop semantics that Image.cover would.
            FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: videoBox,
            )
          else
            FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: videoBox,
            ),
          if (!c.value.isPlaying || _showPlayOverlay)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: c.value.isPlaying ? 0 : 1,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 36, color: Colors.white),
                ),
              ),
            ),
          if (widget.showProgress)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                colors: VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white.withValues(alpha: 0.30),
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The play button over a cover: a round cream button with the play mark,
/// what it'll do on a little paper label under it — or, when playing
/// failed, why, with a way to try again or open the source.
class _PlayCta extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback? onOpenExternal;
  final bool isLocal;
  const _PlayCta({
    required this.busy,
    required this.error,
    required this.onTap,
    this.onOpenExternal,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final paper = NoteColorPalette.background(NoteColor.defaultColor);
    final edge = NoteColorPalette.border(NoteColor.defaultColor);
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ];
    final label = busy
        ? l10n.playerPreparing
        : error != null
            ? l10n.playerRetry
            : isLocal
                ? l10n.playerPlaySaved
                : l10n.playerPlay;
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: busy ? null : onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: paper,
                shape: BoxShape.circle,
                border: Border.all(color: edge, width: 1.5),
                boxShadow: shadow,
              ),
              child: busy
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: palette.primary,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Icon(
                      error == null
                          ? Icons.play_arrow_rounded
                          : Icons.refresh_rounded,
                      size: 36,
                      color: palette.primary,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: paper,
              borderRadius: BorderRadius.circular(20),
              boxShadow: shadow,
            ),
            child: Text(
              label,
              style: AppFonts.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: edge),
                boxShadow: shadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: AppFonts.body(
                      fontSize: 12.5,
                      height: 1.4,
                      color: palette.textSecondary,
                    ),
                  ),
                  if (onOpenExternal != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onOpenExternal,
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: Text(l10n.playerOpenSource),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.primary,
                        textStyle: AppFonts.body(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
