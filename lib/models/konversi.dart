/// Fungsi bantu konversi nilai dari dan ke dokumen Cloud Firestore.
///
/// Model data sengaja tidak bergantung pada package cloud_firestore agar
/// mudah diuji. Firestore menerima [DateTime] saat menulis, dan
/// mengembalikan objek Timestamp saat membaca; keduanya ditangani di sini.
class Konversi {
  Konversi._();

  /// Membaca tanggal dari DateTime, Timestamp Firestore, atau teks ISO.
  static DateTime tanggal(Object? nilai) {
    if (nilai is DateTime) return nilai;
    if (nilai is String) return DateTime.parse(nilai);
    if (nilai != null) {
      // Timestamp Firestore memiliki method toDate().
      return (nilai as dynamic).toDate() as DateTime;
    }
    throw ArgumentError('Tanggal kosong');
  }

  /// Membaca bilangan bulat (Rupiah, porsi) dari int atau double.
  static int angka(Object? nilai) => (nilai as num?)?.toInt() ?? 0;

  /// Kunci tanggal berbentuk `yyyy-MM-dd`, mis. `2026-11-13`.
  ///
  /// Dipakai pada field daftarTanggalKirim (Tabel 3.8) agar saringan
  /// "dikirim hari ini" cukup mencocokkan teks, tanpa memperhitungkan jam.
  static String kunciTanggal(DateTime t) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${dua(t.month)}-${dua(t.day)}';
  }

  /// Tanggal tanpa jam (pukul 00.00).
  static DateTime tanpaJam(DateTime t) => DateTime(t.year, t.month, t.day);
}
