import 'package:flutter/material.dart';

import '../utils/theme.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(ikon, size: 20, color: AppTheme.primary),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(child: Text(judul, style: AppTheme.gayaSeksi)),
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
