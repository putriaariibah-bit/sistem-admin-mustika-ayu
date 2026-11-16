import 'package:flutter/material.dart';

import '../models/aturan_pesanan.dart';
import '../models/konversi.dart';
import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pesanan_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/tombol_tambah_pesanan.dart';

/// Halaman awal setelah pemilik masuk (KF-11, Gambar 3.6(b)).
///
/// Dibuka dengan panel "Kirim hari ini" yang langsung menjawab apa saja
/// yang harus dimasak dan dikirim hari ini, lalu ringkasan pembayaran
/// bulan berjalan dan pesanan terbaru. Angka bulan berjalan dihitung
/// dengan aturan yang sama dengan rekap bulanan (tanggal nota).
class DashboardScreen extends StatelessWidget {
  static const int _batasPesananTerbaru = 3;
  static const int _batasKirim = 5;

  final List<Pesanan> semua;
  final bool memuat;
  final VoidCallback? onLihatSemua;
  final void Function(Pesanan pesanan)? onPesananTap;
  final VoidCallback? onTambah;

  /// Tombol Keluar di kepala halaman (ponsel). Jika null, disembunyikan.
  final VoidCallback? onKeluar;

  const DashboardScreen({
    super.key,
    required this.semua,
    this.memuat = false,
    this.onLihatSemua,
    this.onPesananTap,
    this.onTambah,
    this.onKeluar,
  });

  @override
  Widget build(BuildContext context) {
    final lebar = AppTheme.layarLebar(context);
    final sekarang = DateTime.now();
    final rekap = AturanPesanan.rekap(semua, sekarang.year, sekarang.month);
    final kirimHariIni = [
      for (final p in semua)
        if (p.dikirimPada(sekarang)) p,
    ];

    final isi = <Widget>[
      _PanelHariIni(
        sekarang: sekarang,
        pesanan: kirimHariIni,
        batas: _batasKirim,
        memuat: memuat,
        onKeluar: lebar ? null : onKeluar,
        onPesananTap: onPesananTap,
      ),
      Padding(
        padding: EdgeInsets.all(lebar ? AppTheme.spacing24 : AppTheme.marginTepi),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lebar) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TombolTambahPesanan.ringkas(
                  key: const Key('tambah-dashboard'),
                  onPressed: onTambah,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pembayaran ${Format.bulanTahun(sekarang.year, sekarang.month)}',
                    style: AppTheme.gayaSeksi,
                  ),
                ),
                Text(
                  '${rekap.jumlahPesanan} pesanan',
                  key: const Key('ringkasan-bulan-ini'),
                  style: const TextStyle(
                    fontSize: AppTheme.keterangan,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                for (final s in StatusPembayaran.values) ...[
                  if (s != StatusPembayaran.values.first)
                    const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: _KotakStatus(
                      key: Key('ringkasan-${s.name}'),
                      status: s,
                      jumlah: rekap.jumlahPerStatus[s] ?? 0,
                    ),
                  ),
                ],
              ],
            ),
            if (rekap.sisaTagihan > 0) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Belum diterima bulan ini: ${Format.rupiah(rekap.sisaTagihan)}',
                style: const TextStyle(
                  fontSize: AppTheme.keterangan,
                  color: AppTheme.textSecondary,
                  fontFeatures: AppTheme.angkaRata,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacing24),
            Row(
              children: [
                const Expanded(
                  child: Text('Pesanan terbaru', style: AppTheme.gayaSeksi),
                ),
                if (onLihatSemua != null && semua.isNotEmpty)
                  TextButton(
                    key: const Key('lihat-semua'),
                    onPressed: onLihatSemua,
                    child: const Text('Lihat semua'),
                  ),
              ],
            ),
            if (!memuat && semua.isEmpty)
              const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Belum ada pesanan',
                subtitle: 'Catat pesanan pertama dari WhatsApp pelanggan.',
              )
            else
              for (final p in semua.take(_batasPesananTerbaru))
                PesananCard(
                  pesanan: p,
                  onTap: onPesananTap == null ? null : () => onPesananTap!(p),
                ),
          ],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.permukaan,
      body: ListView(padding: EdgeInsets.zero, children: isi),
      bottomNavigationBar: lebar
          ? null
          : TombolTambahPesanan.bawah(
              key: const Key('tambah-dashboard'),
              onPressed: onTambah,
            ),
    );
  }
}

/// Panel biru di bagian atas Dashboard: siapa saja yang dikirimi hari ini
/// dan menu apa saja yang harus disiapkan.
class _PanelHariIni extends StatelessWidget {
  final DateTime sekarang;
  final List<Pesanan> pesanan;
  final int batas;
  final bool memuat;
  final VoidCallback? onKeluar;
  final void Function(Pesanan pesanan)? onPesananTap;

  const _PanelHariIni({
    required this.sekarang,
    required this.pesanan,
    required this.batas,
    required this.memuat,
    this.onKeluar,
    this.onPesananTap,
  });

  @override
  Widget build(BuildContext context) {
    final kunciHariIni = Konversi.kunciTanggal(sekarang);
    final porsiHariIni = pesanan.fold<int>(0, (jumlah, p) {
      return jumlah +
          p.rincian
              .where((r) => Konversi.kunciTanggal(r.tanggalKirim) == kunciHariIni)
              .fold<int>(0, (j, r) => j + r.jumlahPorsi);
    });

    return Container(
      color: AppTheme.primaryGelap,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.marginTepi,
            AppTheme.spacing12,
            AppTheme.spacing8,
            AppTheme.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${Format.sapaan(sekarang)} · ${Format.tanggalPanjang(sekarang)}',
                      style: const TextStyle(
                        fontSize: AppTheme.keterangan,
                        color: AppTheme.teksPanel,
                      ),
                    ),
                  ),
                  if (onKeluar != null)
                    IconButton(
                      key: const Key('tombol-keluar'),
                      tooltip: 'Keluar',
                      icon: const Icon(Icons.logout, color: AppTheme.teksPanel),
                      onPressed: onKeluar,
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
              const Text(
                'Mustika Ayu Catering',
                style: TextStyle(
                  fontSize: AppTheme.subjudul,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    memuat ? '–' : '${pesanan.length}',
                    key: const Key('ringkasan-dikirim-hari-ini'),
                    style: const TextStyle(
                      fontSize: 48,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFeatures: AppTheme.angkaRata,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        pesanan.isEmpty
                            ? 'Tidak ada kiriman hari ini'
                            : 'Pesanan dikirim hari ini\n$porsiHariIni porsi disiapkan',
                        style: const TextStyle(
                          fontSize: AppTheme.isi,
                          color: AppTheme.teksPanel,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (pesanan.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing16),
                for (final p in pesanan.take(batas))
                  _BarisKiriman(
                    pesanan: p,
                    kunciHariIni: kunciHariIni,
                    onTap: onPesananTap == null ? null : () => onPesananTap!(p),
                  ),
                if (pesanan.length > batas)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacing8),
                    child: Text(
                      '+${pesanan.length - batas} pesanan lain di Daftar Pesanan',
                      style: const TextStyle(
                        fontSize: AppTheme.keterangan,
                        color: AppTheme.teksPanel,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BarisKiriman extends StatelessWidget {
  final Pesanan pesanan;
  final String kunciHariIni;
  final VoidCallback? onTap;

  const _BarisKiriman({
    required this.pesanan,
    required this.kunciHariIni,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final menu = [
      for (final r in pesanan.rincian)
        if (Konversi.kunciTanggal(r.tanggalKirim) == kunciHariIni)
          '${r.namaMenu} ${r.jumlahPorsi}',
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacing8, bottom: 6),
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: 10,
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 18, color: AppTheme.teksPanel),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pesanan.namaPelanggan,
                        style: const TextStyle(
                          fontSize: AppTheme.isi,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        menu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppTheme.keterangan,
                          color: AppTheme.teksPanel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.teksPanel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kotak jumlah pesanan satu status pembayaran pada bulan berjalan.
class _KotakStatus extends StatelessWidget {
  final StatusPembayaran status;
  final int jumlah;

  const _KotakStatus({super.key, required this.status, required this.jumlah});

  @override
  Widget build(BuildContext context) {
    final warna = WarnaStatus.utama(status);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
      child: ColoredBox(
        color: AppTheme.latar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 3, color: warna),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(WarnaStatus.ikon(status), size: 18, color: warna),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    '$jumlah',
                    style: const TextStyle(
                      fontSize: AppTheme.judul,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontFeatures: AppTheme.angkaRata,
                    ),
                  ),
                  Text(
                    status.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTheme.keterangan,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
