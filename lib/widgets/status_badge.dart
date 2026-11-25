import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../utils/theme.dart';

/// Warna untuk setiap status pembayaran, dipakai bersama oleh badge,
/// garis tepi kartu, kotak ringkasan, dan batang progres pembayaran.
class WarnaStatus {
  WarnaStatus._();

  static Color utama(StatusPembayaran s) => switch (s) {
    StatusPembayaran.belumBayar => AppTheme.bayarBelum,
    StatusPembayaran.dp => AppTheme.bayarDP,
    StatusPembayaran.lunas => AppTheme.bayarLunas,
  };

  static Color latar(StatusPembayaran s) => switch (s) {
    StatusPembayaran.belumBayar => AppTheme.bayarBelumLatar,
    StatusPembayaran.dp => AppTheme.bayarDPLatar,
    StatusPembayaran.lunas => AppTheme.bayarLunasLatar,
  };

  static IconData ikon(StatusPembayaran s) => switch (s) {
    StatusPembayaran.belumBayar => Icons.schedule_outlined,
    StatusPembayaran.dp => Icons.timelapse_outlined,
    StatusPembayaran.lunas => Icons.check_circle_outline,
  };
}

/// Badge status pembayaran: Belum bayar, DP, atau Lunas.
///
/// Status selalu disertai teks dan ikon, jadi tidak disampaikan hanya
/// lewat warna.
class StatusBadge extends StatelessWidget {
  final StatusPembayaran status;

  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final warna = WarnaStatus.utama(status);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, AppTheme.spacing8, 3),
      decoration: BoxDecoration(
        color: WarnaStatus.latar(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(WarnaStatus.ikon(status), size: 14, color: warna),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: AppTheme.keterangan,
              fontWeight: FontWeight.w600,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
