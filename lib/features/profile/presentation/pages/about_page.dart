import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/editorial.dart';

/// "Tentang IngatanKu": version, mission, tech stack, and developer credit.
/// Editorial layout matching the rest of the app: page-title, eyebrow
/// section headers, hairline dividers, no card chrome.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Bumped manually until we wire `package_info_plus`. Mirrors the version
  // declared in `pubspec.yaml`.
  static const String _version = '0.1.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('TENTANG', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
          children: [
            Text('Tentang\nIngatanKu.', style: pageTitleStyle(size: 38)),
            const SizedBox(height: 14),
            Text(
              AppConstants.appTagline,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Catat tautan teknis sekali. Tag, ringkas, dan tanyakan ke '
              'asisten AI yang sudah kenal seluruh koleksimu.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),

            // ── DIBUAT OLEH ─────────────────────────────────────
            const SectionHeader(label: 'DIBUAT OLEH'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'TL',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TemanLabs',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Developer & maintainer',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Dibangun sepenuh hati untuk para tech-builder yang ingin '
                    'mengubah scroll harian menjadi ingatan jangka panjang.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── VERSI ──────────────────────────────────────────
            const SectionHeader(label: 'VERSI'),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _version,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'rilis awal',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── TUMPUKAN ───────────────────────────────────────
            const SectionHeader(label: 'TUMPUKAN'),
            const SizedBox(height: 4),
            const _StackRow(label: 'UI', tech: 'Flutter'),
            const ThinDivider(),
            const _StackRow(label: 'Backend & Auth', tech: 'Supabase'),
            const ThinDivider(),
            const _StackRow(label: 'Pencarian semantik', tech: 'pgvector'),
            const ThinDivider(),
            const _StackRow(label: 'Asisten AI', tech: 'LLM via edge function'),
            const SizedBox(height: 32),

            // ── TERIMA KASIH ──────────────────────────────────
            const SectionHeader(label: 'TERIMA KASIH'),
            const SizedBox(height: 12),
            Text(
              'Untuk komunitas open-source dan setiap orang yang sudah '
              'mencoba IngatanKu sejak hari pertama.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Text(
                '© ${DateTime.now().year} TemanLabs',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackRow extends StatelessWidget {
  final String label;
  final String tech;
  const _StackRow({required this.label, required this.tech});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            tech,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
