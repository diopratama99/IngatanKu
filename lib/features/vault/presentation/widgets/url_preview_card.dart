import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../data/models/url_metadata.dart';

class UrlPreviewCard extends StatelessWidget {
  final UrlMetadata? meta;
  final bool loading;

  const UrlPreviewCard({super.key, this.meta, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (!loading && meta == null) return const SizedBox.shrink();
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceStroke),
        ),
        child: loading ? _buildLoading() : _buildLoaded(context, meta!),
      ),
    );
  }

  Widget _buildLoading() => const Row(
        children: [
          ShimmerBox(width: 72, height: 72, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, radius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 12, radius: 4),
              ],
            ),
          ),
        ],
      );

  Widget _buildLoaded(BuildContext context, UrlMetadata m) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 72,
            height: 72,
            child: m.image != null
                ? CachedNetworkImage(
                    imageUrl: m.image!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.bgTertiary),
                    errorWidget: (_, __, ___) => _fallbackIcon(m.sourceType),
                  )
                : _fallbackIcon(m.sourceType),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.siteName != null)
                Text(m.siteName!.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                    )),
              const SizedBox(height: 4),
              Text(
                m.title ?? m.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.titleMedium,
              ),
              if (m.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  m.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackIcon(String type) {
    final icon = switch (type) {
      'youtube' => Icons.play_circle_outline,
      'tiktok' => Icons.music_note_outlined,
      'instagram' => Icons.camera_alt_outlined,
      'x' => Icons.alternate_email,
      _ => Icons.link_rounded,
    };
    return Container(
      color: AppColors.bgTertiary,
      child: Icon(icon, color: AppColors.textSecondary, size: 28),
    );
  }
}
