import 'package:flutter/material.dart';

import '../models/profil_usaha.dart';
import '../utils/theme.dart';

/// Logo usaha di dalam kotak putih bergaris tipis.
///
/// - Tanpa [profil]: logo Mustika Ayu Catering dari aset (garis biru
///   #1F3A5F berlatar transparan).
/// - Dengan [profil] yang punya logo: logo unggahan pemilik.
/// - Dengan [profil] tanpa logo: huruf depan nama usaha.
class LogoUsaha extends StatelessWidget {
  static const String aset = 'assets/images/logo_mustika.png';

  final double ukuran;
  final ProfilUsaha? profil;

  const LogoUsaha({super.key, this.ukuran = 44, this.profil});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      padding: EdgeInsets.all(ukuran * 0.14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ukuran * 0.27),
        border: Border.all(color: AppTheme.garisKartu),
      ),
      child: GambarLogo(profil: profil, ukuranHuruf: ukuran * 0.36),
    );
  }
}

/// Isi logo saja (tanpa bingkai): aset bawaan, logo unggahan, atau huruf
/// depan nama usaha. Dipakai juga oleh kepala nota.
class GambarLogo extends StatelessWidget {
  final ProfilUsaha? profil;
  final double ukuranHuruf;

  const GambarLogo({super.key, this.profil, this.ukuranHuruf = 16});

  @override
  Widget build(BuildContext context) {
    final p = profil;
    if (p == null) return Image.asset(LogoUsaha.aset, fit: BoxFit.contain);
    final bytes = p.logoBytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
    }
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          p.inisial,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: ukuranHuruf,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Logo aplikasi KelolaKatering di halaman Masuk: kotak biru bergradasi
/// berisi ikon makanan. Dipakai sebelum pemilik masuk, saat profil usaha
/// belum diketahui.
class LogoAplikasi extends StatelessWidget {
  final double ukuran;

  const LogoAplikasi({super.key, this.ukuran = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFF2D5486)],
        ),
        borderRadius: BorderRadius.circular(ukuran * 0.27),
      ),
      child: Icon(
        Icons.restaurant_menu,
        color: Colors.white,
        size: ukuran * 0.5,
      ),
    );
  }
}
