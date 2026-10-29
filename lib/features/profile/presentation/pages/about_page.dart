import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../companion/presentation/widgets/pet_host.dart';

/// "Tentang IngatanKu": version, mission, tech stack, and developer credit.
/// Editorial layout matching the rest of the app: page-title, eyebrow
/// section headers, hairline dividers, no card chrome.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: PageTopBar(
        title: l10n.aboutAppBarTitle,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: PetHost(height: 92),
            ),
            const SizedBox(height: 14),
            Text(l10n.aboutTitle, style: pageTitleStyle(context: context, size: 38)),
            const SizedBox(height: 14),
            Text(
              l10n.aboutTagline,
              style: AppFonts.body(
                fontSize: 14,
                color: context.palette.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aboutDescription,
              style: AppFonts.body(
                fontSize: 14,
                color: context.palette.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),

            // ── Made by ─────────────────────────────────────────
            SectionHeader(label: l10n.aboutSectionMaker),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: context.palette.bgSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.palette.surfaceStroke),
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
                          color: context.palette.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'TL',
                            style: AppFonts.display(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: context.palette.onPrimary,
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
                              l10n.aboutMakerName,
                              style: AppFonts.display(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: context.palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.aboutMakerRole,
                              style: AppFonts.body(
                                fontSize: 12,
                                color: context.palette.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.aboutMakerBody,
                    style: AppFonts.body(
                      fontSize: 13,
                      color: context.palette.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Version ────────────────────────────────────────
            SectionHeader(label: l10n.aboutSectionVersion),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // The installed app's own version (pubspec.yaml's, without
                // the build number).
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, info) => Text(
                    info.data?.version ?? '',
                    style: AppFonts.display(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    l10n.aboutVersionLabel,
                    style: AppFonts.body(
                      fontSize: 13,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Thanks ─────────────────────────────────────────
            SectionHeader(label: l10n.aboutSectionThanks),
            const SizedBox(height: 12),
            Text(
              l10n.aboutThanksBody,
              style: AppFonts.body(
                fontSize: 14,
                color: context.palette.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Text(
                l10n.aboutCopyright(DateTime.now().year),
                style: AppFonts.body(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: context.palette.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
