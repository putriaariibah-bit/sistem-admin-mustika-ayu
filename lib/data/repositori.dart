import '../models/pelanggan.dart';
import '../models/pesanan.dart';
import '../models/profil_usaha.dart';
import '../models/riwayat_perubahan.dart';
import 'repositori_firestore.dart';

/// Pintu tunggal ke penyimpanan data aplikasi.
///
/// Aplikasi memakai [RepositoriFirestore] (Cloud Firestore). Pengujian
/// widget mengganti [instance] dengan RepositoriMemori agar tidak perlu
/// menghubungi Firebase.
abstract class Repositori {
  static Repositori? _instance;

  /// Repositori yang sedang dipakai. Dibuat saat pertama kali diakses.
  static Repositori get instance => _instance ??= RepositoriFirestore();
  static set instance(Repositori repositori) => _instance = repositori;

  // ── Profil usaha (pengembangan lanjutan, di luar Bab III) ────
  /// Profil usaha akun yang sedang masuk; null bila belum pernah diisi.
  Stream<ProfilUsaha?> pantauProfil();

  Future<void> simpanProfil(ProfilUsaha profil);

  // ── Pelanggan (proses 2.0, KF-02) ────────────────────────────
  Stream<List<Pelanggan>> pantauPelanggan();

  /// Menambah pelanggan baru (id kosong) atau mengubah namanya.
  Future<Pelanggan> simpanPelanggan(Pelanggan pelanggan);

  // ── Pesanan (proses 3.0 dan 4.0, KF-03 sampai KF-07) ─────────
  /// Seluruh pesanan, terbaru menurut tanggal nota lebih dulu.
  Stream<List<Pesanan>> pantauPesanan();

  /// Satu pesanan; bernilai null bila pesanan sudah dihapus.
  Stream<Pesanan?> pantauSatuPesanan(String id);

  /// Riwayat perubahan satu pesanan, terbaru lebih dulu.
  Stream<List<RiwayatPerubahan>> pantauRiwayat(String pesananId);

  /// Menyimpan pesanan baru dan mengembalikan ID dokumennya.
  Future<String> tambahPesanan(Pesanan pesanan);

  /// Menyimpan perubahan pesanan beserta riwayat perubahannya (KF-06).
  /// Pencatatan pembayaran juga memakai method ini.
  Future<void> ubahPesanan(Pesanan lama, Pesanan baru);

  /// Menghapus pesanan beserta riwayatnya (KF-06, BB-14).
  Future<void> hapusPesanan(String id);
}
