import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/data/repositori.dart';
import 'package:kelola_katering/data/repositori_memori.dart';
import 'package:kelola_katering/models/nota.dart';
import 'package:kelola_katering/models/profil_usaha.dart';
import 'package:kelola_katering/screens/cek_status_login.dart';
import 'package:kelola_katering/screens/profil_usaha_screen.dart';
import 'package:kelola_katering/utils/theme.dart';
import 'package:kelola_katering/utils/validasi_profil.dart';
import 'package:kelola_katering/widgets/logo_usaha.dart';
import 'package:kelola_katering/widgets/nota_kertas.dart';

import 'data_uji.dart';

/// PNG 1 x 1 piksel untuk menguji logo.
final Uint8List _pngKecil = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

Widget _bungkus(Widget anak) => MaterialApp(theme: AppTheme.light, home: anak);

void main() {
  late RepositoriMemori repo;

  setUp(() {
    repo = RepositoriMemori();
    Repositori.instance = repo;
  });
  tearDown(() => ProfilUsaha.aktif.value = ProfilUsaha.kosong);

  group('ProfilUsaha', () {
    test('inisial diambil dari huruf depan dua kata pertama', () {
      expect(const ProfilUsaha(nama: 'Mustika Ayu Catering').inisial, 'MA');
      expect(const ProfilUsaha(nama: '  dapur  ').inisial, 'D');
      expect(ProfilUsaha.kosong.inisial, '?');
    });

    test('profil lengkap bila nama usaha terisi', () {
      expect(ProfilUsaha.kosong.lengkap, isFalse);
      expect(const ProfilUsaha(nama: '   ').lengkap, isFalse);
      expect(const ProfilUsaha(nama: 'Dapur Bu Sari').lengkap, isTrue);
    });

    test('toMap dan fromMap saling bolak-balik', () {
      final asal = ProfilUsaha(
        nama: 'Dapur Bu Sari',
        alamat: 'Jl. Melati 5',
        whatsapp: '081234567890',
        logo: base64Encode(_pngKecil),
      );
      final hasil = ProfilUsaha.fromMap(asal.toMap());
      expect(hasil.nama, 'Dapur Bu Sari');
      expect(hasil.alamat, 'Jl. Melati 5');
      expect(hasil.whatsapp, '081234567890');
      expect(hasil.logoBytes, _pngKecil);
    });
  });

  group('ValidasiProfil', () {
    test('nama usaha wajib diisi', () {
      expect(ValidasiProfil.nama(''), 'Nama usaha wajib diisi');
      expect(ValidasiProfil.nama('Dapur'), isNull);
    });

    test('nomor WhatsApp boleh kosong, tetapi hanya angka 8-15 digit', () {
      expect(ValidasiProfil.whatsapp(''), isNull);
      expect(ValidasiProfil.whatsapp('0812-3456-7890'), isNull);
      expect(ValidasiProfil.whatsapp('+6281234567890'), isNull);
      expect(ValidasiProfil.whatsapp('abc'), isNotNull);
      expect(ValidasiProfil.whatsapp('0812'), isNotNull);
    });
  });

  testWidgets('Profil kosong tidak bisa disimpan tanpa nama usaha',
      (tester) async {
    await tester.pumpWidget(_bungkus(const ProfilUsahaScreen(wajib: true)));

    await tester.tap(find.byKey(const Key('simpan-profil')));
    await tester.pump();

    expect(find.text('Nama usaha wajib diisi'), findsOneWidget);
    expect(await repo.pantauProfil().first, isNull);
  });

  testWidgets('Profil dan logo yang dipilih tersimpan', (tester) async {
    await tester.pumpWidget(_bungkus(ProfilUsahaScreen(
      wajib: true,
      pilihGambar: () async => _pngKecil,
    )));

    await tester.enterText(
        find.byKey(const Key('profil-nama')), '  Dapur Bu Sari ');
    await tester.enterText(
        find.byKey(const Key('profil-alamat')), 'Jl. Melati 5');
    await tester.enterText(
        find.byKey(const Key('profil-whatsapp')), '081234567890');
    await tester.tap(find.byKey(const Key('pilih-logo')));
    await tester.pump();
    expect(find.byKey(const Key('hapus-logo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('simpan-profil')));
    await tester.pump();

    final tersimpan = await repo.pantauProfil().first;
    expect(tersimpan!.nama, 'Dapur Bu Sari');
    expect(tersimpan.alamat, 'Jl. Melati 5');
    expect(tersimpan.logoBytes, _pngKecil);
    expect(ProfilUsaha.aktif.value.nama, 'Dapur Bu Sari');
  });

  testWidgets('Logo yang terlalu besar ditolak', (tester) async {
    await tester.pumpWidget(_bungkus(ProfilUsahaScreen(
      pilihGambar: () async =>
          Uint8List(ProfilUsahaScreen.batasLogo + 1),
    )));

    await tester.tap(find.byKey(const Key('pilih-logo')));
    await tester.pump();

    expect(find.textContaining('terlalu besar'), findsOneWidget);
    expect(find.byKey(const Key('hapus-logo')), findsNothing);
  });

  testWidgets('Akun baru tanpa profil diarahkan ke Profil Usaha',
      (tester) async {
    await tester.pumpWidget(_bungkus(const GerbangProfil()));
    await tester.pump();

    expect(find.byType(ProfilUsahaScreen), findsOneWidget);
  });

  testWidgets('Akun dengan profil langsung masuk ke Dashboard',
      (tester) async {
    await repo.simpanProfil(const ProfilUsaha(nama: 'Dapur Bu Sari'));
    await tester.pumpWidget(_bungkus(const GerbangProfil()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProfilUsahaScreen), findsNothing);
    expect(find.text('Dapur Bu Sari'), findsWidgets);
    expect(ProfilUsaha.aktif.value.nama, 'Dapur Bu Sari');
  });

  testWidgets('Kepala nota memakai profil usaha dan huruf depan bila tanpa logo',
      (tester) async {
    await tester.pumpWidget(_bungkus(Scaffold(
      body: SingleChildScrollView(
        child: NotaKertas(
          nota: Nota.dariPesanan(pesananUji()),
          profil: const ProfilUsaha(nama: 'Dapur Bu Sari'),
        ),
      ),
    )));

    expect(find.text('Dapur Bu Sari'), findsOneWidget);
    expect(find.text('DB'), findsOneWidget);
    expect(find.textContaining('WA:'), findsNothing);
    expect(
      find.text('Terima kasih atas pesanan Anda di Dapur Bu Sari.'),
      findsOneWidget,
    );
  });

  testWidgets('LogoUsaha memakai logo unggahan dari profil', (tester) async {
    await tester.pumpWidget(_bungkus(Scaffold(
      body: LogoUsaha(
        profil: ProfilUsaha(nama: 'Dapur', logo: base64Encode(_pngKecil)),
      ),
    )));

    final gambar = tester.widget<Image>(find.byType(Image));
    expect(gambar.image, isA<MemoryImage>());
  });
}
