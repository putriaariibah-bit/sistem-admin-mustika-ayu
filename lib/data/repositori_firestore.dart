import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/aturan_pesanan.dart';
import '../models/pelanggan.dart';
import '../models/pesanan.dart';
import '../models/profil_usaha.dart';
import '../models/riwayat_perubahan.dart';
import 'repositori.dart';

/// Penyimpanan di Cloud Firestore sesuai pemetaan Tabel 3.7:
/// - koleksi `pelanggan` (field nama);
/// - koleksi `pesanan` (struktur Tabel 3.8), dengan rincian menu,
///   ongkos kirim, dan pembayaran sebagai array berisi map;
/// - subkoleksi `riwayat` di bawah setiap dokumen pesanan.
///
/// Agar aplikasi dapat dipakai lebih dari satu pemilik, seluruh koleksi
/// itu diletakkan di bawah dokumen `usaha/{uid}` milik akun yang sedang
/// masuk. Dokumen `usaha/{uid}` sendiri menyimpan profil usaha. Aturan
/// keamanan Firestore hanya mengizinkan akun membaca dan menulis
/// dokumen usahanya sendiri.
class RepositoriFirestore implements Repositori {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Dokumen usaha milik akun yang sedang masuk.
  DocumentReference<Map<String, dynamic>> get _usaha {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Belum ada akun yang masuk.');
    return _db.collection('usaha').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get _pelanggan =>
      _usaha.collection('pelanggan');
  CollectionReference<Map<String, dynamic>> get _pesanan =>
      _usaha.collection('pesanan');

  // ── Profil usaha ─────────────────────────────────────────────

  @override
  Stream<ProfilUsaha?> pantauProfil() => _usaha.snapshots().map((d) {
    final data = d.data();
    return data == null ? null : ProfilUsaha.fromMap(data);
  });

  @override
  Future<void> simpanProfil(ProfilUsaha profil) => _usaha.set({
    ...profil.toMap(),
    'diperbarui': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // ── Pelanggan ────────────────────────────────────────────────

  @override
  Stream<List<Pelanggan>> pantauPelanggan() => _pelanggan
      .orderBy('nama')
      .snapshots()
      .map((s) => [for (final d in s.docs) Pelanggan.fromMap(d.id, d.data())]);

  @override
  Future<Pelanggan> simpanPelanggan(Pelanggan pelanggan) async {
    if (pelanggan.id.isEmpty) {
      final ref = await _pelanggan.add(pelanggan.toMap());
      return pelanggan.copyWith(id: ref.id);
    }
    await _pelanggan.doc(pelanggan.id).update(pelanggan.toMap());
    return pelanggan;
  }

  // ── Pesanan ──────────────────────────────────────────────────

  /// pelangganId disimpan sebagai reference ke koleksi pelanggan.
  Map<String, Object?> _keDokumen(Pesanan pesanan) {
    final data = pesanan.toMap();
    data['pelangganId'] = pesanan.pelangganId.isEmpty
        ? null
        : _pelanggan.doc(pesanan.pelangganId);
    return data;
  }

  Pesanan _dariDokumen(String id, Map<String, dynamic> data) {
    final salinan = Map<String, Object?>.from(data);
    final ref = salinan['pelangganId'];
    if (ref is DocumentReference) salinan['pelangganId'] = ref.id;
    return Pesanan.fromMap(id, salinan);
  }

  @override
  Stream<List<Pesanan>> pantauPesanan() => _pesanan
      .orderBy('tanggalNota', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) _dariDokumen(d.id, d.data())]);

  @override
  Stream<Pesanan?> pantauSatuPesanan(String id) =>
      _pesanan.doc(id).snapshots().map((d) {
        final data = d.data();
        return data == null ? null : _dariDokumen(d.id, data);
      });

  @override
  Stream<List<RiwayatPerubahan>> pantauRiwayat(String pesananId) => _pesanan
      .doc(pesananId)
      .collection('riwayat')
      .orderBy('waktu', descending: true)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) RiwayatPerubahan.fromMap(d.id, d.data()),
        ],
      );

  @override
  Future<String> tambahPesanan(Pesanan pesanan) async {
    final sekarang = DateTime.now();
    final ref = await _pesanan.add(
      _keDokumen(pesanan.copyWith(dibuatPada: sekarang, diubahPada: sekarang)),
    );
    return ref.id;
  }

  @override
  Future<void> ubahPesanan(Pesanan lama, Pesanan baru) async {
    final sekarang = DateTime.now();
    final riwayat = AturanPesanan.bandingkan(lama, baru, sekarang);
    if (riwayat.isEmpty) return;

    final ref = _pesanan.doc(lama.id);
    // update() hanya menulis field yang disebut, sehingga field audit
    // dibuatPada tidak tersentuh. Bila dokumen sudah dihapus, update()
    // gagal (not-found) dan perubahan tidak membuat dokumen baru.
    final data = _keDokumen(baru.copyWith(diubahPada: sekarang))
      ..remove('dibuatPada');
    final batch = _db.batch();
    batch.update(ref, data);
    for (final r in riwayat) {
      batch.set(ref.collection('riwayat').doc(), r.toMap());
    }
    await batch.commit();
  }

  @override
  Future<void> hapusPesanan(String id) async {
    final ref = _pesanan.doc(id);
    final riwayat = await ref.collection('riwayat').get();
    final batch = _db.batch();
    for (final d in riwayat.docs) {
      batch.delete(d.reference);
    }
    batch.delete(ref);
    await batch.commit();
  }
}
