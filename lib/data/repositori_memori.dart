import 'dart:async';

import '../models/aturan_pesanan.dart';
import '../models/pelanggan.dart';
import '../models/pesanan.dart';
import '../models/profil_usaha.dart';
import '../models/riwayat_perubahan.dart';
import 'repositori.dart';

/// Penyimpanan sementara di memori untuk pengujian widget.
///
/// Perilakunya sama dengan [Repositori] lain, tetapi data hilang saat
/// aplikasi ditutup dan tidak menghubungi Firebase.
class RepositoriMemori implements Repositori {
  ProfilUsaha? _profil;
  final List<Pelanggan> _pelanggan = [];
  final List<Pesanan> _pesanan = [];
  final Map<String, List<RiwayatPerubahan>> _riwayat = {};
  final _berubah = StreamController<void>.broadcast();
  var _nomor = 0;

  String _idBaru() => 'id${++_nomor}';

  Stream<T> _pantau<T>(T Function() ambil) async* {
    yield ambil();
    yield* _berubah.stream.map((_) => ambil());
  }

  void _kabari() => _berubah.add(null);

  @override
  Stream<ProfilUsaha?> pantauProfil() => _pantau(() => _profil);

  @override
  Future<void> simpanProfil(ProfilUsaha profil) async {
    _profil = profil;
    _kabari();
  }

  @override
  Stream<List<Pelanggan>> pantauPelanggan() => _pantau(() =>
      List<Pelanggan>.of(_pelanggan)..sort((a, b) => a.nama.compareTo(b.nama)));

  @override
  Future<Pelanggan> simpanPelanggan(Pelanggan pelanggan) async {
    var hasil = pelanggan;
    if (pelanggan.id.isEmpty) {
      hasil = pelanggan.copyWith(id: _idBaru());
      _pelanggan.add(hasil);
    } else {
      final i = _pelanggan.indexWhere((p) => p.id == pelanggan.id);
      if (i >= 0) _pelanggan[i] = pelanggan;
    }
    _kabari();
    return hasil;
  }

  @override
  Stream<List<Pesanan>> pantauPesanan() => _pantau(() =>
      List<Pesanan>.of(_pesanan)
        ..sort((a, b) => b.tanggalNota.compareTo(a.tanggalNota)));

  @override
  Stream<Pesanan?> pantauSatuPesanan(String id) => _pantau(() {
        for (final p in _pesanan) {
          if (p.id == id) return p;
        }
        return null;
      });

  @override
  Stream<List<RiwayatPerubahan>> pantauRiwayat(String pesananId) =>
      _pantau(() => List<RiwayatPerubahan>.of(_riwayat[pesananId] ?? const [])
          .reversed
          .toList());

  @override
  Future<String> tambahPesanan(Pesanan pesanan) async {
    final sekarang = DateTime.now();
    final id = _idBaru();
    _pesanan.add(
      pesanan.copyWith(id: id, dibuatPada: sekarang, diubahPada: sekarang),
    );
    _kabari();
    return id;
  }

  @override
  Future<void> ubahPesanan(Pesanan lama, Pesanan baru) async {
    final sekarang = DateTime.now();
    final riwayat = AturanPesanan.bandingkan(lama, baru, sekarang);
    if (riwayat.isEmpty) return;
    final i = _pesanan.indexWhere((p) => p.id == lama.id);
    if (i < 0) return;
    _pesanan[i] = baru.copyWith(id: lama.id, diubahPada: sekarang);
    _riwayat.putIfAbsent(lama.id, () => []).addAll(riwayat);
    _kabari();
  }

  @override
  Future<void> hapusPesanan(String id) async {
    _pesanan.removeWhere((p) => p.id == id);
    _riwayat.remove(id);
    _kabari();
  }
}
