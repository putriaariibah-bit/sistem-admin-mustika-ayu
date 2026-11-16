import 'package:kelola_katering/models/ongkos_kirim.dart';
import 'package:kelola_katering/models/pembayaran.dart';
import 'package:kelola_katering/models/pesanan.dart';
import 'package:kelola_katering/models/rincian_menu.dart';

/// Pesanan uji: 2 x Rp40.000 + 1 x Rp25.000, ongkir 4 x Rp9.000
/// (tagihan Rp141.000), dengan tanggal nota dan tanggal kirim [tanggal].
Pesanan pesananUji({
  String nama = 'Pelanggan A',
  DateTime? tanggal,
  int dibayar = 0,
  JenisPesanan jenis = JenisPesanan.sekaligus,
}) {
  final t = tanggal ?? DateTime(2026, 11, 3);
  return Pesanan(
    pelangganId: 'p1',
    namaPelanggan: nama,
    tanggalNota: t,
    jenisPesanan: jenis,
    rincian: [
      RincianMenu(
        noUrut: 1,
        tanggalKirim: t,
        namaMenu: 'Rica ayam',
        jumlahPorsi: 2,
        hargaPerPorsi: 40000,
      ),
      RincianMenu(
        noUrut: 2,
        tanggalKirim: t,
        namaMenu: 'Sayur asem',
        jumlahPorsi: 1,
        hargaPerPorsi: 25000,
      ),
    ],
    ongkosKirim: const [OngkosKirim(noUrut: 1, jumlahKirim: 4, tarif: 9000)],
    pembayaran: [
      if (dibayar > 0)
        Pembayaran(noUrut: 1, tanggalBayar: t, nominal: dibayar),
    ],
  );
}
