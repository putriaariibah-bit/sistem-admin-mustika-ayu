# Tampilan Kartu Putih Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merombak gaya semua layar menjadi kartu putih beraksen biru sesuai gambar `D:\SKRIPSI\usulan-tampilan-mustika-ayu.jpg`, tanpa mengubah isi dan alur layar.

**Architecture:** Token gaya dan widget bersama (kotak ikon, logo, dekorasi kartu) dibuat dulu di `lib/utils/theme.dart` dan `lib/widgets/`, lalu tiap layar memakainya. Logika data (`models/`, `data/`) tidak disentuh.

**Tech Stack:** Flutter 3.47.7, Dart 3.13.5, Material 3, font Inter (aset lokal).

**Spec:** `docs/superpowers/specs/2026-11-16-tampilan-kartu-putih-design.md`

## Global Constraints

- Warna Bab III: biru `#1F3A5F` (AppTheme.primary), latar `#F3F4F6` (AppTheme.permukaan), font Inter.
- Isi tiap layar sesuai Gambar 3.7–3.8; tidak ada data/fitur baru.
- Semua `Key` yang sudah ada tetap ada pada widget yang setara (dipakai tes).
- Teks `Tidak ada kiriman hari ini` tetap ada (dipakai `test/widget_test.dart`).
- Tanpa paket pub baru.
- `flutter analyze` tanpa isu; `flutter test` lulus.

## Review Focus

- Nama pelanggan atau menu sangat panjang di kartu pesanan dan kartu ringkasan Detail: harus terpotong rapi (ellipsis), bukan meluber. → tes di Task 2.
- Layar HP sempit (360 px) dan huruf sistem diperbesar 1,3x: kartu status tiga kolom di Dashboard tidak overflow. → tes di Task 3.
- Kiriman hari ini lebih dari 5 pesanan: tetap tampil 5 + keterangan "+N pesanan lain". → tes di Task 3.
- Detail pesanan Lunas: tombol Catat Pembayaran nonaktif bertuliskan "Sudah lunas"; tombol Lihat Nota dan Ubah tetap terlihat di bawah. → tes di Task 5.
- Judul kolom "Banyak" pada nota di lebar 375 px tidak terpotong. → tes di Task 6.

---

### Task 1: Token gaya, kotak ikon, logo

**Files:**
- Create: `assets/images/logo_mustika.png` (logo garis diwarnai #1F3A5F, latar transparan, ±400 px)
- Create: `lib/widgets/kotak_ikon.dart`, `lib/widgets/logo_usaha.dart`
- Modify: `pubspec.yaml` (aset `assets/images/`), `lib/utils/theme.dart`, `lib/widgets/status_badge.dart`, `lib/widgets/kartu_bagian.dart`
- Test: `test/widget_bersama_test.dart`

**Interfaces:**
- Produces: `AppTheme.sudutKartu = 12.0`; `AppTheme.garisKartu = Color(0xFFE5E7EB)`; `AppTheme.dekorasiKartu` (BoxDecoration putih, sudut 12, garis 1 px `garisKartu`, bayangan `0 1 2 rgba(16,24,40,.05)`); `KotakIkon({required IconData ikon, required Color warna, required Color latar, double ukuran = 36})`; `KotakIkon.status(StatusPembayaran s, {double ukuran = 36})`; `LogoUsaha({double ukuran = 44})` (logo di kotak putih bergaris); `KartuBagian` kepala memakai `KotakIkon` 30 px biru muda.
- Tema: CardTheme memakai garis `garisKartu`; OutlinedButton garis 1 px `#C9D2DF`; NavigationBar latar putih dengan garis atas; AppBar putih tetap.

- [ ] **Step 1: Tes** `KotakIkon.status(StatusPembayaran.lunas)` memakai `WarnaStatus.latar(lunas)` sebagai warna kotak dan `WarnaStatus.ikon(lunas)`; `LogoUsaha()` menampilkan `Image` dari `assets/images/logo_mustika.png`.
- [ ] **Step 2:** `flutter test test/widget_bersama_test.dart` → FAIL (berkas belum ada).
- [ ] **Step 3:** Buat aset, widget, dan token di atas.
- [ ] **Step 4:** `flutter test test/widget_bersama_test.dart` → PASS; `flutter analyze` → No issues.
- [ ] **Step 5:** Commit "Tambah token kartu putih, kotak ikon, dan logo".

### Task 2: Kartu pesanan

**Files:** Modify `lib/widgets/pesanan_card.dart`; Test `test/pesanan_card_test.dart`

**Interfaces:** Consumes `AppTheme.dekorasiKartu`, `StatusBadge`. Produces `PesananCard` dengan parameter sama.

- Tanpa garis status di kiri; baris bawah: kiri `<jenis atau Sisa Rp x> · Nota <tgl>`, kanan `StatusBadge`.
- [ ] **Step 1: Tes** nama 80 karakter dan menu panjang tidak overflow pada lebar 320; pesanan DP menampilkan `Sisa Rp 91.000`; pesanan Lunas menampilkan `Langganan harian` dan badge `Lunas`.
- [ ] **Step 2–4:** FAIL → ubah → PASS.
- [ ] **Step 5:** Commit "Kartu pesanan putih dengan badge di kanan bawah".

### Task 3: Dashboard

**Files:** Modify `lib/screens/dashboard_screen.dart`; Test `test/dashboard_test.dart`

**Interfaces:** Consumes `LogoUsaha`, `KotakIkon`, `PesananCard`. Key tetap: `ringkasan-dikirim-hari-ini`, `ringkasan-belumBayar|dp|lunas`, `ringkasan-bulan-ini`, `tombol-keluar`, `lihat-semua`, `tambah-dashboard`.

- Kepala: `LogoUsaha` + sapaan/tanggal + "Mustika Ayu Catering" biru + tombol keluar bergaris (ponsel).
- Kartu "Kiriman hari ini" putih: `KotakIkon` truk biru muda, angka biru 28, teks `Tidak ada kiriman hari ini` atau `<n> porsi disiapkan`; baris kiriman (maks 5 + "+N pesanan lain") di dalam kartu yang sama.
- Tiga kartu status: `KotakIkon.status`, angka 22 tebal, label.
- [ ] **Step 1: Tes** 360×740 dengan `textScaler` 1.3 tanpa overflow; 7 pesanan dikirim hari ini → 5 baris + teks `+2 pesanan lain di Daftar Pesanan`; tanpa kiriman → `Tidak ada kiriman hari ini`.
- [ ] **Step 2–4:** FAIL → ubah → PASS.
- [ ] **Step 5:** Commit "Dashboard kartu putih dengan logo dan kotak ikon".

### Task 4: Rekap Bulanan

**Files:** Modify `lib/screens/rekap_screen.dart`; Test `test/rekap_screen_test.dart`

**Interfaces:** Key tetap: `bulan-sebelumnya`, `bulan-rekap`, `bulan-berikutnya`, `total-pendapatan`, `sisa-rekap`, `rekap-<status>`.

- Pemilih bulan di kartu putih; kartu pendapatan putih (KotakIkon tren, angka biru 30, keterangan ongkir, garis, Belum diterima); daftar status dengan `KotakIkon.status` 32 + label + jumlah.
- [ ] **Step 1: Tes** pesanan BB-12 bulan Nov 2026 → `total-pendapatan` = `Rp 105.000`, `rekap-belumBayar` = `1 pesanan`; tombol bulan berikutnya → `Desember 2026` dan `Rp 0`.
- [ ] **Step 2–4:** FAIL → ubah → PASS.
- [ ] **Step 5:** Commit "Rekap kartu putih".

### Task 5: Detail Pesanan

**Files:** Modify `lib/screens/detail_pesanan_screen.dart`; Test `test/detail_pesanan_test.dart` (memakai `RepositoriMemori`)

**Interfaces:** Key tetap: `total-tagihan`, `sisa-tagihan`, `catat-pembayaran`, `lihat-nota`, `ubah-pesanan`, `hapus-pesanan`, `batal-hapus`, `konfirmasi-hapus`.

- AppBar putih standar. `_KepalaDetail` → kartu ringkasan putih (nama, badge kanan atas, jenis+tanggal nota, garis, Total tagihan biru 28, progres 8 px hijau bila lunas/biru selainnya, Dibayar/Sisa).
- Tanggal kirim sebagai pil biru muda. Tombol Ubah (garis) dan Lihat Nota (isi) di `bottomNavigationBar`; Hapus tetap di akhir isi.
- [ ] **Step 1: Tes** pesanan lunas → `catat-pembayaran` nonaktif bertuliskan `Sudah lunas`, `lihat-nota` dan `ubah-pesanan` terlihat tanpa menggulir; nama 80 karakter tanpa overflow.
- [ ] **Step 2–4:** FAIL → ubah → PASS.
- [ ] **Step 5:** Commit "Detail pesanan dengan kartu ringkasan dan tombol bawah".

### Task 6: Daftar, Form, Nota, Masuk, Sidebar

**Files:** Modify `lib/screens/daftar_pesanan_screen.dart`, `lib/screens/form_pesanan_screen.dart`, `lib/widgets/nota_kertas.dart`, `lib/screens/masuk_screen.dart`, `lib/widgets/sidebar_menu.dart`; Test tambah ke `test/nota_test.dart`

- Daftar dan Form mengikuti token (kartu, chip, tombol garis tipis); tanpa perubahan isi.
- Masuk: `LogoUsaha(ukuran: 72)` di atas judul.
- Sidebar: `LogoUsaha` + nama di kepala; menu aktif latar `primaryMuda`, teks/ikon `primary`.
- Nota: judul kolom tidak terbungkus (`softWrap: false`), kolom Banyak `FlexColumnWidth(1.3)`.
- [ ] **Step 1: Tes** NotaScreen pada 375×812: teks `Banyak` dirender satu baris (tinggi `Text` = tinggi satu baris).
- [ ] **Step 2–4:** FAIL → ubah → PASS; seluruh `flutter test` dan `flutter analyze` bersih.
- [ ] **Step 5:** Periksa visual di `localhost:8080` (ukuran HP dan layar lebar) setelah hot restart.
- [ ] **Step 6:** Commit "Samakan gaya Daftar, Form, Nota, Masuk, dan sidebar".
