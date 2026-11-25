import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/models/pesanan.dart';
import 'package:kelola_katering/utils/theme.dart';
import 'package:kelola_katering/widgets/kotak_ikon.dart';
import 'package:kelola_katering/widgets/logo_usaha.dart';
import 'package:kelola_katering/widgets/status_badge.dart';

Widget _bungkus(Widget anak) => MaterialApp(
  home: Scaffold(body: Center(child: anak)),
);

void main() {
  testWidgets('KotakIkon.status memakai warna pastel status Lunas', (
    tester,
  ) async {
    await tester.pumpWidget(_bungkus(KotakIkon.status(StatusPembayaran.lunas)));

    final kotak = tester.widget<Container>(
      find.descendant(
        of: find.byType(KotakIkon),
        matching: find.byType(Container),
      ),
    );
    final dekorasi = kotak.decoration! as BoxDecoration;
    expect(dekorasi.color, WarnaStatus.latar(StatusPembayaran.lunas));

    final ikon = tester.widget<Icon>(find.byType(Icon));
    expect(ikon.icon, WarnaStatus.ikon(StatusPembayaran.lunas));
    expect(ikon.color, WarnaStatus.utama(StatusPembayaran.lunas));
  });

  testWidgets('LogoUsaha menampilkan logo dari aset', (tester) async {
    await tester.pumpWidget(_bungkus(const LogoUsaha()));

    final gambar = tester.widget<Image>(find.byType(Image));
    expect(
      (gambar.image as AssetImage).assetName,
      'assets/images/logo_mustika.png',
    );
  });

  test('Token kartu putih sesuai desain', () {
    expect(AppTheme.sudutKartu, 12.0);
    expect(AppTheme.garisKartu, const Color(0xFFE5E7EB));
    expect(AppTheme.dekorasiKartu.color, Colors.white);
  });
}
