import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/data/repositori.dart';
import 'package:kelola_katering/data/repositori_memori.dart';
import 'package:kelola_katering/main.dart';
import 'package:kelola_katering/models/rincian_menu.dart';
import 'package:kelola_katering/screens/nota_screen.dart';
import 'package:kelola_katering/utils/theme.dart';

import 'data_uji.dart';

void main() {
  testWidgets('Data tetap tampil saat layar berganti dari ponsel ke lebar', (
    tester,
  ) async {
    final repo = RepositoriMemori();
    Repositori.instance = repo;
    await repo.tambahPesanan(pesananUji(nama: 'Pelanggan A'));

    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KelolaKateringApp(halamanAwal: HomeShell()));
    await tester.pump();
    expect(find.text('Pelanggan A'), findsWidgets);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Data tidak dapat dimuat'), findsNothing);
    expect(find.text('Pelanggan A'), findsWidgets);
  });

  testWidgets('Nominal jutaan pada nota tidak terpotong di layar 375 px', (
    tester,
  ) async {
    final p = pesananUji().copyWith(
      rincian: [
        RincianMenu(
          noUrut: 1,
          tanggalKirim: DateTime(2026, 11, 5),
          namaMenu: 'Nasi Ayam Bakar',
          jumlahPorsi: 50,
          hargaPerPorsi: 30000,
        ),
      ],
    );
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NotaScreen(pesanan: p),
      ),
    );

    for (final teks in ['1.500.000', '50 pcs', 'Kirim 05/11/2026']) {
      expect(
        tester.getSize(find.text(teks)).height,
        lessThan(20),
        reason: teks,
      );
    }
  });
}
