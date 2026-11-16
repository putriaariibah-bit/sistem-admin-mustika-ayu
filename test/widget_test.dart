import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/data/repositori.dart';
import 'package:kelola_katering/data/repositori_memori.dart';
import 'package:kelola_katering/main.dart';

void main() {
  testWidgets('Aplikasi menampilkan Dashboard setelah masuk', (tester) async {
    Repositori.instance = RepositoriMemori();
    await tester.pumpWidget(const KelolaKateringApp(halamanAwal: HomeShell()));
    await tester.pump();

    // Layar uji 800 x 600 termasuk layar lebar: menu di sidebar.
    expect(find.byKey(const Key('nav-dashboard')), findsOneWidget);
    expect(find.byKey(const Key('nav-daftar-pesanan')), findsOneWidget);
    expect(find.byKey(const Key('nav-rekap')), findsOneWidget);
    expect(find.text('Tidak ada kiriman hari ini'), findsOneWidget);
  });
}
