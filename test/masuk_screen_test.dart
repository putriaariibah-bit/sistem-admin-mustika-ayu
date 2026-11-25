import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/screens/masuk_screen.dart';
import 'package:kelola_katering/utils/theme.dart';
import 'package:kelola_katering/utils/validasi_masuk.dart';

Widget _bungkus(Widget anak) => MaterialApp(theme: AppTheme.light, home: anak);

void main() {
  testWidgets('BB-01: kolom kosong menampilkan pemberitahuan', (tester) async {
    var dipanggil = false;
    await tester.pumpWidget(
      _bungkus(
        MasukScreen(fungsiMasuk: (email, sandi) async => dipanggil = true),
      ),
    );

    await tester.tap(find.byKey(const Key('tombol-masuk')));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(dipanggil, isFalse);
  });

  testWidgets('BB-02: kata sandi salah ditolak dengan pesan', (tester) async {
    await tester.pumpWidget(
      _bungkus(
        MasukScreen(
          fungsiMasuk: (email, sandi) async =>
              throw FirebaseAuthException(code: 'invalid-credential'),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('masuk-email')),
      'pemilik@contoh.com',
    );
    await tester.enterText(find.byKey(const Key('masuk-kata-sandi')), 'salah');
    await tester.tap(find.byKey(const Key('tombol-masuk')));
    await tester.pump();

    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
  });

  testWidgets('BB-03: email dan kata sandi benar diteruskan ke Firebase', (
    tester,
  ) async {
    String? emailTerkirim;
    await tester.pumpWidget(
      _bungkus(
        MasukScreen(fungsiMasuk: (email, sandi) async => emailTerkirim = email),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('masuk-email')),
      ' pemilik@contoh.com ',
    );
    await tester.enterText(
      find.byKey(const Key('masuk-kata-sandi')),
      'rahasia123',
    );
    await tester.tap(find.byKey(const Key('tombol-masuk')));
    await tester.pump();

    expect(emailTerkirim, 'pemilik@contoh.com');
    expect(find.byKey(const Key('masuk-pesan-gagal')), findsNothing);
  });

  test('Pesan kesalahan koneksi', () {
    expect(
      ValidasiMasuk.pesanDariKode('network-request-failed'),
      'Tidak dapat terhubung. Periksa koneksi internet.',
    );
  });
}
