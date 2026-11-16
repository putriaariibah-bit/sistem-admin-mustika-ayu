import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'status_badge.dart';

/// Kartu ringkasan satu pesanan pada Dashboard, Daftar Pesanan, dan Rekap.
///
/// Garis tepi kiri berwarna status pembayaran, sehingga pesanan yang
/// belum dibayar mudah terlihat saat daftar digulir.
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

  String get _ringkasMenu {
    final nama = pesanan.rincian.map((r) => r.namaMenu).toSet().toList();
    if (nama.length <= 2) return nama.join(', ');
    return '${nama.take(2).join(', ')}, +${nama.length - 2} menu';
  }

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    final status = p.statusPembayaran;
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: WarnaStatus.utama(status)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacing12,
                    AppTheme.spacing12,
                    AppTheme.spacing16,
                    AppTheme.spacing12,
                  ),
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
                            Format.rupiah(p.totalTagihan),
                            style: const TextStyle(
                              fontSize: AppTheme.isi,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFeatures: AppTheme.angkaRata,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _ringkasMenu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppTheme.keterangan,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Row(
                        children: [
                          StatusBadge(status),
                          const SizedBox(width: AppTheme.spacing8),
                          Expanded(
                            child: Text(
                              status == StatusPembayaran.lunas
                                  ? p.jenisPesanan.label
                                  : 'Sisa ${Format.rupiah(p.sisaTagihan)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppTheme.keterangan,
                                fontWeight: status == StatusPembayaran.lunas
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                                color: status == StatusPembayaran.lunas
                                    ? AppTheme.textSecondary
                                    : WarnaStatus.utama(status),
                                fontFeatures: AppTheme.angkaRata,
                              ),
                            ),
                          ),
                          Text(
                            'Nota ${Format.tanggal(p.tanggalNota)}',
                            style: const TextStyle(
                              fontSize: AppTheme.keterangan,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
