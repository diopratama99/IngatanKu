import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/vault_note_row.dart';
import '../../../../core/theme/app_fonts.dart';

/// Tag detail / filtered-notes page. Opened from the dashboard "Tag teratas"
/// row and PETA PENGETAHUAN chips. Shows the tag header (name + count) and
/// every note in the vault that carries this tag.
class TagDetailPage extends StatefulWidget {
  final String tag;
  const TagDetailPage({super.key, required this.tag});

  @override
  State<TagDetailPage> createState() => _TagDetailPageState();
}

class _TagDetailPageState extends State<TagDetailPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<VaultBloc>().state;
    if (state is! VaultLoaded) {
      context.read<VaultBloc>().add(const VaultLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: PageTopBar(title: l10n.tagDetailEyebrow),
      body: SafeArea(
        child: BlocBuilder<VaultBloc, VaultState>(
          builder: (_, state) {
            if (state is VaultLoading || state is VaultInitial) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: ShimmerBox(height: 48, radius: 4),
                ),
              );
            }
            if (state is VaultError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    style: context.textStyles.bodyMedium,
                  ),
                ),
              );
            }
            if (state is VaultLoaded) {
              final filtered = state.notes
                  .where((n) => n.tags.contains(widget.tag))
                  .toList();
              return RefreshIndicator(
                color: context.palette.primary,
                onRefresh: () async => context
                    .read<VaultBloc>()
                    .add(const VaultLoadRequested(fetch: true)),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                  children: [
                    Text('#${widget.tag}',
                        style: pageTitleStyle(context: context, size: 38)),
                    const SizedBox(height: 6),
                    Text(
                      filtered.isEmpty
                          ? l10n.tagDetailEmpty
                          : l10n.tagDetailNoteCount(filtered.length),
                      style: AppFonts.body(
                        fontSize: 13,
                        color: context.palette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const ThinDivider(),
                    if (filtered.isEmpty)
                      _EmptyTagState(tag: widget.tag)
                    else
                      ...List.generate(filtered.length, (i) {
                        final n = filtered[i];
                        return Column(
                          children: [
                            VaultNoteRow(
                              note: n,
                              onTap: () =>
                                  context.push('/vault/${n.id}', extra: n),
                            ),
                            if (i != filtered.length - 1) const ThinDivider(),
                          ],
                        );
                      }),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _EmptyTagState extends StatelessWidget {
  final String tag;
  const _EmptyTagState({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'Tag #$tag tidak terpasang di catatan manapun saat ini. '
        'Tambahkan tag ini saat mengedit catatan untuk mengelompokkannya di sini.',
        style: context.textStyles.bodyMedium,
      ),
    );
  }
}
