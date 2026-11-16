/// Fungsi bantu pemformatan tanggal dan Rupiah.
///
/// Dibuat manual tanpa package tambahan (batas Modul 6 dan 7),
/// dan dipakai bersama oleh seluruh halaman agar formatnya seragam.
class Format {
  Format._(); // mencegah instansiasi

  static const List<String> _bulanSingkat = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _bulanPanjang = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// Indeks 0 = Senin, sesuai [DateTime.weekday] dikurangi satu.
  static const List<String> _hari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  /// Contoh: `18 Okt 2026`.
  static String tanggal(DateTime t) =>
      '${t.day} ${_bulanSingkat[t.month - 1]} ${t.year}';

  /// Contoh: `09/11/2026`, format hari/bulan/tahun pada nota (KNF-06).
  static String tanggalAngka(DateTime t) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${dua(t.day)}/${dua(t.month)}/${t.year}';
  }

  /// Contoh: `Kamis, 15 Oktober 2026`.
  static String tanggalPanjang(DateTime t) =>
      '${_hari[t.weekday - 1]}, ${t.day} ${_bulanPanjang[t.month - 1]} '
      '${t.year}';

  /// Contoh: `1.750.000` (tanpa "Rp").
  static String ribuan(int nilai) {
    final angka = nilai.abs().toString();
    final hasil = StringBuffer();
    for (var i = 0; i < angka.length; i++) {
      final sisa = angka.length - i;
      hasil.write(angka[i]);
      if (sisa > 1 && sisa % 3 == 1) hasil.write('.');
    }
    return '${nilai < 0 ? '-' : ''}$hasil';
  }

  /// Contoh: `Rp 1.750.000`.
  static String rupiah(int harga) =>
      harga < 0 ? 'Rp -${ribuan(-harga)}' : 'Rp ${ribuan(harga)}';

  /// Contoh: `November 2026`.
  static String bulanTahun(int tahun, int bulan) =>
      '${_bulanPanjang[bulan - 1]} $tahun';

  /// Sapaan sesuai jam: pagi, siang, sore, atau malam.
  static String sapaan(DateTime t) {
    if (t.hour < 11) return 'Selamat pagi';
    if (t.hour < 15) return 'Selamat siang';
    if (t.hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}
