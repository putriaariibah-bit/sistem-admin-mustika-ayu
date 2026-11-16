import 'package:flutter/material.dart';

import '../models/aturan_pesanan.dart';
import '../models/konversi.dart';
import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/kotak_ikon.dart';
import '../widgets/logo_usaha.dart';
import '../widgets/pesanan_card.dart';
import '../widgets/tombol_tambah_pesanan.dart';

/// Halaman awal setelah pemilik masuk (KF-11, Gambar 3.6(b)).
///
/// Dibuka dengan kepala berlogo dan kartu "Kiriman hari ini" yang menjawab apa saja
/// yang harus dimasak dan dikirim hari ini, lalu ringkasan pembayaran
/// bulan berjalan dan pesanan terbaru. Angka bulan berjalan dihitung
/// dengan aturan yang sama dengan rekap bulanan (tanggal nota).
class DashboardScreen extends StatelessWidget {
  static const TextStyle _gayaSeksi = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );
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
      Padding(
        padding: EdgeInsets.fromLTRB(
          lebar ? AppTheme.spacing24 : AppTheme.marginTepi,
          lebar ? AppTheme.spacing24 : AppTheme.spacing12,
          lebar ? AppTheme.spacing24 : AppTheme.marginTepi,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KepalaDashboard(
              sekarang: sekarang,
              onKeluar: lebar ? null : onKeluar,
            ),
            const SizedBox(height: AppTheme.spacing16),
            _KartuKiriman(
              sekarang: sekarang,
              pesanan: kirimHariIni,
              batas: _batasKirim,
              memuat: memuat,
              onPesananTap: onPesananTap,
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          lebar ? AppTheme.spacing24 : AppTheme.marginTepi,
          AppTheme.spacing24,
          lebar ? AppTheme.spacing24 : AppTheme.marginTepi,
          lebar ? AppTheme.spacing24 : AppTheme.marginTepi,
        ),
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
                    style: _gayaSeksi,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.garisKartu),
                  ),
                  child: Text(
                    '${rekap.jumlahPesanan} pesanan',
                    key: const Key('ringkasan-bulan-ini'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12 - 2),
            Row(
              children: [
                for (final s in StatusPembayaran.values) ...[
                  if (s != StatusPembayaran.values.first)
                    const SizedBox(width: AppTheme.spacing12 - 2),
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
            const SizedBox(height: AppTheme.spacing24 - 4),
            Row(
              children: [
                const Expanded(
                  child: Text('Pesanan terbaru', style: _gayaSeksi),
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

/// Kepala Dashboard: logo, sapaan dan tanggal, nama usaha, tombol Keluar.
class _KepalaDashboard extends StatelessWidget {
  final DateTime sekarang;
  final VoidCallback? onKeluar;

  const _KepalaDashboard({required this.sekarang, this.onKeluar});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          const LogoUsaha(),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Format.sapaan(sekarang)} · ${Format.tanggalPanjang(sekarang)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Mustika Ayu Catering',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (onKeluar != null) ...[
            const SizedBox(width: AppTheme.spacing8),
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton.outlined(
                key: const Key('tombol-keluar'),
                tooltip: 'Keluar',
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.garisKartu),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.sudutTombol),
                  ),
                ),
                icon: const Icon(
                  Icons.logout,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onKeluar,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartu putih "Kiriman hari ini": jumlah pesanan yang dikirim hari ini
/// dan menu yang harus disiapkan.
class _KartuKiriman extends StatelessWidget {
  final DateTime sekarang;
  final List<Pesanan> pesanan;
  final int batas;
  final bool memuat;
  final void Function(Pesanan pesanan)? onPesananTap;

  const _KartuKiriman({
    required this.sekarang,
    required this.pesanan,
    required this.batas,
    required this.memuat,
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
      key: const Key('kartu-kiriman-hari-ini'),
      decoration: AppTheme.dekorasiKartu,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const KotakIkon(
                ikon: Icons.local_shipping_outlined,
                warna: AppTheme.primary,
                latar: AppTheme.primaryMuda,
                ukuran: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kiriman hari ini',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          memuat ? '–' : '${pesanan.length}',
                          key: const Key('ringkasan-dikirim-hari-ini'),
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontFeatures: AppTheme.angkaRata,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: Text(
                            pesanan.isEmpty
                                ? 'Tidak ada kiriman hari ini'
                                : '$porsiHariIni porsi disiapkan',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pesanan.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              child: Divider(color: AppTheme.garisKartu),
            ),
            for (final p in pesanan.take(batas))
              _BarisKiriman(
                pesanan: p,
                kunciHariIni: kunciHariIni,
                onTap: onPesananTap == null ? null : () => onPesananTap!(p),
              ),
            if (pesanan.length > batas)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacing4),
                child: Text(
                  '+${pesanan.length - batas} pesanan lain di Daftar Pesanan',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ],
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

    // Material transparan agar efek ketuk tampil di atas kartu putih.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.sudutTombol),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pesanan.namaPelanggan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      menu,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textTersier),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu jumlah pesanan satu status pembayaran pada bulan berjalan.
class _KotakStatus extends StatelessWidget {
  final StatusPembayaran status;
  final int jumlah;

  const _KotakStatus({super.key, required this.status, required this.jumlah});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.dekorasiKartu,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KotakIkon.status(status),
          const SizedBox(height: 10),
          Text(
            '$jumlah',
            style: const TextStyle(
              fontSize: 22,
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
              fontSize: 12.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
