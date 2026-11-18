# Aplikasi Pencatatan Pesanan dan Rekap Pendapatan Mustika Ayu Catering

Aplikasi Android untuk mencatat pesanan, membuat nota, mencatat pembayaran,
dan menyusun rekap pendapatan bulanan di Mustika Ayu Catering, Semarang.
Pesanan pelanggan tetap masuk lewat WhatsApp; pemilik, yang sekaligus admin
dan satu-satunya pengguna, memasukkan pesanan itu ke aplikasi.

Repositori ini adalah artefak skripsi berjudul:

> **Pengembangan Aplikasi Pencatatan Pesanan dan Rekap Pendapatan Berbasis
> Android pada Mustika Ayu Catering Menggunakan Metode Prototype**

Rancangan aplikasi mengikuti Bab III skripsi: kebutuhan fungsional KF-01
sampai KF-11, struktur data pada Tabel 3.7 dan 3.8, aturan perhitungan 3.2.4,
dan kasus uji Black Box BB-01 sampai BB-25.

## Identitas

| | |
|---|---|
| Nama | Putria Tri Ariibah |
| NIM | 23.01.55.0011 |
| Program studi | Sistem Informasi |
| Fakultas | Teknologi Informasi dan Industri |
| Universitas | Universitas Stikubank (Unisbank) Semarang |
| Dosen pembimbing | Arief Janto, S.Kom., M.Cs. |
| Tempat penelitian | Mustika Ayu Catering, Jl. Kendeng II No. 4, Bendan Ngisor, Semarang |

## Fitur

| Kode | Fitur |
|---|---|
| KF-01 | Masuk dengan email dan kata sandi (Firebase Authentication). Tidak ada halaman Daftar; akun pemilik dibuat lewat Firebase Console. |
| KF-02 | Menambah, mengubah, dan mencari pelanggan. |
| KF-03 | Mencatat pesanan sekaligus maupun langganan harian: tanggal nota, jenis pesanan, dan rincian menu (tanggal kirim, nama menu, jumlah porsi, harga per porsi). |
| KF-04 | Mencatat ongkos kirim (jumlah kirim dan tarif), terpisah dari rincian menu. |
| KF-05 | Subtotal, total menu, total ongkos kirim, dan total tagihan dihitung otomatis. |
| KF-06 | Mengubah pesanan dengan riwayat perubahan; menghapus pesanan setelah konfirmasi. |
| KF-07 | Mencatat pembayaran; status Belum bayar, DP, atau Lunas dan sisa tagihan ditentukan aplikasi. |
| KF-08 | Nota disusun dari data pesanan, disimpan sebagai gambar PNG ke Galeri, dan dibagikan lewat menu berbagi ponsel. |
| KF-09 | Mencari pesanan menurut nama pelanggan atau menu; saringan dikirim hari ini dan status pembayaran. |
| KF-10 | Rekap bulanan: jumlah pesanan, total pendapatan, jumlah pesanan per status, dan sisa tagihan. |
| KF-11 | Dashboard: kiriman hari ini, pesanan per status bulan berjalan, dan pesanan terbaru. |

### Aturan perhitungan (Bab III, 3.2.4)

- Subtotal menu = jumlah porsi × harga per porsi; total menu = jumlah subtotal.
- Total tagihan = total menu + total ongkos kirim.
- Status pembayaran: belum ada pembayaran = Belum bayar; dibayar kurang dari
  tagihan = DP; dibayar sama dengan tagihan = Lunas.
- Pendapatan bulanan = jumlah total menu pesanan yang tanggal notanya jatuh
  pada bulan itu. Ongkos kirim dicatat di nota, tetapi tidak dihitung sebagai
  pendapatan.

## Teknologi

- Flutter 3.47.7 dan Dart 3.13.5
- Firebase: `firebase_core` 5.1.0, `firebase_auth` 7.0.1, `cloud_firestore` 7.1.0
  (project `mustika-ayu-catering`, Firestore region asia-southeast2)
- `gal` (simpan nota ke Galeri) dan `share_plus` (menu berbagi)
- Font Inter (aset lokal, lisensi SIL OFL); warna utama biru `#1F3A5F`
- applicationId Android: `com.mustikaayu.catering`

## Struktur data Cloud Firestore

| Collection | Isi |
|---|---|
| `pelanggan` | Satu dokumen per pelanggan, berisi field `nama`. |
| `pesanan` | Satu dokumen per pesanan: rujukan dan salinan nama pelanggan, tanggal nota, jenis pesanan, array `rincian`, `ongkosKirim`, dan `pembayaran`, serta total dan status yang dihitung dari isinya. |
| `pesanan/{id}/riwayat` | Riwayat perubahan pesanan: waktu, bagian, nilai lama, dan nilai baru. |

Rekap bulanan tidak disimpan sebagai collection; aplikasi menghitungnya dari
dokumen pesanan menurut tanggal nota. Security Rules hanya mengizinkan akses
bagi pengguna yang sudah masuk.

## Struktur folder

```
lib/
  data/      Repositori (antarmuka), RepositoriFirestore, RepositoriMemori
             (untuk pengujian), berkas nota (simpan dan bagikan)
  models/    Pelanggan, Pesanan, RincianMenu, OngkosKirim, Pembayaran,
             RiwayatPerubahan, Nota, dan AturanPesanan (validasi dan rekap)
  screens/   Masuk, Dashboard, Daftar Pesanan, Form Pesanan, Pilih Pelanggan,
             Detail Pesanan, Nota, Rekap Bulanan
  widgets/   Komponen tampilan bersama (kartu, badge status, kotak ikon, logo)
  utils/     Tema, format Rupiah dan tanggal, validasi masuk
test/        Uji unit dan uji widget
docs/        Catatan desain dan rencana pengembangan
```

## Menjalankan aplikasi

```bash
flutter pub get
flutter run                                   # ponsel Android yang terhubung
flutter run -d chrome                         # pratinjau di browser
flutter run -d web-server --web-port 8080     # pratinjau di http://localhost:8080
```

Aplikasi memakai konfigurasi Firebase di `lib/firebase_options.dart`. Masuk
dengan akun yang sudah dibuat di Firebase Console (Authentication,
Email/Password).

## Pengujian

```bash
flutter analyze
flutter test
```

Uji otomatis berjalan tanpa Firebase karena memakai `RepositoriMemori`.
Kasus uji Black Box dari Bab III yang sudah diuji otomatis:

| File uji | Kasus uji |
|---|---|
| `test/masuk_screen_test.dart` | BB-01, BB-02, BB-03 |
| `test/form_pesanan_test.dart` | BB-07, BB-11, BB-12 (melalui form) |
| `test/aturan_pesanan_test.dart` | BB-06 sampai BB-13, BB-15 sampai BB-18, BB-22 sampai BB-24 |
| `test/nota_test.dart` | BB-19, BB-20 |

Kasus BB-04, BB-05, BB-14, BB-21, dan BB-25, beserta User Acceptance Testing
oleh pemilik, diuji langsung pada aplikasi dan hasilnya dilaporkan di Bab V
skripsi. File uji lainnya memeriksa tampilan, misalnya teks panjang dan
layar ponsel sempit tidak meluber.
