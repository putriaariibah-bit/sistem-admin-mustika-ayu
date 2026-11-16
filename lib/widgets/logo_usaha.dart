import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Logo Mustika Ayu Catering di dalam kotak putih bergaris tipis.
///
/// Gambar logo berupa garis biru #1F3A5F berlatar transparan.
class LogoUsaha extends StatelessWidget {
  static const String aset = 'assets/images/logo_mustika.png';

  final double ukuran;

  const LogoUsaha({super.key, this.ukuran = 44});

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
      child: Image.asset(aset, fit: BoxFit.contain),
    );
  }
}
