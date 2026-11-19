import 'package:flutter/material.dart';

import '../models/nota.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'logo_usaha.dart';
import 'status_badge.dart';

/// Tampilan nota (Gambar 3.8(f)).
///
/// Susunannya: kepala usaha (logo, nama, alamat, WhatsApp), judul NOTA
/// dengan tanggal nota dan status pembayaran, kotak pelanggan dan kotak
/// informasi pesanan, tabel Banyak, Nama, Harga, Jumlah seperti nota
/// kertas (ditambah baris ongkos kirim), jumlah tagihan, sudah dibayar,
/// sisa, lalu ucapan terima kasih. Alamat pelanggan tidak dipakai.
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
    height: 1.35,
  );
  static final _tebal = _teks.copyWith(fontWeight: FontWeight.w700);
  static final _redup = _teks.copyWith(color: AppTheme.textTersier);
  static final _angka = _teks.copyWith(fontFeatures: AppTheme.angkaRata);
  static final _labelKecil = _teks.copyWith(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
    color: AppTheme.textTersier,
  );

  static const _garisTipis = Color(0xFFE3E7EE);
  static const _garisTerima = Color(0xFFB9C7DA);
  static const _latarTerima = Color(0xFFF6F8FB);

  /// Lebar relatif kolom Banyak, Nama, Harga, dan Jumlah.
  static const _lebarKolom = [12, 24, 16, 19];

  /// Nomor WhatsApp dikelompokkan empat angka, mis. `0811 2921 703`.
  static String _nomorWa(String nomor) {
    final hasil = StringBuffer();
    for (var i = 0; i < nomor.length; i++) {
      if (i > 0 && i % 4 == 0) hasil.write(' ');
      hasil.write(nomor[i]);
    }
    return hasil.toString();
  }

  /// Teks satu baris yang mengecil bila tempatnya terlalu sempit.
  static Widget _satuBaris(
    String isi,
    TextStyle gaya, {
    Alignment rata = Alignment.centerLeft,
    Key? kunci,
  }) =>
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: rata,
        child: Text(
          isi,
          key: kunci,
          style: gaya,
          maxLines: 1,
          softWrap: false,
        ),
      );

  Widget _kepala() => Column(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: AppTheme.primaryMuda,
              shape: BoxShape.circle,
            ),
            child: Image.asset(LogoUsaha.aset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(
            Nota.namaUsaha,
            textAlign: TextAlign.center,
            style: _tebal.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Nota.alamatUsaha,
            textAlign: TextAlign.center,
            style: _redup.copyWith(fontSize: 11.5),
          ),
          Text(
            'WA: ${_nomorWa(Nota.whatsappUsaha)}',
            textAlign: TextAlign.center,
            style: _redup.copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          Container(height: 2, color: AppTheme.primary),
        ],
      );

  Widget _judulNota() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOTA',
                  style: _tebal.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  children: [
                    Text('Tanggal nota: ', style: _redup),
                    Text(
                      Format.tanggalAngka(nota.tanggalNota),
                      key: const Key('nota-tanggal'),
                      style: _tebal,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text('Status Pembayaran:', style: _redup),
                StatusBadge(nota.status),
              ],
            ),
          ),
        ],
      );

  Widget _kotak(String judul, List<Widget> isi) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.garis),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: _labelKecil),
            const SizedBox(height: 4),
            ...isi,
          ],
        ),
      );

  Widget _isiInfo(String label, String nilai, {Key? kunci}) => Wrap(
        children: [
          Text('$label ', style: _redup),
          Text(nilai, key: kunci, style: _teks),
        ],
      );

  Widget _kotakPelangganDanPesanan() => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _kotak('PELANGGAN', [
                Text(
                  nota.namaPelanggan,
                  key: const Key('nota-nama'),
                  style: _tebal.copyWith(fontSize: 13.5),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kotak('INFORMASI PESANAN', [
                _isiInfo('Jenis:', nota.jenis, kunci: const Key('nota-jenis')),
                _isiInfo('Tanggal kirim:', nota.teksTanggalKirim),
              ]),
            ),
          ],
        ),
      );

  /// Satu baris tabel dengan empat kolom.
  Widget _baris(
    List<Widget> sel, {
    double tebalGaris = 1,
    Color warnaGaris = _garisTipis,
    double atas = 9,
    double bawah = 9,
  }) =>
      Container(
        padding: EdgeInsets.only(top: atas, bottom: bawah),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: warnaGaris, width: tebalGaris),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < sel.length; i++)
              Expanded(
                flex: _lebarKolom[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: sel[i],
                ),
              ),
          ],
        ),
      );

  Widget _barisRincian(BarisNota b, {bool ongkir = false}) {
    final gaya = ongkir ? _teks.copyWith(color: AppTheme.textSecondary) : _teks;
    final angka = gaya.copyWith(fontFeatures: AppTheme.angkaRata);
    return _baris([
      _satuBaris(b.banyak, gaya),
      Text(b.nama, style: gaya),
      _satuBaris(Format.ribuan(b.harga), angka, rata: Alignment.centerRight),
      _satuBaris(
        Format.ribuan(b.jumlah),
        ongkir ? angka : angka.copyWith(fontWeight: FontWeight.w700),
        rata: Alignment.centerRight,
      ),
    ]);
  }

  Widget _subjudul(String isi) => Padding(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 2),
        child: _satuBaris(
          isi,
          _tebal.copyWith(fontSize: 11.5, color: AppTheme.primary),
        ),
      );

  Widget _tabel() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _baris(
            [
              _satuBaris('BANYAK', _labelKecil),
              _satuBaris('NAMA', _labelKecil),
              _satuBaris('HARGA', _labelKecil, rata: Alignment.centerRight),
              _satuBaris('JUMLAH', _labelKecil, rata: Alignment.centerRight),
            ],
            tebalGaris: 2,
            warnaGaris: AppTheme.garis,
            atas: 6,
            bawah: 7,
          ),
          for (final k in nota.menu) ...[
            if (nota.tampilkanTanggalKirim)
              _subjudul('Kirim ${Format.tanggalAngka(k.tanggalKirim)}'),
            for (final b in k.baris) _barisRincian(b),
          ],
          for (final b in nota.ongkosKirim) _barisRincian(b, ongkir: true),
        ],
      );

  Widget _barisTotal(String label, String nilai, TextStyle gayaNilai,
          {Key? kunci}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: _teks.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: _satuBaris(
                nilai,
                gayaNilai.copyWith(fontFeatures: AppTheme.angkaRata),
                rata: Alignment.centerRight,
                kunci: kunci,
              ),
            ),
          ],
        ),
      );

  Widget _total() {
    final warnaSisa =
        nota.sisa > 0 ? AppTheme.bayarBelum : AppTheme.bayarLunas;
    return Row(
      children: [
        const Spacer(flex: 2),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _garisTipis)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'JUMLAH RP.',
                      style: _tebal.copyWith(
                        fontSize: 11.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: _satuBaris(
                        Format.ribuan(nota.jumlahRp),
                        _tebal.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          fontFeatures: AppTheme.angkaRata,
                        ),
                        rata: Alignment.centerRight,
                        kunci: const Key('nota-jumlah'),
                      ),
                    ),
                  ],
                ),
              ),
              _barisTotal(
                'Sudah dibayar',
                Format.ribuan(nota.sudahDibayar),
                _teks.copyWith(fontWeight: FontWeight.w600),
                kunci: const Key('nota-dibayar'),
              ),
              _barisTotal(
                'Sisa',
                Format.ribuan(nota.sisa),
                _tebal.copyWith(color: warnaSisa),
                kunci: const Key('nota-sisa'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _terimaKasih() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _latarTerima,
          border: Border.all(color: _garisTerima),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              'Terima kasih atas pesanan Anda di ${Nota.namaUsaha}.',
              textAlign: TextAlign.center,
              style: _teks.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              'Semoga hidangan kami memuaskan.',
              textAlign: TextAlign.center,
              style: _redup.copyWith(fontSize: 11),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _kepala(),
          const SizedBox(height: 16),
          _judulNota(),
          const SizedBox(height: 14),
          _kotakPelangganDanPesanan(),
          const SizedBox(height: 14),
          _tabel(),
          const SizedBox(height: 8),
          _total(),
          const SizedBox(height: 20),
          _terimaKasih(),
        ],
      ),
    );
  }
}
