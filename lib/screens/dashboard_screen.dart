import 'package:flutter/material.dart';

import '../models/aturan_pesanan.dart';
import '../models/konversi.dart';
import '../models/pesanan.dart';
import '../models/profil_usaha.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/kepala_biru.dart';
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

  /// Tombol Profil Usaha di kepala halaman (ponsel). Jika null,
  /// disembunyikan.
  final VoidCallback? onProfil;

  const DashboardScreen({
    super.key,
    required this.semua,
    this.memuat = false,
    this.onLihatSemua,
    this.onPesananTap,
    this.onTambah,
    this.onKeluar,
    this.onProfil,
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

    final tepi = lebar ? AppTheme.spacing24 : AppTheme.marginTepi;

    final isi = <Widget>[
      _KepalaDashboard(
        sekarang: sekarang,
        rekap: rekap,
        tepi: tepi,
        onKeluar: lebar ? null : onKeluar,
        onProfil: lebar ? null : onProfil,
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(tepi, AppTheme.spacing16, tepi, 0),
        child: _KartuKiriman(
          sekarang: sekarang,
          pesanan: kirimHariIni,
          batas: _batasKirim,
          memuat: memuat,
          onPesananTap: onPesananTap,
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

/// Kepala Dashboard berwarna biru: logo dan nama usaha, sapaan dan
/// tanggal, tombol Profil Usaha dan Keluar, lalu ringkasan pembayaran
/// bulan berjalan (belum diterima dan jumlah pesanan per status).
class _KepalaDashboard extends StatelessWidget {
  final DateTime sekarang;
  final RekapBulanan rekap;
  final double tepi;
  final VoidCallback? onKeluar;
  final VoidCallback? onProfil;

  const _KepalaDashboard({
    required this.sekarang,
    required this.rekap,
    required this.tepi,
    this.onKeluar,
    this.onProfil,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProfilUsaha>(
      valueListenable: ProfilUsaha.aktif,
      builder: (context, profil, _) => KepalaBiru(
        tepi: tepi,
        depan: LogoUsaha(profil: profil.lengkap ? profil : null, ukuran: 42),
        judul: profil.lengkap ? profil.nama.trim() : ProfilUsaha.bawaan.nama,
        subjudul:
            '${Format.sapaan(sekarang)} · ${Format.tanggalPanjang(sekarang)}',
        aksi: [
          if (onProfil != null)
            KepalaBiru.tombol(
              key: const Key('tombol-profil-usaha'),
              tooltip: 'Profil usaha',
              ikon: Icons.storefront_outlined,
              onPressed: onProfil!,
            ),
          if (onKeluar != null)
            KepalaBiru.tombol(
              key: const Key('tombol-keluar'),
              tooltip: 'Keluar',
              ikon: Icons.logout,
              onPressed: onKeluar!,
            ),
        ],
        bawah: _RingkasanBulan(sekarang: sekarang, rekap: rekap),
      ),
    );
  }
}

/// Kotak transparan di kepala Dashboard: tagihan yang belum diterima
/// bulan ini dan jumlah pesanan Belum bayar, DP, dan Lunas.
class _RingkasanBulan extends StatelessWidget {
  final DateTime sekarang;
  final RekapBulanan rekap;

  const _RingkasanBulan({required this.sekarang, required this.rekap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Belum diterima · '
                  '${Format.bulanTahun(sekarang.year, sekarang.month)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: KepalaBiru.teksRedup,
                  ),
                ),
              ),
              Text(
                '${rekap.jumlahPesanan} pesanan',
                key: const Key('ringkasan-bulan-ini'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Format.rupiah(rekap.sisaTagihan),
              key: const Key('belum-diterima-bulan-ini'),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: AppTheme.angkaRata,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              for (final s in StatusPembayaran.values) ...[
                if (s != StatusPembayaran.values.first)
                  const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: _AngkaStatus(
                    key: Key('ringkasan-${s.name}'),
                    status: s,
                    jumlah: rekap.jumlahPerStatus[s] ?? 0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Jumlah pesanan satu status pembayaran di kepala Dashboard.
class _AngkaStatus extends StatelessWidget {
  final StatusPembayaran status;
  final int jumlah;

  const _AngkaStatus({super.key, required this.status, required this.jumlah});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            '$jumlah',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: AppTheme.angkaRata,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              status.label,
              maxLines: 1,
              style: const TextStyle(fontSize: 11, color: KepalaBiru.teksRedup),
            ),
          ),
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
              .where(
                (r) => Konversi.kunciTanggal(r.tanggalKirim) == kunciHariIni,
              )
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
