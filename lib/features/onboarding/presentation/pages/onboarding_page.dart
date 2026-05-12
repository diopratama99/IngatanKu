import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/editorial.dart';

/// Multi-step welcome flow shown to fresh sign-ups right after their email
/// OTP is verified. Four editorial slides — brand, capture, ask, streak —
/// with swipe + dot indicator + a primary "Lanjut / Mulai" CTA. Existing
/// users coming through normal sign-in skip this entirely (they're routed
/// straight to /dashboard from `LoginPage`).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late final List<_SlideData> _slides;

  @override
  void initState() {
    super.initState();
    _slides = const [
      _SlideData(
        title: 'Hai,\nselamat\ndatang.',
        subtitle:
            'IngatanKu adalah otak kedua untuk tautan teknismu. Catat sekali, ingat selamanya.',
        visual: _BrandMarkVisual(),
      ),
      _SlideData(
        title: 'Catat,\nbiar AI\nyang ringkas.',
        subtitle:
            'Tempel tautan apapun. Asisten otomatis ekstrak judul, ringkas isinya, dan kasih tag.',
        visual: _NoteCardVisual(),
      ),
      _SlideData(
        title: 'Tanya\nasistenmu.',
        subtitle:
            'Asistenmu sudah baca seluruh catatan. Tanya apa saja, jawabannya datang langsung dari koleksimu.',
        visual: _ChatVisual(),
      ),
      _SlideData(
        title: 'Pertahankan\nritmemu.',
        subtitle:
            'Catat tiap hari, kumpulkan lencana, dan jaga streak belajarmu tetap menyala.',
        visual: _BadgeVisual(),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() => context.go(Routes.dashboard);

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                    '${_slides.length.toString().padLeft(2, '0')}',
                    style: eyebrowStyle(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textTertiary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'LEWATI',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── PageView slides ────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemCount: _slides.length,
                itemBuilder: (ctx, i) => _Slide(data: _slides[i]),
              ),
            ),

            // ── Bottom bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 22, 24),
              child: Row(
                children: [
                  // Dot / pill indicator
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final active = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 6),
                        height: 4,
                        width: active ? 28 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.surfaceStroke,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),

                  // Primary CTA
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastPage ? 'MULAI' : 'LANJUT',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
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
          // Visual sits in the upper third
          SizedBox(
            height: 200,
            child: Center(child: data.visual),
          ),
          const Spacer(flex: 1),
          // Editorial title
          Text(data.title, style: pageTitleStyle(size: 44)),
          const SizedBox(height: 18),
          // Subtitle
          Text(
            data.subtitle,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
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

/// Slide 1: the actual app launcher icon (rounded-square IK monogram on
/// indigo) with a soft primary glow underneath — mirrors what the user
/// sees on their home screen so the brand association lands immediately.
///
/// The PNG already has its own pre-baked rounded corners, so the outer
/// [Container] handles only the shadow and the inner [ClipRRect] safeguards
/// against any edge-bleed if the source ships with non-premultiplied alpha.
class _BrandMarkVisual extends StatelessWidget {
  const _BrandMarkVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      height: 144,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.40),
            blurRadius: 56,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: 144,
          height: 144,
          fit: BoxFit.cover,
          // Crisp at 144px even though source is 1024×1024 — we let the
          // GPU bilinear-downsample. `filterQuality: medium` is the sweet
          // spot for static brand marks (no aliasing, no over-soft).
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Slide 2: two stacked "note cards" — back card faded, front card with
/// indigo border, hairlines for body text, two tag pills. Suggests the
/// vault without screenshotting it.
class _NoteCardVisual extends StatelessWidget {
  const _NoteCardVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back card (rotated, faded)
          Positioned(
            top: 8,
            right: 4,
            child: Transform.rotate(
              angle: 0.06,
              child: Container(
                width: 220,
                height: 116,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceStroke),
                ),
              ),
            ),
          ),
          // Front card with content
          Positioned(
            bottom: 8,
            left: 4,
            child: Transform.rotate(
              angle: -0.04,
              child: Container(
                width: 240,
                height: 134,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 180, height: 9, color: AppColors.textPrimary),
                    const SizedBox(height: 8),
                    Container(
                        width: 140, height: 6, color: AppColors.textTertiary),
                    const SizedBox(height: 6),
                    Container(
                        width: 110, height: 6, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        _TagPill(label: '#flutter'),
                        SizedBox(width: 6),
                        _TagPill(label: '#async'),
                      ],
                    ),
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

class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Slide 3: a mini chat thread showing how the assistant pulls from the
/// user's notes. User question on the right (neutral), assistant answer
/// on the left (indigo), with a citation-style timestamp inline.
class _ChatVisual extends StatelessWidget {
  const _ChatVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // User bubble — right aligned
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 200),
              decoration: const BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(2),
                ),
              ),
              child: Text(
                'Apa itu pgvector?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // AI bubble — left, indigo
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              constraints: const BoxConstraints(maxWidth: 230),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                'Dari catatanmu — ekstensi Postgres untuk pencarian vektor.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 4: streak medallion — circular indigo badge with a flame, big
/// SpaceGrotesk number for current streak, eyebrow caption underneath.
class _BadgeVisual extends StatelessWidget {
  const _BadgeVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.40),
                blurRadius: 48,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 60,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '07',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text('HARI BERUNTUN', style: eyebrowStyle()),
      ],
    );
  }
}
