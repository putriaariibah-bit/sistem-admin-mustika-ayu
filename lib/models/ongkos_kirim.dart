import 'konversi.dart';

/// Satu baris ongkos kirim (entitas Ongkos Kirim), terpisah dari menu.
///
/// Disimpan sebagai map di dalam array `ongkosKirim` dokumen pesanan.
/// Ongkos kirim tercatat di nota, tetapi tidak dihitung sebagai pendapatan.
class OngkosKirim {
  final int noUrut;
  final String keterangan;
  final int jumlahKirim;
  final int tarif;

  const OngkosKirim({
    required this.noUrut,
    this.keterangan = '',
    required this.jumlahKirim,
    required this.tarif,
  });

  /// Aturan 3.2.4 nomor 2: subtotal = jumlah kirim x tarif.
  int get subtotal => jumlahKirim * tarif;

  Map<String, Object?> toMap() => {
    'noUrut': noUrut,
    'keterangan': keterangan.trim(),
    'jumlahKirim': jumlahKirim,
    'tarif': tarif,
    'subtotal': subtotal,
  };

  factory OngkosKirim.fromMap(Map<String, Object?> data) => OngkosKirim(
    noUrut: Konversi.angka(data['noUrut']),
    keterangan: (data['keterangan'] as String?) ?? '',
    jumlahKirim: Konversi.angka(data['jumlahKirim']),
    tarif: Konversi.angka(data['tarif']),
  );
}
