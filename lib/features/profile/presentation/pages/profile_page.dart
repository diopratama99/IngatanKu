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

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state is Authenticated
        ? (context.read<AuthBloc>().state as Authenticated).user
        : null;

    final initial = (user?.username ?? user?.email ?? '?')
        .substring(0, 1)
        .toUpperCase();

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
              ],
            ),
            const SizedBox(height: 40),

            // ─── Pengaturan ───────────────────────────────────────────
            const SectionHeader(label: 'PENGATURAN'),
            _ProfileNavRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Lencanaku',
              onTap: () => context.go(Routes.badges),
            ),
            const ThinDivider(),
            _ProfileNavRow(
              icon: Icons.tag_rounded,
              label: 'Kelola tag',
              onTap: () => context.push(Routes.tags),
            ),
            const ThinDivider(),
            _ProfileNavRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Privasi & data',
              onTap: () {},
            ),
            const ThinDivider(),
            _ProfileNavRow(
              icon: Icons.info_outline,
              label: 'Tentang IngatanKu',
              onTap: () {},
            ),
            const SizedBox(height: 48),

            // ─── Akun ─────────────────────────────────────────────────
            const SectionHeader(label: 'AKUN'),
            _ProfileNavRow(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              destructive: true,
              onTap: () =>
                  context.read<AuthBloc>().add(AuthSignOutRequested()),
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
  final bool destructive;
  const _ProfileNavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg =
        destructive ? AppColors.danger : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: destructive
                  ? AppColors.danger.withOpacity(0.7)
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
