import 'package:flutter/material.dart';

import '../models/nota.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'status_badge.dart';

/// Tampilan nota (Gambar 3.8(f)), dibuat mirip nota kertas pemilik:
/// kepala usaha, tanggal dan nama, tabel Banyak, Nama, Harga, Jumlah,
/// lalu baris "Jumlah Rp.". Baris alamat tidak dipakai. Tambahannya
/// adalah baris ongkos kirim, sudah dibayar, sisa, dan status pembayaran.
///
/// Widget ini juga yang diubah menjadi berkas gambar saat nota disimpan
/// atau dibagikan, sehingga isi berkas sama dengan yang tampil di layar.
class NotaKertas extends StatelessWidget {
  final Nota nota;

  const NotaKertas({super.key, required this.nota});

  static const _teks = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 12.5,
    color: AppTheme.textPrimary,
    height: 1.3,
  );
  static final _tebal = _teks.copyWith(fontWeight: FontWeight.w700);
  static final _angka = _teks.copyWith(fontFeatures: AppTheme.angkaRata);
  static const _garis = BorderSide(color: AppTheme.textSecondary, width: 0.8);

  Widget _sel(String isi, TextStyle gaya, {TextAlign rata = TextAlign.left}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Text(isi, style: gaya, textAlign: rata),
      );

  TableRow _barisTabel(BarisNota b) => TableRow(
        children: [
          _sel(b.banyak, _teks),
          _sel(b.nama, _teks),
          _sel(Format.ribuan(b.harga), _angka, rata: TextAlign.right),
          _sel(Format.ribuan(b.jumlah), _angka, rata: TextAlign.right),
        ],
      );

  TableRow _subjudul(String isi) => TableRow(
        decoration: const BoxDecoration(color: AppTheme.permukaan),
        children: [
          const SizedBox.shrink(),
          _sel(isi, _tebal.copyWith(fontSize: 11.5, color: AppTheme.primary)),
          const SizedBox.shrink(),
          const SizedBox.shrink(),
        ],
      );

  Widget _barisAkhir(String label, String nilai,
      {bool tebal = false, Key? kunci}) {
    final gaya = tebal ? _tebal.copyWith(fontSize: 14) : _angka;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: gaya, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 120,
            child: Text(
              nilai,
              key: kunci,
              style: gaya.copyWith(fontFeatures: AppTheme.angkaRata),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = nota;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kepala nota: identitas usaha di kiri, tanggal dan nama di kanan.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Nota.namaUsaha,
                      style: _tebal.copyWith(
                        fontSize: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(Nota.alamatUsaha, style: _teks),
                    Text('WA ${Nota.whatsappUsaha}', style: _teks),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal : ${Format.tanggalAngka(n.tanggalNota)}',
                    key: const Key('nota-tanggal'),
                    style: _teks,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      'Nama     : ${n.namaPelanggan}',
                      key: const Key('nota-nama'),
                      style: _teks,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Table(
            border: const TableBorder(
              top: _garis,
              bottom: _garis,
              left: _garis,
              right: _garis,
              horizontalInside: _garis,
              verticalInside: _garis,
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.1),
              1: FlexColumnWidth(2.8),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.6),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                children: [
                  _sel('Banyak', _tebal),
                  _sel('Nama', _tebal, rata: TextAlign.center),
                  _sel('Harga', _tebal, rata: TextAlign.center),
                  _sel('Jumlah', _tebal, rata: TextAlign.center),
                ],
              ),
              for (final k in n.menu) ...[
                if (n.tampilkanTanggalKirim)
                  _subjudul('Kirim ${Format.tanggalAngka(k.tanggalKirim)}'),
                for (final b in k.baris) _barisTabel(b),
              ],
              for (final b in n.ongkosKirim) _barisTabel(b),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          _barisAkhir(
            'Jumlah Rp.',
            Format.ribuan(n.jumlahRp),
            tebal: true,
            kunci: const Key('nota-jumlah'),
          ),
          _barisAkhir(
            'Sudah dibayar',
            Format.ribuan(n.sudahDibayar),
            kunci: const Key('nota-dibayar'),
          ),
          _barisAkhir(
            'Sisa',
            Format.ribuan(n.sisa),
            kunci: const Key('nota-sisa'),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Status pembayaran  ', style: _teks),
              StatusBadge(n.status),
            ],
          ),
        ],
      ),
    );
  }
}
