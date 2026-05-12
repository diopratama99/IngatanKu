import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/vault_note_row.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<VaultBloc>().add(VaultLoadRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BRANKAS', style: eyebrowStyle()),
                  const SizedBox(height: 8),
                  Text('Catatanmu.', style: pageTitleStyle(size: 36)),
                  const SizedBox(height: 4),
                  BlocBuilder<VaultBloc, VaultState>(
                    builder: (_, state) {
                      final n = state is VaultLoaded ? state.notes.length : 0;
                      return Text(
                        n == 0 ? 'Belum ada catatan' : '$n catatan tersimpan',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _EditorialSearchField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                  ),
                ],
              ),
            ),
            const ThinDivider(),
            Expanded(
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
                        child: Text(state.message,
                            style: context.textStyles.bodyMedium),
                      ),
                    );
                  }
                  if (state is VaultLoaded) {
                    final notes = state.notes.where((n) {
                      if (_query.isEmpty) return true;
                      return n.title?.toLowerCase().contains(_query) == true ||
                          n.manualNotes.toLowerCase().contains(_query) ||
                          n.tags.any((t) => t.toLowerCase().contains(_query));
                    }).toList();

                    if (notes.isEmpty) return _EmptyState(query: _query);

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async =>
                          context.read<VaultBloc>().add(VaultLoadRequested()),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 96),
                        itemCount: notes.length,
                        itemBuilder: (_, i) {
                          final n = notes[i];
                          return Column(
                            children: [
                              VaultNoteRow(
                                note: n,
                                onTap: () =>
                                    context.push('/vault/${n.id}', extra: n),
                              ),
                              if (i != notes.length - 1) const ThinDivider(),
                            ],
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-note-fab',
        onPressed: () => context.push(Routes.addNote),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Catatan baru',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: const _LiftedFabLocation(
        FloatingActionButtonLocation.endFloat,
        kEditorialNavBarOverlay,
      ),
    );
  }
}

/// Wraps another [FloatingActionButtonLocation] and lifts the FAB up by
/// [lift] logical pixels. Used to keep the vault FAB visible above the
/// floating editorial nav bar overlay.
class _LiftedFabLocation extends FloatingActionButtonLocation {
  final FloatingActionButtonLocation base;
  final double lift;
  const _LiftedFabLocation(this.base, this.lift);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final offset = base.getOffset(scaffoldGeometry);
    return Offset(offset.dx, offset.dy - lift);
  }
}

class _EditorialSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _EditorialSearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceStroke, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search_rounded,
                size: 18, color: AppColors.textTertiary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Cari judul, isi, atau #tag…',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            query.isEmpty ? 'BRANKAS KOSONG' : 'TIDAK DITEMUKAN',
            style: eyebrowStyle(),
          ),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? 'Mulai\nmenulis' : '"$query"\ntidak\nada',
            style: pageTitleStyle(size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            query.isEmpty
                ? 'Tap "Catatan baru" di pojok kanan bawah untuk menyimpan tautan pertamamu — kamu akan dapat 10 XP.'
                : 'Coba kata kunci lain, atau bersihkan pencarian.',
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
