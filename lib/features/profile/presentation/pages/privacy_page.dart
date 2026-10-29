import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../core/theme/app_fonts.dart';

/// Static informational page summarising what data IngatanKu stores, where
/// it lives, and what rights the user has. Editorial in tone; intentionally
/// not a long legalese document. Surfaces the essentials with hairline
/// section dividers in line with the rest of the app.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: PageTopBar(
        title: l10n.privacyAppBarTitle,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
          children: [
            Text(l10n.privacyTitle, style: pageTitleStyle(context: context, size: 38)),
            const SizedBox(height: 14),
            Text(
              l10n.privacyIntro,
              style: AppFonts.body(
                fontSize: 14,
                color: context.palette.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 36),
            SectionHeader(label: l10n.privacySectionGiven),
            const SizedBox(height: 12),
            _BulletList([
              l10n.privacyGiven1,
              l10n.privacyGiven2,
              l10n.privacyGiven3,
              l10n.privacyGiven4,
            ]),
            const SizedBox(height: 32),
            SectionHeader(label: l10n.privacySectionWhere),
            const SizedBox(height: 12),
            _Paragraph(l10n.privacyWhereBody),
            const SizedBox(height: 32),
            SectionHeader(label: l10n.privacySectionDont),
            const SizedBox(height: 12),
            _BulletList([
              l10n.privacyDont1,
              l10n.privacyDont2,
              l10n.privacyDont3,
            ]),
            const SizedBox(height: 32),
            SectionHeader(label: l10n.privacySectionRights),
            const SizedBox(height: 12),
            _BulletList([
              l10n.privacyRights1,
              l10n.privacyRights2,
              l10n.privacyRights3,
            ]),
            const SizedBox(height: 32),
            SectionHeader(label: l10n.privacySectionContact),
            const SizedBox(height: 12),
            _Paragraph(l10n.privacyContactBody),
          ],
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.body(
        fontSize: 14,
        color: context.palette.textSecondary,
        height: 1.6,
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList(this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 12),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.palette.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppFonts.body(
                        fontSize: 14,
                        color: context.palette.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
