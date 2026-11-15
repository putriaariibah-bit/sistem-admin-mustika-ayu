import 'konversi.dart';

/// Satu catatan pembayaran (entitas Pembayaran).
///
/// Disimpan sebagai map di dalam array `pembayaran` dokumen pesanan.
class Pembayaran {
  final int noUrut;
  final DateTime tanggalBayar;
  final int nominal;
  final String keterangan;

  const Pembayaran({
    required this.noUrut,
    required this.tanggalBayar,
    required this.nominal,
    this.keterangan = '',
  });

  Map<String, Object?> toMap() => {
        'noUrut': noUrut,
        'tanggalBayar': tanggalBayar,
        'nominal': nominal,
        'keterangan': keterangan.trim(),
      };

  factory Pembayaran.fromMap(Map<String, Object?> data) => Pembayaran(
        noUrut: Konversi.angka(data['noUrut']),
        tanggalBayar: Konversi.tanggal(data['tanggalBayar']),
        nominal: Konversi.angka(data['nominal']),
        keterangan: (data['keterangan'] as String?) ?? '',
      );
}
