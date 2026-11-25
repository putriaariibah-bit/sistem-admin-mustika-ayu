import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/kartu_pesanan_daftar.dart';
import '../widgets/kepala_biru.dart';
import '../widgets/tombol_tambah_pesanan.dart';
import 'detail_pesanan_screen.dart';
import 'nota_screen.dart';

/// Saringan pada Daftar Pesanan (KF-09).
enum Saringan {
  semua('Semua'),
  dikirimHariIni('Dikirim hari ini'),
  belumBayar('Belum bayar'),
  dp('DP'),
  lunas('Lunas');

  const Saringan(this.label);
  final String label;

  bool cocok(Pesanan p, DateTime hariIni) => switch (this) {
    Saringan.semua => true,
    Saringan.dikirimHariIni => p.dikirimPada(hariIni),
    Saringan.belumBayar => p.statusPembayaran == StatusPembayaran.belumBayar,
    Saringan.dp => p.statusPembayaran == StatusPembayaran.dp,
    Saringan.lunas => p.statusPembayaran == StatusPembayaran.lunas,
  };
}

/// Halaman Daftar Pesanan (Gambar 3.6(c)).
///
/// Pemilik dapat mencari nama pelanggan atau menu, lalu menyaring
/// pesanan yang dikirim hari ini atau menurut status pembayaran.
class DaftarPesananScreen extends StatefulWidget {
  final List<Pesanan> semua;
  final bool memuat;
  final void Function(Pesanan pesanan)? onPesananTap;
  final VoidCallback? onTambah;

  const DaftarPesananScreen({
    super.key,
    required this.semua,
    this.memuat = false,
    this.onPesananTap,
    this.onTambah,
  });

  @override
  State<DaftarPesananScreen> createState() => _DaftarPesananScreenState();
}

class _DaftarPesananScreenState extends State<DaftarPesananScreen> {
  final _cariController = TextEditingController();
  Saringan _saringan = Saringan.semua;

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  /// BB-21: cocok bila nama pelanggan atau salah satu menu memuat kata cari.
  bool _cocokCari(Pesanan p, String kata) {
    if (kata.isEmpty) return true;
    if (p.namaPelanggan.toLowerCase().contains(kata)) return true;
    return p.rincian.any((r) => r.namaMenu.toLowerCase().contains(kata));
  }

  void _bukaNota(Pesanan p) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => NotaScreen(pesanan: p)),
  );

  @override
  Widget build(BuildContext context) {
    final lebar = AppTheme.layarLebar(context);
    final tepi = lebar ? AppTheme.spacing24 : AppTheme.marginTepi;
    final kata = _cariController.text.trim().toLowerCase();
    final hariIni = DateTime.now();
    final hasil = [
      for (final p in widget.semua)
        if (_cocokCari(p, kata) && _saringan.cocok(p, hariIni)) p,
    ];

    final kolomCari = TextField(
      key: const Key('cari-pesanan'),
      controller: _cariController,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari nama pelanggan atau menu',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        suffixIcon: _cariController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(_cariController.clear),
              ),
      ),
    );

    final pilihanSaringan = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final s in Saringan.values) ...[
            if (s != Saringan.values.first)
              const SizedBox(width: AppTheme.spacing8),
            _PilSaringan(
              key: Key('saringan-${s.name}'),
              label: s.label,
              aktif: _saringan == s,
              onTap: () => setState(() => _saringan = s),
            ),
          ],
        ],
      ),
    );

    Widget isi;
    if (widget.memuat) {
      isi = const Padding(
        padding: EdgeInsets.all(AppTheme.spacing24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (widget.semua.isEmpty) {
      isi = const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada pesanan',
        subtitle: 'Catat pesanan pertama dari WhatsApp pelanggan.',
      );
    } else if (hasil.isEmpty) {
      isi = const EmptyState(
        icon: Icons.search_off,
        title: 'Pesanan tidak ditemukan',
        subtitle: 'Coba kata pencarian atau saringan lain.',
      );
    } else {
      isi = Column(
        children: [
          for (final p in hasil)
            KartuPesananDaftar(
              pesanan: p,
              onDetail: widget.onPesananTap == null
                  ? null
                  : () => widget.onPesananTap!(p),
              onNota: () => _bukaNota(p),
              onCatatBayar: () =>
                  DetailPesananScreen.catatPembayaran(context, p),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.permukaan,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          KepalaBiru(
            tepi: tepi,
            judul: 'Daftar Pesanan',
            subjudul: 'Semua nota yang sudah dicatat',
            bawah: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                kolomCari,
                const SizedBox(height: AppTheme.spacing12),
                pilihanSaringan,
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(tepi, AppTheme.spacing16, tepi, tepi),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (lebar) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TombolTambahPesanan.ringkas(
                      key: const Key('tambah-daftar'),
                      onPressed: widget.onTambah,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                ],
                isi,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: lebar
          ? null
          : TombolTambahPesanan.bawah(
              key: const Key('tambah-daftar'),
              onPressed: widget.onTambah,
            ),
    );
  }
}

/// Tombol saringan berbentuk pil di kepala biru.
class _PilSaringan extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _PilSaringan({
    super.key,
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: aktif,
      button: true,
      child: Material(
        color: aktif ? Colors.white : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: aktif ? AppTheme.primary : AppTheme.primaryMuda,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
