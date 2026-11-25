import 'package:flutter/material.dart';

import '../models/aturan_pesanan.dart';
import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/kepala_biru.dart';
import '../widgets/kotak_ikon.dart';
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
  static const TextStyle _gayaSeksi = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

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

  Widget _tombolBulan(Key key, String tooltip, IconData ikon, int arah) =>
      SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          key: key,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(ikon, color: Colors.white, size: 20),
          onPressed: () => _geser(arah),
        ),
      );

  /// Kotak berwarna lembut berisi jumlah pesanan (Gambar 3.8(g)).
  Widget _kotakJumlah({
    required Widget ikon,
    required String label,
    required String nilai,
    required Color warna,
    required Color latar,
    required Color garis,
    Key? kunci,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: latar,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: garis),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ikon,
        const SizedBox(height: 10),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: warna,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            nilai,
            key: kunci,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: warna,
              fontFeatures: AppTheme.angkaRata,
            ),
          ),
        ),
      ],
    ),
  );

  static Color _lembut(Color warna) =>
      Color.alphaBlend(warna.withValues(alpha: 0.05), Colors.white);

  @override
  Widget build(BuildContext context) {
    final lebar = AppTheme.layarLebar(context);
    final tepi = lebar ? AppTheme.spacing24 : AppTheme.marginTepi;
    final rekap = AturanPesanan.rekap(widget.semua, _tahun, _bulan);
    final pesananBulanIni = [
      for (final p in widget.semua)
        if (p.tanggalNota.year == _tahun && p.tanggalNota.month == _bulan) p,
    ];

    final kotak = <Widget>[
      _kotakJumlah(
        ikon: const KotakIkon(
          ikon: Icons.receipt_long_outlined,
          warna: AppTheme.primary,
          latar: Colors.white,
          ukuran: 30,
        ),
        label: 'Jumlah pesanan',
        nilai: '${rekap.jumlahPesanan} pesanan',
        warna: AppTheme.primary,
        latar: const Color(0xFFEEF3FA),
        garis: const Color(0xFFD3DEEE),
        kunci: const Key('rekap-jumlah'),
      ),
      for (final s in StatusPembayaran.values)
        _kotakJumlah(
          ikon: KotakIkon.status(s, ukuran: 30),
          label: s.label,
          nilai: '${rekap.jumlahPerStatus[s] ?? 0} pesanan',
          warna: WarnaStatus.utama(s),
          latar: _lembut(WarnaStatus.utama(s)),
          garis: WarnaStatus.latar(s),
          kunci: Key('rekap-${s.name}'),
        ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.permukaan,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          KepalaBiru(
            tepi: tepi,
            judul: 'Rekap Bulanan',
            subjudul: 'Pendapatan menurut tanggal nota',
            bawah: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _tombolBulan(
                    const Key('bulan-sebelumnya'),
                    'Bulan sebelumnya',
                    Icons.chevron_left,
                    -1,
                  ),
                  Expanded(
                    child: Text(
                      Format.bulanTahun(_tahun, _bulan),
                      key: const Key('bulan-rekap'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _tombolBulan(
                    const Key('bulan-berikutnya'),
                    'Bulan berikutnya',
                    Icons.chevron_right,
                    1,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(tepi, AppTheme.spacing16, tepi, tepi),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: AppTheme.dekorasiKartu,
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          KotakIkon(
                            ikon: Icons.trending_up,
                            warna: AppTheme.bayarLunas,
                            latar: AppTheme.bayarLunasLatar,
                          ),
                          SizedBox(width: AppTheme.spacing12),
                          Text(
                            'Total pendapatan',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing12 - 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Format.rupiah(rekap.totalPendapatan),
                          key: const Key('total-pendapatan'),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.bayarLunas,
                            fontFeatures: AppTheme.angkaRata,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'Dari ${rekap.jumlahPesanan} pesanan menurut tanggal '
                        'nota. Ongkos kirim tidak dihitung.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacing12,
                        ),
                        child: Divider(color: AppTheme.garisKartu),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Sisa tagihan yang belum diterima',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            Format.rupiah(rekap.sisaTagihan),
                            key: const Key('sisa-rekap'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: rekap.sisaTagihan > 0
                                  ? AppTheme.bayarBelum
                                  : AppTheme.textPrimary,
                              fontFeatures: AppTheme.angkaRata,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24 - 4),
                const Text('Pesanan menurut status', style: _gayaSeksi),
                const SizedBox(height: AppTheme.spacing12 - 2),
                Row(
                  children: [
                    Expanded(child: kotak[0]),
                    const SizedBox(width: 10),
                    Expanded(child: kotak[1]),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: kotak[2]),
                    const SizedBox(width: 10),
                    Expanded(child: kotak[3]),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing24 - 4),
                const Text('Pesanan bulan ini', style: _gayaSeksi),
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
          ),
        ],
      ),
    );
  }
}
