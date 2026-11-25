import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/models/pesanan.dart';
import 'package:kelola_katering/utils/theme.dart';
import 'package:kelola_katering/widgets/pesanan_card.dart';
import 'package:kelola_katering/widgets/status_badge.dart';

import 'data_uji.dart';

Future<void> _pasang(WidgetTester tester, Pesanan p) async {
  tester.view.physicalSize = const Size(320, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ListView(children: [PesananCard(pesanan: p)]),
      ),
    ),
  );
}

void main() {
  testWidgets('Kartu pesanan putih dengan badge di kanan bawah', (
    tester,
  ) async {
    await _pasang(tester, pesananUji(dibayar: 50000));

    final kartu = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(PesananCard),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(kartu.decoration, AppTheme.dekorasiKartu);

    final nota = find.textContaining('Nota 3 Nov 2026', findRichText: true);
    expect(
      tester.getTopLeft(find.byType(StatusBadge)).dx,
      greaterThan(tester.getTopLeft(nota).dx),
    );
    expect(
      find.textContaining('Sisa Rp 91.000', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('Pesanan lunas menampilkan jenis pesanan', (tester) async {
    await _pasang(
      tester,
      pesananUji(dibayar: 141000, jenis: JenisPesanan.langgananHarian),
    );
    expect(
      find.textContaining('Langganan harian', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Lunas'), findsOneWidget);
  });

  testWidgets('Nama dan menu panjang tidak meluber di layar 320 px', (
    tester,
  ) async {
    await _pasang(tester, pesananUji(nama: 'Ibu ' * 20));
    expect(tester.takeException(), isNull);
  });
}
