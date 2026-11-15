import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../utils/theme.dart';

/// Badge status pembayaran: Belum bayar, DP, atau Lunas.
///
/// Bentuknya kapsul bergaris dengan latar muda sesuai style guide Figma.
/// Status selalu disertai teks, jadi tidak disampaikan hanya lewat warna.
class StatusBadge extends StatelessWidget {
  final StatusPembayaran status;

  const StatusBadge(this.status, {super.key});

  Color get _warna => switch (status) {
        StatusPembayaran.belumBayar => AppTheme.bayarBelum,
        StatusPembayaran.dp => AppTheme.bayarDP,
        StatusPembayaran.lunas => AppTheme.bayarLunas,
      };

  Color get _latar => switch (status) {
        StatusPembayaran.belumBayar => AppTheme.bayarBelumLatar,
        StatusPembayaran.dp => AppTheme.bayarDPLatar,
        StatusPembayaran.lunas => AppTheme.bayarLunasLatar,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _latar,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _warna),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: AppTheme.keterangan,
          fontWeight: FontWeight.w600,
          color: _warna,
        ),
      ),
    );
  }
}
