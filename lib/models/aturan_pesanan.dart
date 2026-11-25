import 'konversi.dart';
import 'pesanan.dart';
import 'riwayat_perubahan.dart';

/// Aturan validasi, riwayat perubahan, dan rekap pesanan.
///
/// Semua aturan ditulis di satu tempat agar formulir, pengujian
/// Black Box (Tabel 3.10), dan rekap memakai dasar yang sama
/// (aturan 3.2.4).
class AturanPesanan {
  AturanPesanan._();

  // ── Validasi isian (BB-06 sampai BB-10, BB-18) ───────────────

  /// BB-06: pesanan wajib memiliki minimal satu rincian menu.
  static String? validasiRincian(Pesanan pesanan) =>
      pesanan.rincian.isEmpty ? 'Rincian menu wajib diisi' : null;

  /// Nama menu wajib diisi.
  static String? validasiNamaMenu(String? nilai) =>
      (nilai == null || nilai.trim().isEmpty) ? 'Nama menu wajib diisi' : null;

  /// BB-07 sampai BB-09: jumlah porsi wajib diisi dan minimal 1.
  static String? validasiPorsi(String? nilai) {
    final teks = nilai?.trim() ?? '';
    if (teks.isEmpty) return 'Jumlah porsi wajib diisi';
    final porsi = int.tryParse(teks);
    if (porsi == null) return 'Jumlah porsi harus berupa angka';
    if (porsi < 1) return 'Jumlah porsi minimal 1';
    return null;
  }

  /// BB-10: harga per porsi wajib diisi dan lebih dari 0.
  static String? validasiHarga(String? nilai) =>
      _validasiRupiah(nilai, 'Harga per porsi');

  /// Tarif ongkos kirim wajib diisi dan lebih dari 0.
  static String? validasiTarif(String? nilai) =>
      _validasiRupiah(nilai, 'Tarif');

  /// Jumlah kirim wajib diisi dan minimal 1.
  static String? validasiJumlahKirim(String? nilai) {
    final teks = nilai?.trim() ?? '';
    if (teks.isEmpty) return 'Jumlah kirim wajib diisi';
    final jumlah = int.tryParse(teks);
    if (jumlah == null) return 'Jumlah kirim harus berupa angka';
    if (jumlah < 1) return 'Jumlah kirim minimal 1';
    return null;
  }

  /// BB-18: nominal pembayaran lebih dari 0 dan tidak melebihi sisa tagihan.
  static String? validasiNominal(String? nilai, int sisaTagihan) {
    final pesan = _validasiRupiah(nilai, 'Nominal');
    if (pesan != null) return pesan;
    final nominal = bacaRupiah(nilai)!;
    if (nominal > sisaTagihan) return 'Nominal melebihi sisa tagihan';
    return null;
  }

  /// Membaca angka Rupiah dari teks; titik, koma, spasi, dan "Rp" diabaikan.
  static int? bacaRupiah(String? nilai) {
    final angka = (nilai ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return angka.isEmpty ? null : int.tryParse(angka);
  }

  static String? _validasiRupiah(String? nilai, String nama) {
    final angka = bacaRupiah(nilai);
    if (angka == null) return '$nama wajib diisi';
    if (angka <= 0) return '$nama harus lebih dari 0';
    return null;
  }

  // ── Riwayat perubahan (KF-06, BB-13) ─────────────────────────

  /// Membandingkan pesanan sebelum dan sesudah diubah, lalu menghasilkan
  /// satu catatan riwayat untuk setiap bagian yang berubah.
  ///
  /// Contoh BB-13: porsi Beef semur 1 menjadi 2 menghasilkan
  /// bagian "Porsi Beef semur", nilaiLama "1", nilaiBaru "2".
  static List<RiwayatPerubahan> bandingkan(
    Pesanan lama,
    Pesanan baru,
    DateTime waktu,
  ) {
    final hasil = <RiwayatPerubahan>[];
    void catat(String bagian, Object? nilaiLama, Object? nilaiBaru) {
      final a = '${nilaiLama ?? ''}';
      final b = '${nilaiBaru ?? ''}';
      if (a != b) {
        hasil.add(
          RiwayatPerubahan(
            waktu: waktu,
            bagian: bagian,
            nilaiLama: a,
            nilaiBaru: b,
          ),
        );
      }
    }

    catat('Nama pelanggan', lama.namaPelanggan, baru.namaPelanggan);
    catat(
      'Tanggal nota',
      Konversi.kunciTanggal(lama.tanggalNota),
      Konversi.kunciTanggal(baru.tanggalNota),
    );
    catat('Jenis pesanan', lama.jenisPesanan.label, baru.jenisPesanan.label);

    final rincianLama = {for (final r in lama.rincian) r.noUrut: r};
    final rincianBaru = {for (final r in baru.rincian) r.noUrut: r};
    for (final no in {...rincianLama.keys, ...rincianBaru.keys}) {
      final a = rincianLama[no];
      final b = rincianBaru[no];
      if (a == null && b != null) {
        catat('Tambah menu', '', '${b.namaMenu} ${b.jumlahPorsi} porsi');
      } else if (a != null && b == null) {
        catat('Hapus menu', '${a.namaMenu} ${a.jumlahPorsi} porsi', '');
      } else if (a != null && b != null) {
        final menu = b.namaMenu;
        catat('Nama menu baris $no', a.namaMenu, b.namaMenu);
        catat(
          'Tanggal kirim $menu',
          Konversi.kunciTanggal(a.tanggalKirim),
          Konversi.kunciTanggal(b.tanggalKirim),
        );
        catat('Porsi $menu', a.jumlahPorsi, b.jumlahPorsi);
        catat('Harga per porsi $menu', a.hargaPerPorsi, b.hargaPerPorsi);
      }
    }

    catat('Total ongkos kirim', lama.totalOngkir, baru.totalOngkir);
    catat('Total dibayar', lama.totalDibayar, baru.totalDibayar);
    return hasil;
  }

  // ── Rekap bulanan dan ringkasan (KF-10, KF-11) ───────────────

  /// Rekap pesanan yang tanggal notanya jatuh pada [tahun]-[bulan]
  /// (aturan 3.2.4 nomor 4 sampai 6).
  static RekapBulanan rekap(List<Pesanan> semua, int tahun, int bulan) {
    final pesananBulanIni = [
      for (final p in semua)
        if (p.tanggalNota.year == tahun && p.tanggalNota.month == bulan) p,
    ];
    final perStatus = {for (final s in StatusPembayaran.values) s: 0};
    var pendapatan = 0;
    var sisa = 0;
    for (final p in pesananBulanIni) {
      pendapatan += p.totalMenu; // ongkos kirim tidak dihitung
      sisa += p.sisaTagihan;
      perStatus[p.statusPembayaran] = perStatus[p.statusPembayaran]! + 1;
    }
    return RekapBulanan(
      tahun: tahun,
      bulan: bulan,
      jumlahPesanan: pesananBulanIni.length,
      totalPendapatan: pendapatan,
      jumlahPerStatus: perStatus,
      sisaTagihan: sisa,
    );
  }

  /// Jumlah pesanan yang memiliki rincian dikirim pada [hariIni] (KF-11).
  static int jumlahDikirim(List<Pesanan> semua, DateTime hariIni) =>
      semua.where((p) => p.dikirimPada(hariIni)).length;
}

/// Hasil rekap satu bulan (KF-10). Tidak disimpan sebagai koleksi;
/// dihitung dari dokumen pesanan setiap kali dibuka.
class RekapBulanan {
  final int tahun;
  final int bulan;
  final int jumlahPesanan;
  final int totalPendapatan;
  final Map<StatusPembayaran, int> jumlahPerStatus;
  final int sisaTagihan;

  const RekapBulanan({
    required this.tahun,
    required this.bulan,
    required this.jumlahPesanan,
    required this.totalPendapatan,
    required this.jumlahPerStatus,
    required this.sisaTagihan,
  });
}
