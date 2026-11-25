import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/screens/rekap_screen.dart';
import 'package:kelola_katering/utils/format.dart';
import 'package:kelola_katering/utils/theme.dart';
import 'package:kelola_katering/widgets/kotak_ikon.dart';

import 'data_uji.dart';

void main() {
  testWidgets('Rekap memakai kartu putih dan kotak ikon status', (
    tester,
  ) async {
    final sekarang = DateTime.now();
    tester.view.physicalSize = const Size(375, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RekapScreen(semua: [pesananUji(tanggal: sekarang)]),
      ),
    );

    expect(
      tester.widget<Text>(find.byKey(const Key('total-pendapatan'))).data,
      'Rp 105.000',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('rekap-belumBayar'))).data,
      '1 pesanan',
    );
    final kartu = find.ancestor(
      of: find.byKey(const Key('total-pendapatan')),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration == AppTheme.dekorasiKartu,
      ),
    );
    expect(kartu, findsOneWidget);
    expect(find.byType(KotakIkon), findsAtLeastNWidgets(4));

    await tester.tap(find.byKey(const Key('bulan-berikutnya')));
    await tester.pump();
    final bulanDepan = DateTime(sekarang.year, sekarang.month + 1);
    expect(
      find.text(Format.bulanTahun(bulanDepan.year, bulanDepan.month)),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('total-pendapatan'))).data,
      'Rp 0',
    );
  });
}
