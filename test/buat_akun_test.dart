import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/screens/buat_akun_screen.dart';
import 'package:kelola_katering/screens/masuk_screen.dart';
import 'package:kelola_katering/utils/theme.dart';

Widget _bungkus(Widget anak) => MaterialApp(theme: AppTheme.light, home: anak);

Future<void> _isi(WidgetTester tester, String email, String sandi,
    String ulangi) async {
  await tester.enterText(find.byKey(const Key('akun-email')), email);
  await tester.enterText(find.byKey(const Key('akun-kata-sandi')), sandi);
  await tester.enterText(find.byKey(const Key('akun-ulangi-sandi')), ulangi);
  await tester.tap(find.byKey(const Key('kirim-buat-akun')));
  await tester.pump();
}

void main() {
  testWidgets('Buat Akun: kolom kosong ditolak', (tester) async {
    var dipanggil = false;
    await tester.pumpWidget(_bungkus(BuatAkunScreen(
      fungsiBuatAkun: (e, s) async => dipanggil = true,
    )));

    await _isi(tester, '', '', '');

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(dipanggil, isFalse);
  });

  testWidgets('Buat Akun: sandi pendek dan sandi berbeda ditolak',
      (tester) async {
    await tester.pumpWidget(_bungkus(BuatAkunScreen(
      fungsiBuatAkun: (e, s) async {},
    )));

    await _isi(tester, 'sari@contoh.com', '123', '124');

    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
    expect(find.text('Kata sandi tidak sama'), findsOneWidget);
  });

  testWidgets('Buat Akun: email yang sudah terdaftar diberi pesan',
      (tester) async {
    await tester.pumpWidget(_bungkus(BuatAkunScreen(
      fungsiBuatAkun: (e, s) async =>
          throw FirebaseAuthException(code: 'email-already-in-use'),
    )));

    await _isi(tester, 'sari@contoh.com', 'rahasia1', 'rahasia1');

    expect(find.text('Email ini sudah terdaftar. Silakan masuk.'),
        findsOneWidget);
  });

  testWidgets('Halaman Masuk membuka Buat Akun lalu kembali setelah berhasil',
      (tester) async {
    String? emailDibuat;
    await tester.pumpWidget(_bungkus(MasukScreen(
      fungsiMasuk: (e, s) async {},
      fungsiBuatAkun: (e, s) async => emailDibuat = e,
    )));

    await tester.tap(find.byKey(const Key('tombol-buat-akun')));
    await tester.pumpAndSettle();
    expect(find.byType(BuatAkunScreen), findsOneWidget);

    await _isi(tester, ' sari@contoh.com ', 'rahasia1', 'rahasia1');
    await tester.pumpAndSettle();

    expect(emailDibuat, 'sari@contoh.com');
    expect(find.byType(BuatAkunScreen), findsNothing);
  });

  testWidgets('Lupa kata sandi mengirim email ke alamat yang diisi',
      (tester) async {
    String? emailReset;
    await tester.pumpWidget(_bungkus(MasukScreen(
      fungsiMasuk: (e, s) async {},
      fungsiLupaSandi: (e) async => emailReset = e,
    )));

    await tester.enterText(
        find.byKey(const Key('masuk-email')), 'sari@contoh.com');
    await tester.tap(find.byKey(const Key('tombol-lupa-sandi')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kirim-lupa-sandi')));
    await tester.pumpAndSettle();

    expect(emailReset, 'sari@contoh.com');
    expect(find.textContaining('tautan untuk membuat kata sandi baru'),
        findsOneWidget);
  });

  testWidgets('Tombol Masuk dengan Google memanggil fungsi login Google',
      (tester) async {
    var dipanggil = false;
    await tester.pumpWidget(_bungkus(MasukScreen(
      fungsiMasuk: (e, s) async {},
      fungsiMasukGoogle: () async => dipanggil = true,
    )));

    await tester.tap(find.byKey(const Key('tombol-masuk-google')));
    await tester.pump();

    expect(dipanggil, isTrue);
  });

  testWidgets('Jendela Google yang ditutup tidak menampilkan pesan gagal',
      (tester) async {
    await tester.pumpWidget(_bungkus(MasukScreen(
      fungsiMasuk: (e, s) async {},
      fungsiMasukGoogle: () async =>
          throw FirebaseAuthException(code: 'popup-closed-by-user'),
    )));

    await tester.tap(find.byKey(const Key('tombol-masuk-google')));
    await tester.pump();

    expect(find.byKey(const Key('masuk-pesan-gagal')), findsNothing);
  });
}
