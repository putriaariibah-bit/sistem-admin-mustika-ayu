import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pesanan_card.dart';
import '../widgets/tombol_tambah_pesanan.dart';

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
        Saringan.belumBayar =>
          p.statusPembayaran == StatusPembayaran.belumBayar,
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

  @override
  Widget build(BuildContext context) {
    final lebar = AppTheme.layarLebar(context);
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
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _cariController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(_cariController.clear),
              ),
      ),
    );

    final pilihanSaringan = Wrap(
      spacing: AppTheme.spacing8,
      runSpacing: AppTheme.spacing8,
      children: [
        for (final s in Saringan.values)
          ChoiceChip(
            key: Key('saringan-${s.name}'),
            label: Text(s.label),
            selected: _saringan == s,
            onSelected: (_) => setState(() => _saringan = s),
          ),
      ],
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
            PesananCard(
              pesanan: p,
              onTap: widget.onPesananTap == null
                  ? null
                  : () => widget.onPesananTap!(p),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: lebar ? null : AppBar(title: const Text('Daftar Pesanan')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(
            lebar ? AppTheme.spacing24 : AppTheme.marginTepi,
          ),
          children: [
            if (lebar) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daftar Pesanan',
                      style: TextStyle(
                        fontSize: AppTheme.judul,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  TombolTambahPesanan.ringkas(
                    key: const Key('tambah-daftar'),
                    onPressed: widget.onTambah,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
            kolomCari,
            const SizedBox(height: AppTheme.spacing12),
            pilihanSaringan,
            const SizedBox(height: AppTheme.spacing12),
            isi,
          ],
        ),
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
