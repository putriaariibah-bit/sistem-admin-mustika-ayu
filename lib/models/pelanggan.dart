/// Entitas Pelanggan (ERD Gambar 3.5, koleksi `pelanggan` pada Tabel 3.7).
///
/// Hanya menyimpan nama, karena alamat tetap berada di WhatsApp.
class Pelanggan {
  /// ID dokumen Firestore. Kosong untuk pelanggan yang belum disimpan.
  final String id;

  final String nama;

  const Pelanggan({this.id = '', required this.nama});

  /// BB-04 dan BB-05: nama wajib diisi.
  static String? validasiNama(String? nilai) {
    if (nilai == null || nilai.trim().isEmpty) return 'Nama wajib diisi';
    return null;
  }

  Map<String, Object?> toMap() => {'nama': nama.trim()};

  factory Pelanggan.fromMap(String id, Map<String, Object?> data) =>
      Pelanggan(id: id, nama: (data['nama'] as String?) ?? '');

  Pelanggan copyWith({String? id, String? nama}) =>
      Pelanggan(id: id ?? this.id, nama: nama ?? this.nama);
}
