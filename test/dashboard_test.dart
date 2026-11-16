import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/models/pesanan.dart';
import 'package:kelola_katering/screens/dashboard_screen.dart';
import 'package:kelola_katering/utils/theme.dart';
import 'package:kelola_katering/widgets/logo_usaha.dart';

import 'data_uji.dart';

Future<void> _pasang(
  WidgetTester tester,
  List<Pesanan> semua, {
  double skalaHuruf = 1,
}) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    builder: (context, anak) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(skalaHuruf)),
      child: anak!,
    ),
    home: DashboardScreen(semua: semua, onKeluar: () {}),
  ));
}

void main() {
  testWidgets('Dashboard memakai logo dan kartu kiriman putih',
      (tester) async {
    await _pasang(tester, const []);

    expect(find.byType(LogoUsaha), findsOneWidget);
    final kartu = tester.widget<Container>(
      find.byKey(const Key('kartu-kiriman-hari-ini')),
    );
    expect(kartu.decoration, AppTheme.dekorasiKartu);
    expect(find.text('Tidak ada kiriman hari ini'), findsOneWidget);
  });

  testWidgets('Tujuh kiriman hari ini: lima baris dan sisa dua',
      (tester) async {
    final hariIni = DateTime.now();
    await _pasang(tester, [
      for (var i = 0; i < 7; i++)
        pesananUji(nama: 'Pelanggan $i', tanggal: hariIni),
    ]);

    expect(find.text('+2 pesanan lain di Daftar Pesanan'), findsOneWidget);
    expect(find.text('Pelanggan 5'), findsNothing);
  });

  testWidgets('Layar 360 px dengan huruf 1,3x tidak meluber',
      (tester) async {
    await _pasang(tester, [pesananUji()], skalaHuruf: 1.3);
    expect(tester.takeException(), isNull);
  });
}
