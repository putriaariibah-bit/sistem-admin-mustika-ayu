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

    // Layar uji 800 x 600 termasuk layar lebar: "Dashboard" tampil
    // sebagai judul halaman dan sebagai menu sidebar.
    expect(find.text('Dashboard'), findsNWidgets(2));
    expect(find.byKey(const Key('nav-daftar-pesanan')), findsOneWidget);
    expect(find.text('Belum ada pesanan'), findsWidgets);
  });
}
