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

  /// Kata sandi untuk akun baru: wajib diisi, minimal 6 karakter
  /// (batas minimal Firebase Authentication).
  static String? kataSandiBaru(String? nilai) {
    if (nilai == null || nilai.isEmpty) return 'Kata sandi wajib diisi';
    if (nilai.length < 6) return 'Kata sandi minimal 6 karakter';
    return null;
  }

  static String? ulangiKataSandi(String? nilai, String kataSandi) {
    if (nilai == null || nilai.isEmpty) return 'Ulangi kata sandi';
    if (nilai != kataSandi) return 'Kata sandi tidak sama';
    return null;
  }

  /// Pesan kesalahan saat membuat akun baru.
  static String pesanBuatAkun(String kode) {
    switch (kode) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan masuk.';
      case 'invalid-email':
        return 'Format email belum benar.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
      case 'operation-not-allowed':
        return 'Pembuatan akun belum diaktifkan.';
      case 'network-request-failed':
        return 'Tidak dapat terhubung. Periksa koneksi internet.';
      default:
        return 'Gagal membuat akun. Silakan coba lagi.';
    }
  }

  /// Pesan kesalahan saat mengirim email lupa kata sandi.
  static String pesanLupaSandi(String kode) {
    switch (kode) {
      case 'invalid-email':
        return 'Format email belum benar.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak dapat terhubung. Periksa koneksi internet.';
      default:
        return 'Gagal mengirim email. Silakan coba lagi.';
    }
  }

  /// Kode yang berarti pemilik menutup jendela Google sendiri; tidak
  /// perlu ditampilkan sebagai kesalahan.
  static bool dibatalkanPengguna(String kode) => const {
        'popup-closed-by-user',
        'cancelled-popup-request',
        'web-context-canceled',
        'canceled',
        'user-cancelled',
      }.contains(kode);

  /// Pesan kesalahan saat masuk dengan Google.
  static String pesanGoogle(String kode) {
    switch (kode) {
      case 'account-exists-with-different-credential':
        return 'Email ini sudah terdaftar dengan kata sandi. '
            'Masuk dengan email dan kata sandi.';
      case 'popup-blocked':
        return 'Jendela Google diblokir browser. Izinkan pop-up lalu coba lagi.';
      case 'operation-not-allowed':
        return 'Masuk dengan Google belum diaktifkan.';
      case 'network-request-failed':
        return 'Tidak dapat terhubung. Periksa koneksi internet.';
      default:
        return 'Gagal masuk dengan Google. Silakan coba lagi.';
    }
  }
}
