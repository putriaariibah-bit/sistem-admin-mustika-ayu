import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/repositori.dart';
import 'firebase_options.dart';
import 'models/pesanan.dart';
import 'models/profil_usaha.dart';
import 'screens/cek_status_login.dart';
import 'screens/daftar_pesanan_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/detail_pesanan_screen.dart';
import 'screens/form_pesanan_screen.dart';
import 'screens/profil_usaha_screen.dart';
import 'screens/rekap_screen.dart';
import 'utils/theme.dart';
import 'widgets/empty_state.dart';
import 'widgets/sidebar_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KelolaKateringApp());
}

/// Root widget aplikasi Mustika Ayu Catering.
///
/// Menggunakan [AppTheme.light] sebagai tema Material 3
/// dan [CekStatusLogin] sebagai halaman awal.
class KelolaKateringApp extends StatelessWidget {
  /// Halaman pertama aplikasi. Bawaannya [CekStatusLogin]; pengujian
  /// widget memakai [HomeShell] agar tidak memanggil Firebase.
  final Widget halamanAwal;

  const KelolaKateringApp({
    super.key,
    this.halamanAwal = const CekStatusLogin(),
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mustika Ayu Catering',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: halamanAwal,
    );
  }
}

/// Pembungkus tiga tujuan utama: Dashboard, Daftar Pesanan, dan Rekap.
///
/// - ponsel (lebar < 600 px): [NavigationBar] di bawah;
/// - layar lebar (lebar >= 600 px): [SidebarMenu] di kiri.
///
/// Data pesanan dibaca sekali dari [Repositori] dan dibagikan ke kedua
/// halaman, sehingga angka di Dashboard dan isi Daftar Pesanan selalu sama.
class HomeShell extends StatefulWidget {
  /// Dipanggil saat pemilik menekan Keluar. Jika null, tombol disembunyikan.
  final VoidCallback? onKeluar;

  const HomeShell({super.key, this.onKeluar});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  // Data pesanan didengarkan sekali di sini, bukan lewat StreamBuilder di
  // dalam tata letak. Saat lebar layar berganti (ponsel <-> layar lebar),
  // posisi halaman di pohon widget ikut berubah; StreamBuilder akan
  // berlangganan ulang dan data terakhir tidak datang lagi.
  late final StreamSubscription<List<Pesanan>> _langganan;
  List<Pesanan> _semua = const [];
  bool _memuat = true;
  Object? _galat;

  @override
  void initState() {
    super.initState();
    _langganan = Repositori.instance.pantauPesanan().listen(
      (data) => setState(() {
        _semua = data;
        _memuat = false;
        _galat = null;
      }),
      onError: (Object e) => setState(() => _galat = e),
    );
  }

  @override
  void dispose() {
    _langganan.cancel();
    super.dispose();
  }

  void _pilihTab(int index) => setState(() => _currentIndex = index);

  void _tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _bukaDetailPesanan(Pesanan pesanan) async {
    final hasil = await Navigator.push<HasilDetail>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPesananScreen(pesanan: pesanan),
      ),
    );
    if (mounted && hasil == HasilDetail.dihapus) {
      _tampilkanPesan('Pesanan dihapus.');
    }
  }

  Future<void> _bukaProfil() async {
    final tersimpan = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilUsahaScreen(awal: ProfilUsaha.aktif.value),
      ),
    );
    if (mounted && tersimpan == true) _tampilkanPesan('Profil usaha disimpan.');
  }

  Future<void> _bukaFormTambah() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const FormPesananScreen()),
    );
    if (mounted && berhasil == true) {
      _tampilkanPesan('Pesanan baru berhasil disimpan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lebar = AppTheme.layarLebar(context);

    final Widget halaman;
    if (_galat != null) {
      halaman = Scaffold(
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Data tidak dapat dimuat',
          subtitle: '$_galat',
        ),
      );
    } else {
      halaman = IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            semua: _semua,
            memuat: _memuat,
            onLihatSemua: () => _pilihTab(1),
            onPesananTap: _bukaDetailPesanan,
            onTambah: _bukaFormTambah,
            onKeluar: widget.onKeluar,
            onProfil: _bukaProfil,
          ),
          DaftarPesananScreen(
            semua: _semua,
            memuat: _memuat,
            onPesananTap: _bukaDetailPesanan,
            onTambah: _bukaFormTambah,
          ),
          RekapScreen(
            semua: _semua,
            memuat: _memuat,
            onPesananTap: _bukaDetailPesanan,
          ),
        ],
      );
    }

    if (lebar) {
      return Scaffold(
        body: Row(
          children: [
            SidebarMenu(
              indeksAktif: _currentIndex,
              onPilih: _pilihTab,
              onKeluar: widget.onKeluar,
              onProfil: _bukaProfil,
            ),
            Expanded(child: halaman),
          ],
        ),
      );
    }

    return Scaffold(
      body: halaman,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.garisKartu)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _pilihTab,
          destinations: const [
            NavigationDestination(
              key: Key('nav-dashboard'),
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Dashboard',
            ),
            NavigationDestination(
              key: Key('nav-daftar-pesanan'),
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Daftar Pesanan',
            ),
            NavigationDestination(
              key: Key('nav-rekap'),
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Rekap',
            ),
          ],
        ),
      ),
    );
  }
}
