import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import 'status_badge.dart';

/// Kotak ikon berwarna pastel di sudut kartu, mis. pada kartu ringkasan
/// Dashboard dan Rekap.
class KotakIkon extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final Color latar;
  final double ukuran;

  const KotakIkon({
    super.key,
    required this.ikon,
    required this.warna,
    required this.latar,
    this.ukuran = 36,
  });

  /// Kotak ikon dengan warna status pembayaran (Belum bayar, DP, Lunas).
  KotakIkon.status(StatusPembayaran status, {Key? key, double ukuran = 36})
    : this(
        key: key,
        ikon: WarnaStatus.ikon(status),
        warna: WarnaStatus.utama(status),
        latar: WarnaStatus.latar(status),
        ukuran: ukuran,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(ukuran * 0.28),
      ),
      child: Icon(ikon, size: ukuran * 0.52, color: warna),
    );
  }
}
