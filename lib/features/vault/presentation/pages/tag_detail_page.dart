import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/vault_note_row.dart';

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
      context.read<VaultBloc>().add(VaultLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('TAG', style: eyebrowStyle()),
      ),
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
                color: AppColors.primary,
                onRefresh: () async =>
                    context.read<VaultBloc>().add(VaultLoadRequested()),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                  children: [
                    Text('#${widget.tag}', style: pageTitleStyle(size: 38)),
                    const SizedBox(height: 6),
                    Text(
                      filtered.isEmpty
                          ? 'Belum ada catatan dengan tag ini.'
                          : '${filtered.length} catatan terkait',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textTertiary,
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
                            if (i != filtered.length - 1)
                              const ThinDivider(),
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
