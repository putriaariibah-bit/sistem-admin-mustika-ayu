import 'konversi.dart';

/// Satu catatan perubahan pesanan (entitas Riwayat Perubahan).
///
/// Disimpan di subkoleksi `riwayat` di bawah dokumen pesanan
/// (Tabel 3.7), berisi waktu, bagian, nilaiLama, dan nilaiBaru.
class RiwayatPerubahan {
  final String id;
  final DateTime waktu;
  final String bagian;
  final String nilaiLama;
  final String nilaiBaru;

  const RiwayatPerubahan({
    this.id = '',
    required this.waktu,
    required this.bagian,
    required this.nilaiLama,
    required this.nilaiBaru,
  });

  Map<String, Object?> toMap() => {
        'waktu': waktu,
        'bagian': bagian,
        'nilaiLama': nilaiLama,
        'nilaiBaru': nilaiBaru,
      };

  factory RiwayatPerubahan.fromMap(String id, Map<String, Object?> data) =>
      RiwayatPerubahan(
        id: id,
        waktu: Konversi.tanggal(data['waktu']),
        bagian: (data['bagian'] as String?) ?? '',
        nilaiLama: (data['nilaiLama'] as String?) ?? '',
        nilaiBaru: (data['nilaiBaru'] as String?) ?? '',
      );
}
