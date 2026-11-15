import 'konversi.dart';

/// Satu baris rincian menu pada pesanan (entitas Rincian Menu).
///
/// Disimpan sebagai map di dalam array `rincian` dokumen pesanan
/// (Tabel 3.7 dan 3.8).
class RincianMenu {
  final int noUrut;
  final DateTime tanggalKirim;
  final String namaMenu;
  final int jumlahPorsi;
  final int hargaPerPorsi;

  const RincianMenu({
    required this.noUrut,
    required this.tanggalKirim,
    required this.namaMenu,
    required this.jumlahPorsi,
    required this.hargaPerPorsi,
  });

  /// Aturan 3.2.4 nomor 1: subtotal = jumlah porsi x harga per porsi.
  int get subtotal => jumlahPorsi * hargaPerPorsi;

  Map<String, Object?> toMap() => {
        'noUrut': noUrut,
        'tanggalKirim': Konversi.tanpaJam(tanggalKirim),
        'namaMenu': namaMenu.trim(),
        'jumlahPorsi': jumlahPorsi,
        'hargaPerPorsi': hargaPerPorsi,
        'subtotal': subtotal,
      };

  factory RincianMenu.fromMap(Map<String, Object?> data) => RincianMenu(
        noUrut: Konversi.angka(data['noUrut']),
        tanggalKirim: Konversi.tanggal(data['tanggalKirim']),
        namaMenu: (data['namaMenu'] as String?) ?? '',
        jumlahPorsi: Konversi.angka(data['jumlahPorsi']),
        hargaPerPorsi: Konversi.angka(data['hargaPerPorsi']),
      );

  RincianMenu copyWith({
    int? noUrut,
    DateTime? tanggalKirim,
    String? namaMenu,
    int? jumlahPorsi,
    int? hargaPerPorsi,
  }) =>
      RincianMenu(
        noUrut: noUrut ?? this.noUrut,
        tanggalKirim: tanggalKirim ?? this.tanggalKirim,
        namaMenu: namaMenu ?? this.namaMenu,
        jumlahPorsi: jumlahPorsi ?? this.jumlahPorsi,
        hargaPerPorsi: hargaPerPorsi ?? this.hargaPerPorsi,
      );
}
