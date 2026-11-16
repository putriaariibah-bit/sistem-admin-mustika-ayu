import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/data/repositori.dart';
import 'package:kelola_katering/data/repositori_memori.dart';
import 'package:kelola_katering/screens/dashboard_screen.dart';
import 'package:kelola_katering/screens/detail_pesanan_screen.dart';
import 'package:kelola_katering/utils/theme.dart';

import 'data_uji.dart';

double _kontras(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final terang = la > lb ? la : lb;
  final gelap = la > lb ? lb : la;
  return (terang + 0.05) / (gelap + 0.05);
}

void main() {
  test('Teks tersier cukup kontras di atas putih (WCAG AA 4,5:1)', () {
    expect(_kontras(AppTheme.textTersier, Colors.white),
        greaterThanOrEqualTo(4.5));
  });

  testWidgets('Baris kiriman di Dashboard punya Material untuk efek ketuk',
      (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: DashboardScreen(
        semua: [pesananUji(tanggal: DateTime.now())],
        onPesananTap: (_) {},
      ),
    ));

    final kartu = find.byKey(const Key('kartu-kiriman-hari-ini'));
    final ink = find.descendant(of: kartu, matching: find.byType(InkWell));
    expect(ink, findsOneWidget);
    expect(
      find.descendant(of: kartu, matching: find.byType(Material)),
      findsWidgets,
    );
  });

  testWidgets('Tombol bawah Detail selebar konten pada layar lebar',
      (tester) async {
    final repo = RepositoriMemori();
    Repositori.instance = repo;
    final p = pesananUji();
    final id = await repo.tambahPesanan(p);
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: DetailPesananScreen(pesanan: p.copyWith(id: id)),
    ));
    await tester.pump();

    final kiri = tester.getRect(find.byKey(const Key('ubah-pesanan'))).left;
    final kanan = tester.getRect(find.byKey(const Key('lihat-nota'))).right;
    expect(kanan - kiri, lessThanOrEqualTo(AppTheme.lebarKontenMaks));
  });
}
