import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Kepala halaman berwarna biru bergradasi dengan sudut bawah melengkung,
/// dipakai Dashboard, Daftar Pesanan, dan Rekap Bulanan.
///
/// Isinya: [depan] (mis. logo), [judul] dan [subjudul], tombol [aksi] di
/// kanan, lalu [bawah] (mis. kotak cari atau ringkasan) di bawah judul.
class KepalaBiru extends StatelessWidget {
  static const LinearGradient gradien = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppTheme.primary, Color(0xFF2D5486)],
  );

  /// Warna teks redup di atas latar biru.
  static const Color teksRedup = AppTheme.teksPanel;

  final String judul;
  final String? subjudul;
  final Widget? depan;
  final List<Widget> aksi;
  final Widget? bawah;

  /// Jarak tepi kiri dan kanan isi kepala.
  final double tepi;

  const KepalaBiru({
    super.key,
    required this.judul,
    this.subjudul,
    this.depan,
    this.aksi = const [],
    this.bawah,
    this.tepi = AppTheme.marginTepi,
  });

  /// Tombol ikon putih transparan untuk [aksi].
  static Widget tombol({
    required Key key,
    required String tooltip,
    required IconData ikon,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          key: key,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.sudutTombol + 2),
            ),
          ),
          icon: Icon(ikon, size: 19, color: Colors.white),
          onPressed: onPressed,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: gradien,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(tepi, 14, tepi, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (depan != null) ...[
                        depan!,
                        const SizedBox(width: AppTheme.spacing12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              judul,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (subjudul != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subjudul!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: teksRedup,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      for (final a in aksi) ...[
                        const SizedBox(width: AppTheme.spacing8),
                        a,
                      ],
                    ],
                  ),
                  if (bawah != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    bawah!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
