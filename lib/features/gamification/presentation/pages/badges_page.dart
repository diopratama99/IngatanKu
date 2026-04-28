import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../bloc/badges_cubit.dart';
import '../widgets/badge_card.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});
  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  @override
  void initState() {
    super.initState();
    context.read<BadgesCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('LENCANA', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: BlocBuilder<BadgesCubit, BadgesState>(
          builder: (_, state) {
            if (state is BadgesLoading || state is BadgesInitial) {
              return GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(24),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
                children: List.generate(
                    4, (_) => const ShimmerBox(height: 200, radius: 8)),
              );
            }
            if (state is BadgesError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.message,
                      style: context.textStyles.bodyMedium),
                ),
              );
            }
            if (state is BadgesLoaded) {
              final unlocked =
                  state.badges.where((b) => b.unlocked).length;
              final total = state.badges.length;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pencapaianmu.',
                              style: pageTitleStyle(size: 32)),
                          const SizedBox(height: 32),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$unlocked',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -2,
                                  height: 0.95,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '/ $total',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            unlocked == 0
                                ? 'Belum ada lencana yang terbuka. Mulai catat tech-mu untuk membuka yang pertama.'
                                : 'Lencana terbuka. Terus konsisten untuk membuka sisanya.',
                            style: context.textStyles.bodyMedium,
                          ),
                          const SizedBox(height: 28),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : unlocked / total,
                              backgroundColor:
                                  AppColors.bgTertiary.withOpacity(0.4),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                              minHeight: 3,
                            ),
                          ),
                          const SizedBox(height: 36),
                          const SectionHeader(label: 'KOLEKSI'),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => BadgeCard(badge: state.badges[i]),
                        childCount: state.badges.length,
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
