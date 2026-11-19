import '../utils/format.dart';
import 'konversi.dart';
import 'pesanan.dart';
import 'rincian_menu.dart';

/// Satu baris tabel nota: kolom Banyak, Nama, Harga, dan Jumlah,
/// sama dengan tabel pada nota kertas (Gambar 3.8(f)).
class BarisNota {
  final String banyak;
  final String nama;
  final int harga;
  final int jumlah;

  const BarisNota({
    required this.banyak,
    required this.nama,
    required this.harga,
    required this.jumlah,
  });
}

/// Baris menu yang dikirim pada tanggal yang sama.
class KelompokNota {
  final DateTime tanggalKirim;
  final List<BarisNota> baris;

  const KelompokNota({required this.tanggalKirim, required this.baris});
}

/// Isi nota yang disusun dari data pesanan (proses 5.0, KF-08).
///
/// Nota tidak disimpan di Firestore. Setiap kali dibuka, isinya disusun
/// ulang dari dokumen pesanan, sehingga rincian, ongkos kirim, dan total
/// selalu sama dengan data pesanan (BB-19).
class Nota {
  /// Identitas usaha, disalin dari kepala nota kertas Mustika Ayu Catering.
  static const String namaUsaha = 'Mustika Ayu Catering';
  static const String alamatUsaha = 'Jl. Kendeng II No. 4 Semarang';
  static const String whatsappUsaha = '08112921703';

  final DateTime tanggalNota;
  final String namaPelanggan;

  /// Jenis pesanan, mis. "Sekaligus" atau "Langganan harian".
  final String jenis;
  final List<KelompokNota> menu;
  final List<BarisNota> ongkosKirim;

  /// Total tagihan, ditulis pada baris "Jumlah Rp." seperti nota kertas.
  final int jumlahRp;
  final int sudahDibayar;
  final int sisa;
  final StatusPembayaran status;

  const Nota({
    required this.tanggalNota,
    required this.namaPelanggan,
    required this.jenis,
    required this.menu,
    required this.ongkosKirim,
    required this.jumlahRp,
    required this.sudahDibayar,
    required this.sisa,
    required this.status,
  });

  factory Nota.dariPesanan(Pesanan p) {
    final urut = [...p.rincian]..sort((a, b) {
        final t = a.tanggalKirim.compareTo(b.tanggalKirim);
        return t != 0 ? t : a.noUrut.compareTo(b.noUrut);
      });

    final kelompok = <String, List<RincianMenu>>{};
    for (final r in urut) {
      kelompok
          .putIfAbsent(Konversi.kunciTanggal(r.tanggalKirim), () => [])
          .add(r);
    }

    return Nota(
      tanggalNota: p.tanggalNota,
      namaPelanggan: p.namaPelanggan,
      jenis: p.jenisPesanan.label,
      menu: [
        for (final daftar in kelompok.values)
          KelompokNota(
            tanggalKirim: daftar.first.tanggalKirim,
            baris: [
              for (final r in daftar)
                BarisNota(
                  banyak: '${r.jumlahPorsi} pcs',
                  nama: r.namaMenu,
                  harga: r.hargaPerPorsi,
                  jumlah: r.subtotal,
                ),
            ],
          ),
      ],
      ongkosKirim: [
        for (final o in p.ongkosKirim)
          BarisNota(
            banyak: '${o.jumlahKirim}x',
            nama: o.keterangan.trim().isEmpty
                ? 'Ongkos kirim'
                : 'Ongkos kirim (${o.keterangan.trim()})',
            harga: o.tarif,
            jumlah: o.subtotal,
          ),
      ],
      jumlahRp: p.totalTagihan,
      sudahDibayar: p.totalDibayar,
      sisa: p.sisaTagihan,
      status: p.statusPembayaran,
    );
  }

  /// Tanggal kirim ditulis sebagai subjudul bila menu dikirim lebih dari
  /// satu hari, atau dikirim pada hari lain dari tanggal nota.
  bool get tampilkanTanggalKirim =>
      menu.length > 1 ||
      (menu.length == 1 &&
          Konversi.kunciTanggal(menu.first.tanggalKirim) !=
              Konversi.kunciTanggal(tanggalNota));

  /// Tanggal kirim untuk kotak informasi pesanan: satu tanggal, mis.
  /// `03/11/2026`, atau rentang tanggal pertama sampai terakhir, mis.
  /// `09/11 – 10/11/2026`.
  String get teksTanggalKirim {
    if (menu.isEmpty) return Format.tanggalAngka(tanggalNota);
    final awal = menu.first.tanggalKirim;
    final akhir = menu.last.tanggalKirim;
    if (menu.length == 1) return Format.tanggalAngka(awal);
    String dua(int n) => n.toString().padLeft(2, '0');
    final teksAwal = awal.year == akhir.year
        ? '${dua(awal.day)}/${dua(awal.month)}'
        : Format.tanggalAngka(awal);
    return '$teksAwal – ${Format.tanggalAngka(akhir)}';
  }

  /// Jumlah kolom Jumlah pada seluruh baris menu (sama dengan total menu).
  int get totalMenu => menu.fold(
        0,
        (total, k) => total + k.baris.fold(0, (s, b) => s + b.jumlah),
      );

  /// Jumlah kolom Jumlah pada baris ongkos kirim.
  int get totalOngkir => ongkosKirim.fold(0, (s, b) => s + b.jumlah);

  /// Nama berkas gambar, mis. `Nota_Mama_Mosa_2025-12-12.png`.
  String get namaBerkas {
    final nama = namaPelanggan
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final bagianNama = nama.isEmpty ? '' : '_$nama';
    return 'Nota${bagianNama}_${Konversi.kunciTanggal(tanggalNota)}.png';
  }
}
