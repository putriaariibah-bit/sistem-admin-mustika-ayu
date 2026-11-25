import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../main.dart';
import '../models/profil_usaha.dart';
import '../widgets/empty_state.dart';
import 'masuk_screen.dart';
import 'profil_usaha_screen.dart';

/// Menentukan halaman yang tampil berdasarkan status login (KNF-05).
///
/// - Belum masuk: [MasukScreen].
/// - Sudah masuk: [GerbangProfil], yang menampilkan Profil Usaha bila
///   profil belum diisi, atau [HomeShell] bila sudah.
///
/// Sesi disimpan oleh Firebase Authentication, sehingga pemilik tetap
/// masuk saat aplikasi dibuka ulang sampai menekan Keluar.
class CekStatusLogin extends StatelessWidget {
  const CekStatusLogin({super.key});

  static Future<void> _keluar() async {
    ProfilUsaha.aktif.value = ProfilUsaha.kosong;
    await FirebaseAuth.instance.signOut();
  }

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
        final pengguna = snapshot.data;
        if (pengguna != null) {
          return GerbangProfil(
            key: ValueKey(pengguna.uid),
            onKeluar: () => unawaited(_keluar()),
          );
        }
        return const MasukScreen();
      },
    );
  }
}

/// Membaca profil usaha akun yang sedang masuk, lalu menampilkan halaman
/// Profil Usaha (bila belum diisi) atau [HomeShell].
class GerbangProfil extends StatefulWidget {
  final VoidCallback? onKeluar;

  const GerbangProfil({super.key, this.onKeluar});

  @override
  State<GerbangProfil> createState() => _GerbangProfilState();
}

class _GerbangProfilState extends State<GerbangProfil> {
  // Setiap profil yang diterima langsung disimpan ke ProfilUsaha.aktif,
  // sehingga kepala Dashboard dan nota ikut berubah.
  late final Stream<ProfilUsaha?> _profil = Repositori.instance
      .pantauProfil()
      .map((p) {
        if (p != null && p.lengkap) ProfilUsaha.aktif.value = p;
        return p;
      });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProfilUsaha?>(
      stream: _profil,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              actions: [
                if (widget.onKeluar != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: widget.onKeluar,
                    child: const Text('Keluar'),
                  ),
              ],
            ),
            body: EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Profil usaha tidak dapat dimuat',
              subtitle: '${snapshot.error}',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profil = snapshot.data;
        if (profil == null || !profil.lengkap) {
          return ProfilUsahaScreen(
            awal: profil ?? ProfilUsaha.kosong,
            wajib: true,
            onKeluar: widget.onKeluar,
          );
        }
        return HomeShell(onKeluar: widget.onKeluar);
      },
    );
  }
}
