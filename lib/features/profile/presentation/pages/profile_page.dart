import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// Shows a confirmation dialog before dispatching [AuthSignOutRequested].
  /// We grab the bloc reference *before* the await so we don't have to use
  /// `BuildContext` across an async gap (avoids `use_build_context_synchronously`).
  ///
  /// Styled to match the rest of the editorial dark theme:
  ///   * SpaceGrotesk display title, Inter body
  ///   * Hairline stroke border + slightly tighter radius
  ///   * "Batal" muted (textTertiary) and "Keluar" in danger red so the
  ///     destructive option is the only visually loud choice on screen.
  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.surfaceStroke, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 14, 12),
        title: Text(
          'Yakin ingin keluar?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
        ),
        content: Text(
          'Kamu harus masuk lagi untuk membuka catatanmu.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(AuthSignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state is Authenticated
        ? (context.read<AuthBloc>().state as Authenticated).user
        : null;

    final initial =
        (user?.username ?? user?.email ?? '?').substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('PROFIL', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            // ─── Identity block ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? 'Anonim',
                        style: pageTitleStyle(size: 26),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sign-out trigger lives next to the identity block. Compact
                // icon button with the danger color so the action reads as
                // "this is your account exit" without a full-width red row.
                // Tap goes through a confirmation dialog so the user doesn't
                // accidentally sign out and lose their session.
                IconButton(
                  tooltip: 'Keluar',
                  onPressed: () => _confirmSignOut(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppColors.danger,
                  ),
                  splashRadius: 22,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // ─── Pengaturan ───────────────────────────────────────
            const SectionHeader(label: 'PENGATURAN'),
            _ProfileNavRow(
              icon: Icons.tag_rounded,
              label: 'Kelola tag',
              onTap: () => context.push(Routes.tags),
            ),
            const ThinDivider(),
            _ProfileNavRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Privasi & data',
              onTap: () => context.push(Routes.privacy),
            ),
            const ThinDivider(),
            _ProfileNavRow(
              icon: Icons.info_outline,
              label: 'Tentang IngatanKu',
              onTap: () => context.push(Routes.about),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileNavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
