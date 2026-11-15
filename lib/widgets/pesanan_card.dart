import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'status_badge.dart';

/// Kartu ringkasan satu pesanan pada Dashboard dan Daftar Pesanan.
///
/// - baris 1: nama pelanggan dan tanggal nota;
/// - baris 2: jenis pesanan, jumlah menu, dan total tagihan;
/// - baris 3: badge status pembayaran dan sisa tagihan bila belum lunas.
class PesananCard extends StatelessWidget {
  final Pesanan pesanan;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const PesananCard({
    super.key,
    required this.pesanan,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    final keterangan = [
      p.jenisPesanan.label,
      '${p.rincian.length} menu',
      Format.rupiah(p.totalTagihan),
    ].join(' · ');

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p.namaPelanggan,
                      style: const TextStyle(
                        fontSize: AppTheme.isi,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Nota ${Format.tanggal(p.tanggalNota)}',
                    style: const TextStyle(
                      fontSize: AppTheme.keterangan,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                keterangan,
                style: const TextStyle(
                  fontSize: AppTheme.keterangan,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                children: [
                  StatusBadge(p.statusPembayaran),
                  if (p.statusPembayaran != StatusPembayaran.lunas) ...[
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'Sisa ${Format.rupiah(p.sisaTagihan)}',
                      style: const TextStyle(
                        fontSize: AppTheme.keterangan,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
