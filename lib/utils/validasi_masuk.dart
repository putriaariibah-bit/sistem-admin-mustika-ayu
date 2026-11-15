/// Aturan validasi dan pesan kesalahan halaman Masuk.
///
/// Dipisah dari tampilan agar mudah diuji (BB-01 dan BB-02).
class ValidasiMasuk {
  ValidasiMasuk._();

  static final RegExp _polaEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// BB-01: email wajib diisi dan berformat email.
  static String? email(String? nilai) {
    final teks = nilai?.trim() ?? '';
    if (teks.isEmpty) return 'Email wajib diisi';
    if (!_polaEmail.hasMatch(teks)) return 'Format email belum benar';
    return null;
  }

  /// BB-01: kata sandi wajib diisi.
  static String? kataSandi(String? nilai) {
    if (nilai == null || nilai.isEmpty) return 'Kata sandi wajib diisi';
    return null;
  }

  /// BB-02: menerjemahkan kode kesalahan Firebase Authentication.
  ///
  /// Email tidak terdaftar dan kata sandi salah diberi pesan yang sama
  /// agar orang lain tidak dapat menebak email mana yang terdaftar.
  static String pesanDariKode(String kode) {
    switch (kode) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Email atau kata sandi salah.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak dapat terhubung. Periksa koneksi internet.';
      default:
        return 'Gagal masuk. Silakan coba lagi.';
    }
  }
}
