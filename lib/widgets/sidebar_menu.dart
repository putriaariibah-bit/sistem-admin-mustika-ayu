import 'package:flutter/material.dart';

import '../models/profil_usaha.dart';
import '../utils/theme.dart';
import 'logo_usaha.dart';

/// Sidebar menu untuk layar lebar (versi web).
///
/// Sesuai rancangan web Figma: nama aplikasi di atas, lalu menu
/// Dashboard dan Daftar Pesanan dengan urutan yang sama seperti
/// navigasi bawah di ponsel. Menu aktif berlatar biru muda.
class SidebarMenu extends StatelessWidget {
  /// Index menu aktif: 0 = Dashboard, 1 = Daftar Pesanan.
  final int indeksAktif;

  /// Dipanggil dengan index menu yang dipilih.
  final ValueChanged<int> onPilih;

  /// Dipanggil saat menu Keluar ditekan. Jika null, menu disembunyikan.
  final VoidCallback? onKeluar;

  /// Dipanggil saat menu Profil Usaha ditekan. Jika null, disembunyikan.
  final VoidCallback? onProfil;

  const SidebarMenu({
    super.key,
    required this.indeksAktif,
    required this.onPilih,
    this.onKeluar,
    this.onProfil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppTheme.lebarSidebar,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.garisKartu)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacing4,
                  AppTheme.spacing8,
                  AppTheme.spacing4,
                  AppTheme.spacing24,
                ),
                child: ValueListenableBuilder<ProfilUsaha>(
                  valueListenable: ProfilUsaha.aktif,
                  builder: (context, profil, _) => Row(
                    children: [
                      LogoUsaha(
                        ukuran: 40,
                        profil: profil.lengkap ? profil : null,
                      ),
                      const SizedBox(width: AppTheme.spacing12 - 2),
                      Expanded(
                        child: Text(
                          profil.lengkap
                              ? profil.nama.trim()
                              : ProfilUsaha.bawaan.nama,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _ItemMenu(
                key: const Key('nav-dashboard'),
                ikon: Icons.grid_view,
                label: 'Dashboard',
                aktif: indeksAktif == 0,
                onTap: () => onPilih(0),
              ),
              const SizedBox(height: AppTheme.spacing4),
              _ItemMenu(
                key: const Key('nav-daftar-pesanan'),
                ikon: Icons.receipt_long,
                label: 'Daftar Pesanan',
                aktif: indeksAktif == 1,
                onTap: () => onPilih(1),
              ),
              const SizedBox(height: AppTheme.spacing4),
              _ItemMenu(
                key: const Key('nav-rekap'),
                ikon: Icons.bar_chart,
                label: 'Rekap',
                aktif: indeksAktif == 2,
                onTap: () => onPilih(2),
              ),
              const Spacer(),
              if (onProfil != null) ...[
                _ItemMenu(
                  key: const Key('nav-profil-usaha'),
                  ikon: Icons.storefront_outlined,
                  label: 'Profil Usaha',
                  aktif: false,
                  onTap: onProfil!,
                ),
                const SizedBox(height: AppTheme.spacing4),
              ],
              if (onKeluar != null) ...[
                _ItemMenu(
                  key: const Key('tombol-keluar'),
                  ikon: Icons.logout,
                  label: 'Keluar',
                  aktif: false,
                  onTap: onKeluar!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData ikon;
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _ItemMenu({
    super.key,
    required this.ikon,
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = aktif ? AppTheme.primary : AppTheme.textSecondary;
    return Material(
      color: aktif ? AppTheme.primaryMuda : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.sudutTombol),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.sudutTombol),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing12,
            vertical: AppTheme.spacing8 + 2,
          ),
          child: Row(
            children: [
              Icon(ikon, size: 18, color: warna),
              const SizedBox(width: AppTheme.spacing8),
              // Expanded + ellipsis agar label tidak meluber bila ukuran
              // huruf sistem diperbesar.
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: aktif ? FontWeight.w600 : FontWeight.w500,
                    color: warna,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
