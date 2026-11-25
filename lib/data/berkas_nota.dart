import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../models/profil_usaha.dart';

/// Aksi terhadap berkas nota: simpan atau bagikan.
typedef AksiNota = Future<void> Function(Uint8List png, String namaBerkas);

/// Mengubah tampilan nota di dalam [batas] menjadi gambar PNG.
Future<Uint8List> gambarNota(RenderRepaintBoundary batas) async {
  final gambar = await batas.toImage(pixelRatio: 3);
  final data = await gambar.toByteData(format: ui.ImageByteFormat.png);
  gambar.dispose();
  return data!.buffer.asUint8List();
}

/// Penyimpanan dan pembagian berkas nota (KF-08).
///
/// Aplikasi hanya menyiapkan berkas gambar nota. Pemilik sendiri yang
/// memilih WhatsApp pada menu berbagi ponsel, sehingga tidak ada
/// integrasi otomatis dengan WhatsApp (batasan masalah).
///
/// [instance] dapat diganti tiruan pada pengujian widget (BB-20).
abstract class BerkasNota {
  static BerkasNota instance = BerkasNotaPerangkat();

  /// Menyimpan gambar nota di ponsel.
  Future<void> simpan(Uint8List png, String namaBerkas);

  /// Membuka menu berbagi ponsel dengan gambar nota terlampir.
  Future<void> bagikan(Uint8List png, String namaBerkas);
}

/// Dilempar bila pemilik tidak memberi izin menyimpan ke galeri.
class IzinGaleriDitolak implements Exception {
  const IzinGaleriDitolak();

  @override
  String toString() => 'Izin menyimpan ke galeri tidak diberikan.';
}

/// Implementasi di perangkat: Android menyimpan ke Galeri (album
/// [album]); versi web mengunduh berkasnya.
class BerkasNotaPerangkat implements BerkasNota {
  /// Nama album mengikuti nama usaha pada profil.
  static String get album {
    final profil = ProfilUsaha.aktif.value;
    return profil.lengkap ? profil.nama.trim() : ProfilUsaha.bawaan.nama;
  }

  @override
  Future<void> simpan(Uint8List png, String namaBerkas) async {
    if (kIsWeb) {
      await XFile.fromData(png, mimeType: 'image/png', name: namaBerkas)
          .saveTo(namaBerkas);
      return;
    }
    if (!await Gal.hasPermission(toAlbum: true)) {
      final diizinkan = await Gal.requestPermission(toAlbum: true);
      if (!diizinkan) throw const IzinGaleriDitolak();
    }
    final tanpaEkstensi = namaBerkas.replaceAll(RegExp(r'\.png$'), '');
    await Gal.putImageBytes(png, album: album, name: tanpaEkstensi);
  }

  @override
  Future<void> bagikan(Uint8List png, String namaBerkas) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png', name: namaBerkas)],
        fileNameOverrides: [namaBerkas],
      ),
    );
  }
}
