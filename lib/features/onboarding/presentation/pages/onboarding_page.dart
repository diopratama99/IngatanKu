import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../companion/data/pet_store.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/presentation/pet_labels.dart';
import '../../../companion/presentation/widgets/blob_mascot.dart';
import '../../../companion/presentation/widgets/food_painter.dart';
import '../../../companion/presentation/widgets/pet_naming_sheet.dart';
import '../../../companion/presentation/widgets/pet_speech_bubble.dart';

/// The welcome story shown to fresh sign-ups right after their email OTP
/// is verified: meet the pet (still in its egg), feed it what you find,
/// watch it grow, then ask and quiz. Swipe or tap through; existing users
/// coming through normal sign-in skip this entirely.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_SlideData> _slides(AppLocalizations l10n) => [
        _SlideData(
          title: l10n.onboardMeetTitle,
          subtitle: l10n.onboardMeetBody,
          visual: const _MeetVisual(),
        ),
        _SlideData(
          title: l10n.onboardFeedTitle,
          subtitle: l10n.onboardFeedBody,
          visual: const _FeedVisual(),
        ),
        _SlideData(
          title: l10n.onboardGrowTitle,
          subtitle: l10n.onboardGrowBody,
          visual: const _GrowVisual(),
        ),
        _SlideData(
          title: l10n.onboardAskTitle,
          subtitle: l10n.onboardAskBody,
          visual: const _AskVisual(),
        ),
      ];

  void _next(int count) {
    if (_currentIndex < count - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      // "Let's go!" — off on the adventure.
      SoundService.instance.play(Sfx.start);
      _finish();
    }
  }

  /// Whether finishing has begun, so a second tap doesn't ask twice.
  bool _finishing = false;

  /// Into the house — after giving the pet its name (skipping the story
  /// still asks: the name is part of meeting it).
  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    // Asked here, so Beranda doesn't ask again.
    final user = sl<SupabaseService>().currentUserId;
    if (user != null) sl<PetStore>().markNamingAsked(user);
    await showPetNaming(context);
    if (mounted) context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final slides = _slides(l10n);
    final isLastPage = _currentIndex == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 14, 14, 0),
              child: Row(
                children: [
                  Text(
                    '${(_currentIndex + 1).toString().padLeft(2, '0')} / '
                    '${slides.length.toString().padLeft(2, '0')}',
                    style: eyebrowStyle(context: context),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isLastPage ? 0 : 1,
                    child: TextButton(
                      onPressed: isLastPage ? null : _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: palette.textTertiary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.onboardSkip),
                    ),
                  ),
                ],
              ),
            ),

            // ── Slides ─────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  SoundService.instance.play(Sfx.swipe);
                  setState(() => _currentIndex = i);
                },
                itemCount: slides.length,
                itemBuilder: (ctx, i) => _Slide(data: slides[i]),
              ),
            ),

            // ── Bottom bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 22, 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(slides.length, (i) {
                      final active = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: active ? 26 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? palette.primary
                              : palette.primaryMuted,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _next(slides.length),
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.fromLTRB(24, 14, 18, 14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isLastPage ? l10n.onboardStart : l10n.onboardNext),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                          SLIDE FRAME
// ════════════════════════════════════════════════════════════════

class _SlideData {
  final String title;
  final String subtitle;
  final Widget visual;
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.visual,
  });
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          SizedBox(height: 230, child: Center(child: data.visual)),
          const Spacer(flex: 1),
          Text(data.title, style: pageTitleStyle(context: context, size: 42)),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: AppFonts.body(
              fontSize: 15,
              color: context.palette.textSecondary,
              height: 1.55,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                          SLIDE VISUALS
// ════════════════════════════════════════════════════════════════

/// The user's pet as it is right now (an egg, for someone who's just
/// signed up), or at [stage].
class _Pet extends StatelessWidget {
  final double size;
  final PetStage? stage;
  final bool glasses;
  final BlobExpression? expression;
  const _Pet({
    required this.size,
    this.stage,
    this.glasses = false,
    this.expression,
  });

  @override
  Widget build(BuildContext context) {
    final store = sl<PetStore>();
    // Laid out by its body (the canvas around it is mostly headroom), so
    // pets can stand side by side.
    return SizedBox(
      width: size * 0.8,
      height: size * 0.9,
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: BlobMascot(
          size: size,
          color: store.color,
          accessory: store.accessory,
          outfit: store.outfit,
          stage: stage ?? store.state.stage,
          glasses: glasses,
          expression: expression,
          interactive: false,
        ),
      ),
    );
  }
}

/// A soft round rug on the floor, for a pet to stand on.
class _Spotlight extends StatelessWidget {
  final double width;
  const _Spotlight({required this.width});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 0.22),
      painter: _RugPainter(context.palette.primaryMuted),
    );
  }
}

class _RugPainter extends CustomPainter {
  final Color color;
  _RugPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Offset.zero & size,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.18),
    );
  }

  @override
  bool shouldRepaint(_RugPainter old) => old.color != color;
}

/// Slide 1: the pet (still an egg) in a pool of warm light.
class _MeetVisual extends StatelessWidget {
  const _MeetVisual();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 240,
      height: 230,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(bottom: 6, child: _Spotlight(width: 190)),
          Positioned(bottom: 14, child: _Pet(size: 150)),
        ],
      ),
    );
  }
}

/// Slide 2: a saved video turning into a dish, and a hungry pet.
class _FeedVisual extends StatelessWidget {
  const _FeedVisual();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 300,
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
              right: 12, bottom: 6, child: _Spotlight(width: 150)),
          // The link you shared, as a little card.
          Positioned(
            left: 0,
            top: 18,
            child: Transform.rotate(
              angle: -0.07,
              child: Container(
                width: 128,
                padding: const EdgeInsets.all(10),
                decoration: softCard(context, radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(Icons.play_circle_fill_rounded,
                            size: 26, color: palette.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final w in [86.0, 58.0]) ...[
                      Container(
                        width: w,
                        height: 6,
                        decoration: BoxDecoration(
                          color: palette.surfaceStroke,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // … becomes a meal …
          Positioned(
            left: 134,
            top: 58,
            child: Icon(Icons.east_rounded,
                size: 22, color: palette.textTertiary),
          ),
          const Positioned(
            left: 164,
            top: 36,
            child: FoodIcon(kind: FoodKind.bento, size: 58),
          ),
          // … for a hungry pet.
          const Positioned(
            right: 25,
            bottom: 16,
            child: _Pet(
              size: 140,
              stage: PetStage.baby,
              expression: BlobExpression.hungry,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 3: egg → baby → kid → sage, side by side.
class _GrowVisual extends StatelessWidget {
  const _GrowVisual();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    const stages = [
      (PetStage.egg, 92.0),
      (PetStage.baby, 92.0),
      (PetStage.kid, 92.0),
      (PetStage.sage, 92.0),
    ];
    return SizedBox(
      width: 320,
      height: 230,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const Positioned(bottom: 18, child: _Spotlight(width: 320)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final (stage, size) in stages)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Pet(size: size, stage: stage),
                    const SizedBox(height: 6),
                    Text(
                      l10n.stageLabel(stage),
                      style: AppFonts.body(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slide 4: the pet in its reading glasses, ready for questions — and the
/// weekly quiz.
class _AskVisual extends StatelessWidget {
  const _AskVisual();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return SizedBox(
      width: 300,
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(left: 4, bottom: 6, child: _Spotlight(width: 150)),
          const Positioned(
            left: 23,
            bottom: 16,
            child: _Pet(
              size: 140,
              stage: PetStage.kid,
              glasses: true,
            ),
          ),
          Positioned(
            left: 128,
            top: 40,
            child: PetSpeechBubble(
              text: l10n.onboardAskBubble,
              maxWidth: 150,
              tailLeft: true,
            ),
          ),
          // A quiz card with the right answer ticked.
          Positioned(
            right: 4,
            bottom: 12,
            child: Transform.rotate(
              angle: 0.05,
              child: Container(
                width: 132,
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                decoration: softCard(context, radius: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weeklyQuizAppBarTitle,
                      style: eyebrowStyle(context: context)
                          .copyWith(fontSize: 9),
                    ),
                    const SizedBox(height: 7),
                    for (final right in [false, true]) ...[
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: right
                                  ? palette.success
                                  : Colors.transparent,
                              border: Border.all(
                                color: right
                                    ? palette.success
                                    : palette.surfaceStroke,
                                width: 1.5,
                              ),
                            ),
                            child: right
                                ? const Icon(Icons.check_rounded,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: right ? 70 : 54,
                            height: 6,
                            decoration: BoxDecoration(
                              color: palette.surfaceStroke,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
