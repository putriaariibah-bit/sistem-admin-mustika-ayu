import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'masuk_screen.dart';

/// Menentukan halaman yang tampil berdasarkan status login (KNF-05).
///
/// - Belum masuk: [MasukScreen].
/// - Sudah masuk: [HomeShell] (Dashboard dan Daftar Pesanan).
///
/// Sesi disimpan oleh Firebase Authentication, sehingga pemilik tetap
/// masuk saat aplikasi dibuka ulang sampai menekan Keluar.
class CekStatusLogin extends StatelessWidget {
  const CekStatusLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return HomeShell(onKeluar: () => FirebaseAuth.instance.signOut());
        }
        return const MasukScreen();
      },
    );
  }
}
