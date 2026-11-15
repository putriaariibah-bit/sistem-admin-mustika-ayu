import 'package:flutter/material.dart';

import '../models/aturan_pesanan.dart';
import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pesanan_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/tombol_tambah_pesanan.dart';

/// Halaman awal setelah pemilik masuk (KF-11, Gambar 3.6(b)).
///
/// Memuat jumlah pesanan yang dikirim hari ini, jumlah pesanan bulan
/// berjalan, jumlah pesanan per status pembayaran pada bulan berjalan,
/// dan pesanan terbaru. Angka bulan berjalan dihitung dengan aturan yang
/// sama dengan rekap bulanan (berdasarkan tanggal nota).
class DashboardScreen extends StatelessWidget {
  static const int _batasPesananTerbaru = 3;

  /// Seluruh pesanan dari Firestore.
  final List<Pesanan> semua;

  /// True selama data pertama belum diterima.
  final bool memuat;

  final VoidCallback? onLihatSemua;
  final void Function(Pesanan pesanan)? onPesananTap;
  final VoidCallback? onTambah;

  /// Tombol Keluar di app bar (ponsel). Jika null, tombol disembunyikan.
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
    final hariIni = DateTime.now();
    final rekap = AturanPesanan.rekap(semua, hariIni.year, hariIni.month);
    final dikirimHariIni = AturanPesanan.jumlahDikirim(semua, hariIni);
    final terbaru = semua.take(_batasPesananTerbaru).toList();

    Widget kotak(String judul, int nilai, Key key) =>
        Expanded(child: SummaryCard(key: key, title: judul, value: nilai));

    final isi = <Widget>[
      if (lebar)
        Row(
          children: [
            const Expanded(
              child: Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: AppTheme.judul,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            TombolTambahPesanan.ringkas(
              key: const Key('tambah-dashboard'),
              onPressed: onTambah,
            ),
          ],
        ),
      Text(
        Format.tanggalPanjang(hariIni),
        style: const TextStyle(
          fontSize: AppTheme.isi,
          color: AppTheme.textSecondary,
        ),
      ),
      const SizedBox(height: AppTheme.spacing16),
      if (memuat)
        const Padding(
          padding: EdgeInsets.all(AppTheme.spacing24),
          child: Center(child: CircularProgressIndicator()),
        )
      else ...[
        Row(
          children: [
            kotak('Dikirim hari ini', dikirimHariIni,
                const Key('ringkasan-dikirim-hari-ini')),
            const SizedBox(width: AppTheme.spacing12),
            kotak('Pesanan bulan ini', rekap.jumlahPesanan,
                const Key('ringkasan-bulan-ini')),
          ],
        ),
        const SizedBox(height: AppTheme.spacing24),
        const Text('Status Pembayaran Bulan Ini', style: AppTheme.gayaSeksi),
        const SizedBox(height: AppTheme.spacing8),
        Row(
          children: [
            for (final status in StatusPembayaran.values) ...[
              if (status != StatusPembayaran.values.first)
                const SizedBox(width: AppTheme.spacing12),
              kotak(status.label, rekap.jumlahPerStatus[status] ?? 0,
                  Key('ringkasan-${status.name}')),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.spacing24),
        Row(
          children: [
            const Expanded(
              child: Text('Pesanan Terbaru', style: AppTheme.gayaSeksi),
            ),
            if (onLihatSemua != null && semua.isNotEmpty)
              TextButton(
                key: const Key('lihat-semua'),
                onPressed: onLihatSemua,
                child: const Text('Lihat semua'),
              ),
          ],
        ),
        if (semua.isEmpty)
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Belum ada pesanan',
            subtitle: 'Catat pesanan pertama dari WhatsApp pelanggan.',
          )
        else
          for (final pesanan in terbaru)
            PesananCard(
              pesanan: pesanan,
              onTap: onPesananTap == null ? null : () => onPesananTap!(pesanan),
            ),
      ],
    ];

    return Scaffold(
      appBar: lebar
          ? null
          : AppBar(
              title: const Text('Dashboard'),
              actions: [
                if (onKeluar != null)
                  IconButton(
                    key: const Key('tombol-keluar'),
                    tooltip: 'Keluar',
                    icon: const Icon(Icons.logout),
                    onPressed: onKeluar,
                  ),
              ],
            ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(
            lebar ? AppTheme.spacing24 : AppTheme.marginTepi,
          ),
          children: isi,
        ),
      ),
      bottomNavigationBar: lebar
          ? null
          : TombolTambahPesanan.bawah(
              key: const Key('tambah-dashboard'),
              onPressed: onTambah,
            ),
    );
  }
}
