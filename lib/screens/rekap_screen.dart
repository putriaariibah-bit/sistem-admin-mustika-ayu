import 'package:flutter/material.dart';

import '../models/aturan_pesanan.dart';
import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pesanan_card.dart';
import '../widgets/status_badge.dart';

/// Halaman Rekap Bulanan (proses 7.0, KF-10, Gambar 3.8(g)).
///
/// Pesanan dikelompokkan menurut tanggal nota. Pendapatan adalah jumlah
/// total menu; ongkos kirim tidak dihitung (aturan 3.2.4 nomor 4-6).
class RekapScreen extends StatefulWidget {
  final List<Pesanan> semua;
  final bool memuat;
  final void Function(Pesanan pesanan)? onPesananTap;

  const RekapScreen({
    super.key,
    required this.semua,
    this.memuat = false,
    this.onPesananTap,
  });

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen> {
  late int _tahun;
  late int _bulan;

  @override
  void initState() {
    super.initState();
    final sekarang = DateTime.now();
    _tahun = sekarang.year;
    _bulan = sekarang.month;
  }

  void _geser(int arah) {
    setState(() {
      final t = DateTime(_tahun, _bulan + arah);
      _tahun = t.year;
      _bulan = t.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lebar = AppTheme.layarLebar(context);
    final rekap = AturanPesanan.rekap(widget.semua, _tahun, _bulan);
    final pesananBulanIni = [
      for (final p in widget.semua)
        if (p.tanggalNota.year == _tahun && p.tanggalNota.month == _bulan) p,
    ];

    return Scaffold(
      backgroundColor: AppTheme.permukaan,
      appBar: lebar ? null : AppBar(title: const Text('Rekap Bulanan')),
      body: ListView(
        padding: EdgeInsets.all(lebar ? AppTheme.spacing24 : AppTheme.marginTepi),
        children: [
          if (lebar) ...[
            const Text(
              'Rekap Bulanan',
              style: TextStyle(
                fontSize: AppTheme.judul,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
          Row(
            children: [
              IconButton(
                key: const Key('bulan-sebelumnya'),
                tooltip: 'Bulan sebelumnya',
                onPressed: () => _geser(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  Format.bulanTahun(_tahun, _bulan),
                  key: const Key('bulan-rekap'),
                  textAlign: TextAlign.center,
                  style: AppTheme.gayaSeksi,
                ),
              ),
              IconButton(
                key: const Key('bulan-berikutnya'),
                tooltip: 'Bulan berikutnya',
                onPressed: () => _geser(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGelap,
              borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total pendapatan',
                  style: TextStyle(
                    fontSize: AppTheme.keterangan,
                    color: AppTheme.teksPanel,
                  ),
                ),
                Text(
                  Format.rupiah(rekap.totalPendapatan),
                  key: const Key('total-pendapatan'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFeatures: AppTheme.angkaRata,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '${rekap.jumlahPesanan} pesanan menurut tanggal nota. '
                  'Ongkos kirim tidak dihitung.',
                  style: const TextStyle(
                    fontSize: AppTheme.keterangan,
                    color: AppTheme.teksPanel,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Belum diterima',
                        style: TextStyle(
                          fontSize: AppTheme.isi,
                          color: AppTheme.teksPanel,
                        ),
                      ),
                    ),
                    Text(
                      Format.rupiah(rekap.sisaTagihan),
                      key: const Key('sisa-rekap'),
                      style: const TextStyle(
                        fontSize: AppTheme.isi,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFeatures: AppTheme.angkaRata,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              child: Column(
                children: [
                  for (final s in StatusPembayaran.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          StatusBadge(s),
                          const Spacer(),
                          Text(
                            '${rekap.jumlahPerStatus[s] ?? 0} pesanan',
                            key: Key('rekap-${s.name}'),
                            style: const TextStyle(
                              fontSize: AppTheme.isi,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontFeatures: AppTheme.angkaRata,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          const Text('Pesanan bulan ini', style: AppTheme.gayaSeksi),
          const SizedBox(height: AppTheme.spacing4),
          if (widget.memuat)
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacing24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (pesananBulanIni.isEmpty)
            const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Tidak ada pesanan',
              subtitle: 'Belum ada nota pada bulan ini.',
            )
          else
            for (final p in pesananBulanIni)
              PesananCard(
                pesanan: p,
                onTap: widget.onPesananTap == null
                    ? null
                    : () => widget.onPesananTap!(p),
              ),
        ],
      ),
    );
  }
}
