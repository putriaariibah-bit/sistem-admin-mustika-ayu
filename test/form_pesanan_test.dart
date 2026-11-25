import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/data/repositori.dart';
import 'package:kelola_katering/data/repositori_memori.dart';
import 'package:kelola_katering/screens/form_pesanan_screen.dart';
import 'package:kelola_katering/utils/theme.dart';

Future<void> _bukaForm(WidgetTester tester) async {
  Repositori.instance = RepositoriMemori();
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const FormPesananScreen()),
  );
}

void main() {
  testWidgets('BB-07: jumlah porsi kosong ditolak', (tester) async {
    await _bukaForm(tester);
    await tester.tap(find.byKey(const Key('simpan-pesanan')));
    await tester.pump();

    expect(find.text('Jumlah porsi wajib diisi'), findsOneWidget);
    expect(find.text('Pelanggan wajib dipilih'), findsOneWidget);
  });

  testWidgets('BB-06: pesanan tanpa rincian menu ditolak', (tester) async {
    await _bukaForm(tester);
    await tester.tap(find.byKey(const Key('hapus-menu-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('simpan-pesanan')));
    await tester.pump();

    expect(find.text('Rincian menu wajib diisi'), findsOneWidget);
  });

  testWidgets('BB-11 dan BB-12: total dihitung otomatis', (tester) async {
    await _bukaForm(tester);
    await tester.enterText(find.byKey(const Key('nama-menu-0')), 'Rica ayam');
    await tester.enterText(find.byKey(const Key('porsi-0')), '2');
    await tester.enterText(find.byKey(const Key('harga-0')), '40000');
    await tester.tap(find.byKey(const Key('tambah-menu')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('nama-menu-1')), 'Sayur asem');
    await tester.enterText(find.byKey(const Key('porsi-1')), '1');
    await tester.enterText(find.byKey(const Key('harga-1')), '25000');
    await tester.tap(find.byKey(const Key('tambah-ongkir')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('jumlah-kirim-0')), '4');
    await tester.enterText(find.byKey(const Key('tarif-0')), '9000');
    await tester.pump();

    expect(find.text('Rp 105.000'), findsOneWidget); // total menu
    expect(find.text('Rp 36.000'), findsOneWidget); // total ongkos kirim
    expect(find.text('Rp 141.000'), findsOneWidget); // total tagihan
  });
}
