import 'package:flutter/material.dart';

import '../utils/theme.dart';
import 'kotak_ikon.dart';

/// Kartu berjudul untuk mengelompokkan isi Detail dan Form Pesanan,
/// misalnya Rincian Menu, Pembayaran, dan Riwayat Perubahan.
class KartuBagian extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Widget? aksi;
  final List<Widget> children;

  const KartuBagian({
    super.key,
    required this.judul,
    required this.ikon,
    this.aksi,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      decoration: AppTheme.dekorasiKartu,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          AppTheme.spacing12 + 2,
          AppTheme.spacing16,
          AppTheme.spacing16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                KotakIkon(
                  ikon: ikon,
                  warna: AppTheme.primary,
                  latar: AppTheme.primaryMuda,
                  ukuran: 30,
                ),
                const SizedBox(width: AppTheme.spacing12 - 2),
                Expanded(
                  child: Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                ?aksi,
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            ...children,
          ],
        ),
      ),
    );
  }
}
