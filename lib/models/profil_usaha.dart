import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Identitas usaha katering milik satu akun: nama, alamat, nomor
/// WhatsApp, dan logo. Dipakai pada kepala nota dan kepala Dashboard.
///
/// Disimpan di Firestore pada dokumen `usaha/{uid}`. Fitur ini adalah
/// pengembangan lanjutan di luar rancangan Bab III, agar aplikasi dapat
/// dipakai pemilik katering lain.
class ProfilUsaha {
  final String nama;
  final String alamat;
  final String whatsapp;

  /// Gambar logo dalam bentuk base64; null bila belum diunggah.
  final String? logo;

  const ProfilUsaha({
    required this.nama,
    this.alamat = '',
    this.whatsapp = '',
    this.logo,
  });

  static const ProfilUsaha kosong = ProfilUsaha(nama: '');

  /// Identitas Mustika Ayu Catering. Dipakai bila profil belum dimuat,
  /// misalnya pada pengujian widget.
  static const ProfilUsaha bawaan = ProfilUsaha(
    nama: 'Mustika Ayu Catering',
    alamat: 'Jl. Kendeng II No. 4 Semarang',
    whatsapp: '08112921703',
  );

  /// Profil akun yang sedang masuk. Diisi oleh [GerbangProfil] setelah
  /// profil dibaca dari Firestore.
  static final ValueNotifier<ProfilUsaha> aktif = ValueNotifier(kosong);

  /// Profil dianggap lengkap bila nama usaha sudah diisi.
  bool get lengkap => nama.trim().isNotEmpty;

  /// Isi logo yang sudah diubah kembali menjadi byte gambar.
  Uint8List? get logoBytes {
    final isi = logo;
    if (isi == null || isi.isEmpty) return null;
    try {
      return base64Decode(isi);
    } on FormatException {
      return null;
    }
  }

  /// Huruf depan dua kata pertama nama usaha, mis. "MA" untuk Mustika
  /// Ayu Catering. Dipakai sebagai pengganti logo.
  String get inisial {
    final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty);
    if (kata.isEmpty) return '?';
    return kata.take(2).map((k) => k[0].toUpperCase()).join();
  }

  /// Salinan dengan spasi di awal dan akhir isian dibuang.
  ProfilUsaha get dirapikan => ProfilUsaha(
        nama: nama.trim(),
        alamat: alamat.trim(),
        whatsapp: whatsapp.trim(),
        logo: logo,
      );

  Map<String, dynamic> toMap() => {
        'nama': nama.trim(),
        'alamat': alamat.trim(),
        'whatsapp': whatsapp.trim(),
        'logo': logo,
      };

  factory ProfilUsaha.fromMap(Map<String, dynamic> data) => ProfilUsaha(
        nama: (data['nama'] as String?) ?? '',
        alamat: (data['alamat'] as String?) ?? '',
        whatsapp: (data['whatsapp'] as String?) ?? '',
        logo: data['logo'] as String?,
      );
}
