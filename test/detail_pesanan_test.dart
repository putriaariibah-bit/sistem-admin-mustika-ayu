import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/data/repositori.dart';
import 'package:kelola_katering/data/repositori_memori.dart';
import 'package:kelola_katering/models/pesanan.dart';
import 'package:kelola_katering/screens/detail_pesanan_screen.dart';
import 'package:kelola_katering/utils/theme.dart';

import 'data_uji.dart';

Future<void> _buka(WidgetTester tester, Pesanan p) async {
  final repo = RepositoriMemori();
  Repositori.instance = repo;
  final id = await repo.tambahPesanan(p);
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: DetailPesananScreen(pesanan: p.copyWith(id: id)),
  ));
  await tester.pump();
}

void main() {
  testWidgets('Tombol Lihat Nota dan Ubah terlihat tanpa menggulir',
      (tester) async {
    await _buka(tester, pesananUji(dibayar: 141000));

    for (final kunci in ['lihat-nota', 'ubah-pesanan']) {
      final kotak = tester.getRect(find.byKey(Key(kunci)));
      expect(kotak.bottom, lessThanOrEqualTo(812), reason: kunci);
    }
    final judulTotal = find.byKey(const Key('total-tagihan'));
    final teks = tester.widget<Text>(judulTotal);
    expect(teks.style?.color, AppTheme.primary);
  });

  testWidgets('Pesanan lunas: Catat Pembayaran nonaktif', (tester) async {
    await _buka(tester, pesananUji(dibayar: 141000));
    await tester.scrollUntilVisible(
      find.byKey(const Key('catat-pembayaran')),
      200,
    );
    final tombol = tester.widget<FilledButton>(
      find.byKey(const Key('catat-pembayaran')),
    );
    expect(tombol.onPressed, isNull);
    expect(find.text('Sudah lunas'), findsOneWidget);
  });

  testWidgets('Nama sangat panjang tidak meluber', (tester) async {
    await _buka(tester, pesananUji(nama: 'Ibu ' * 20));
    expect(tester.takeException(), isNull);
  });
}
