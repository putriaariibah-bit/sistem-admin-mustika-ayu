/// Aturan validasi halaman Profil Usaha.
class ValidasiProfil {
  ValidasiProfil._();

  static final RegExp _polaWa = RegExp(r'^\+?\d{8,15}$');

  static String? nama(String? nilai) {
    if ((nilai ?? '').trim().isEmpty) return 'Nama usaha wajib diisi';
    return null;
  }

  /// Boleh kosong. Bila diisi, hanya angka (boleh diawali +, boleh ada
  /// spasi atau tanda hubung) sebanyak 8 sampai 15 digit.
  static String? whatsapp(String? nilai) {
    final teks = (nilai ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (teks.isEmpty) return null;
    if (!_polaWa.hasMatch(teks)) {
      return 'Nomor WhatsApp hanya boleh berisi 8-15 angka';
    }
    return null;
  }
}
