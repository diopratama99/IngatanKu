import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/editorial.dart';

/// Static informational page summarising what data IngatanKu stores, where
/// it lives, and what rights the user has. Editorial in tone; intentionally
/// not a long legalese document. Surfaces the essentials with hairline
/// section dividers in line with the rest of the app.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('PRIVASI', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
          children: [
            Text('Privasi\n& data.', style: pageTitleStyle(size: 38)),
            const SizedBox(height: 14),
            Text(
              'Catatanmu adalah milikmu. Kami menyimpan seminimal mungkin '
              'dan tidak menjual datamu ke pihak ketiga.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 36),
            const SectionHeader(label: 'YANG KAMU BERIKAN'),
            const SizedBox(height: 12),
            const _BulletList([
              'Email untuk masuk dan mengirim email penting (verifikasi, lupa sandi).',
              'Username yang ditampilkan di dashboard.',
              'Catatan: tautan, judul, isi manual, dan tag. Semua milikmu, bisa diakses dan dihapus kapan saja.',
              'Embedding catatan, yaitu vektor numerik yang dipakai fitur "Asisten" untuk mencari catatan terkait.',
            ]),
            const SizedBox(height: 32),
            const SectionHeader(label: 'DI MANA DISIMPAN'),
            const SizedBox(height: 12),
            const _Paragraph(
              'Database Postgres + pgvector di Supabase (region Asia Tenggara). '
              'Semua koneksi melalui HTTPS. Setiap baris di-tag dengan ID '
              'pengguna dan dilindungi Row Level Security, jadi kamu hanya bisa '
              'membaca catatanmu sendiri.',
            ),
            const SizedBox(height: 32),
            const SectionHeader(label: 'YANG TIDAK KAMI LAKUKAN'),
            const SizedBox(height: 12),
            const _BulletList([
              'Tidak ada pelacakan iklan atau analitik pihak ketiga.',
              'Tidak ada penjualan data.',
              'Tidak ada pengiriman catatanmu ke layanan eksternal selain '
                  'untuk fitur AI yang kamu picu sendiri (mis. "Tanya asisten").',
            ]),
            const SizedBox(height: 32),
            const SectionHeader(label: 'HAK KAMU'),
            const SizedBox(height: 12),
            const _BulletList([
              'Edit atau hapus catatan kapan saja dari Brankas.',
              'Hapus akun dan semua catatan terkait. Tombolnya akan segera tersedia; sementara ini bisa diminta lewat kontak di bawah.',
              'Minta salinan datamu dengan menghubungi developer.',
            ]),
            const SizedBox(height: 32),
            const SectionHeader(label: 'KONTAK'),
            const SizedBox(height: 12),
            const _Paragraph(
              'Pertanyaan, permintaan ekspor, atau penghapusan data: hubungi '
              'TemanLabs lewat halaman Tentang IngatanKu.',
            ),
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
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textSecondary,
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
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
