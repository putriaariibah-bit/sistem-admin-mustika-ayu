import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'status_badge.dart';

/// Kartu satu pesanan pada Daftar Pesanan.
///
/// Nama pelanggan dan badge status di atas, tanggal nota di kanan atas,
/// lalu baris berlabel (Jenis, Total tagihan, Sisa, Menu, Kirim) dan
/// tombol Catat Bayar, Lihat Nota, serta Detail di bawah.
class KartuPesananDaftar extends StatelessWidget {
  final Pesanan pesanan;
  final VoidCallback? onDetail;
  final VoidCallback? onNota;
  final VoidCallback? onCatatBayar;

  const KartuPesananDaftar({
    super.key,
    required this.pesanan,
    this.onDetail,
    this.onNota,
    this.onCatatBayar,
  });

  static const _label = TextStyle(
    fontSize: 12.5,
    color: AppTheme.textTersier,
    height: 1.35,
  );

  String get _menu {
    final nama = <String, int>{};
    for (final r in pesanan.rincian) {
      nama[r.namaMenu] = (nama[r.namaMenu] ?? 0) + r.jumlahPorsi;
    }
    return nama.entries.map((e) => '${e.key} ×${e.value}').join(', ');
  }

  String _kirim(DateTime hariIni) {
    final tanggal = pesanan.rincian.map((r) => r.tanggalKirim).toList()
      ..sort();
    if (tanggal.isEmpty) return '-';
    final awal = Format.tanggal(tanggal.first);
    final akhir = Format.tanggal(tanggal.last);
    final teks = awal == akhir ? awal : '$awal – $akhir';
    return pesanan.dikirimPada(hariIni) ? '$teks (hari ini)' : teks;
  }

  Widget _baris(String label, String nilai, {Color? warna, int baris = 1}) =>
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text.rich(
          TextSpan(
            text: '$label: ',
            children: [
              TextSpan(
                text: nilai,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: warna ?? AppTheme.textPrimary,
                  fontFeatures: AppTheme.angkaRata,
                ),
              ),
            ],
          ),
          maxLines: baris,
          overflow: TextOverflow.ellipsis,
          style: _label,
        ),
      );

  static ButtonStyle _gayaTombol(Color latar, {bool garis = false}) {
    final bentuk = WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 6),
      ),
      shape: bentuk,
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (garis) return Colors.white;
        return s.contains(WidgetState.disabled)
            ? AppTheme.garisKartu
            : latar;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((s) {
        if (garis) return AppTheme.primary;
        return s.contains(WidgetState.disabled)
            ? AppTheme.textTersier
            : Colors.white;
      }),
      side: WidgetStatePropertyAll(
        garis
            ? const BorderSide(color: AppTheme.primary, width: 1.3)
            : BorderSide.none,
      ),
    );
  }

  Widget _tombol(Key key, String teks, VoidCallback? aksi, ButtonStyle gaya) =>
      Expanded(
        child: TextButton(
          key: key,
          onPressed: aksi,
          style: gaya,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(teks, maxLines: 1),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    final lunas = p.statusPembayaran == StatusPembayaran.lunas;
    final radius = BorderRadius.circular(16);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.dekorasiKartu.copyWith(borderRadius: radius),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onDetail,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            p.namaPelanggan,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          StatusBadge(p.statusPembayaran),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      Format.tanggal(p.tanggalNota),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTersier,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _baris('Jenis', p.jenisPesanan.label),
                _baris('Total tagihan', Format.rupiah(p.totalTagihan)),
                _baris(
                  'Sisa',
                  Format.rupiah(p.sisaTagihan),
                  warna: p.sisaTagihan > 0
                      ? AppTheme.bayarBelum
                      : AppTheme.bayarLunas,
                ),
                _baris('Menu', _menu, baris: 2),
                _baris('Kirim', _kirim(DateTime.now())),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  children: [
                    _tombol(
                      Key('catat-bayar-${p.id}'),
                      lunas ? 'Sudah Lunas' : 'Catat Bayar',
                      lunas ? null : onCatatBayar,
                      _gayaTombol(const Color(0xFF2F7D3A)),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    _tombol(
                      Key('nota-${p.id}'),
                      'Lihat Nota',
                      onNota,
                      _gayaTombol(AppTheme.primary),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    _tombol(
                      Key('detail-${p.id}'),
                      'Detail',
                      onDetail,
                      _gayaTombol(Colors.white, garis: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
