import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'status_badge.dart';

/// Kartu ringkasan satu pesanan pada Dashboard, Daftar Pesanan, dan Rekap.
///
/// Kartu putih: nama dan total di atas, ringkasan menu, lalu keterangan
/// (jenis pesanan atau sisa tagihan) dan tanggal nota di kiri bawah serta
/// badge status pembayaran di kanan bawah.
class PesananCard extends StatelessWidget {
  final Pesanan pesanan;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const PesananCard({
    super.key,
    required this.pesanan,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 5),
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
    final lunas = status == StatusPembayaran.lunas;
    final radius = BorderRadius.circular(AppTheme.sudutKartu);

    return Container(
      margin: margin,
      decoration: AppTheme.dekorasiKartu,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        p.namaPelanggan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 3),
                Text(
                  _ringkasMenu,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTheme.keterangan,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: lunas
                                  ? p.jenisPesanan.label
                                  : 'Sisa ${Format.rupiah(p.sisaTagihan)}',
                              style: lunas
                                  ? null
                                  : TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: WarnaStatus.utama(status),
                                    ),
                            ),
                            TextSpan(
                              text: ' · Nota ${Format.tanggal(p.tanggalNota)}',
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTersier,
                          fontFeatures: AppTheme.angkaRata,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    StatusBadge(status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
