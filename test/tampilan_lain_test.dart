import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/screens/masuk_screen.dart';
import 'package:kelola_katering/screens/nota_screen.dart';
import 'package:kelola_katering/utils/theme.dart';
import 'package:kelola_katering/widgets/logo_usaha.dart';
import 'package:kelola_katering/widgets/sidebar_menu.dart';

import 'data_uji.dart';

void main() {
  testWidgets('Halaman Masuk menampilkan logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MasukScreen(fungsiMasuk: (email, sandi) async {}),
      ),
    );
    expect(find.byType(LogoUsaha), findsOneWidget);
  });

  testWidgets('Sidebar menampilkan logo dan menu aktif berlatar muda', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(children: [SidebarMenu(indeksAktif: 0, onPilih: (_) {})]),
        ),
      ),
    );
    expect(find.byType(LogoUsaha), findsOneWidget);
    final aktif = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const Key('nav-dashboard')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(aktif.color, AppTheme.primaryMuda);
  });

  testWidgets('Judul kolom BANYAK pada nota tetap satu baris di 375 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NotaScreen(pesanan: pesananUji()),
      ),
    );
    final tinggi = tester.getSize(find.text('BANYAK')).height;
    expect(tinggi, lessThan(20));
  });
}
