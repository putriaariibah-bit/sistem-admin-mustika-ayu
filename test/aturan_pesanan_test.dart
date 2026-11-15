import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/models/aturan_pesanan.dart';
import 'package:kelola_katering/models/ongkos_kirim.dart';
import 'package:kelola_katering/models/pembayaran.dart';
import 'package:kelola_katering/models/pesanan.dart';
import 'package:kelola_katering/models/rincian_menu.dart';

RincianMenu _menu(int no, String nama, int porsi, int harga,
        {DateTime? kirim}) =>
    RincianMenu(
      noUrut: no,
      tanggalKirim: kirim ?? DateTime(2026, 11, 9),
      namaMenu: nama,
      jumlahPorsi: porsi,
      hargaPerPorsi: harga,
    );

Pesanan _pesanan({
  List<RincianMenu> rincian = const [],
  List<OngkosKirim> ongkir = const [],
  List<Pembayaran> bayar = const [],
  DateTime? nota,
}) =>
    Pesanan(
      pelangganId: 'p1',
      namaPelanggan: 'Pelanggan A',
      tanggalNota: nota ?? DateTime(2026, 11, 3),
      jenisPesanan: JenisPesanan.langgananHarian,
      rincian: rincian,
      ongkosKirim: ongkir,
      pembayaran: bayar,
    );

/// Pesanan BB-11 dan BB-12: total menu Rp105.000, ongkir 4 x Rp9.000.
final _pesananBB12 = _pesanan(
  rincian: [_menu(1, 'Rica ayam', 2, 40000), _menu(2, 'Sayur asem', 1, 25000)],
  ongkir: [const OngkosKirim(noUrut: 1, jumlahKirim: 4, tarif: 9000)],
);

Pembayaran _bayar(int nominal) =>
    Pembayaran(noUrut: 1, tanggalBayar: DateTime(2026, 11, 4), nominal: nominal);

void main() {
  group('Validasi isian', () {
    test('BB-06: pesanan tanpa rincian ditolak', () {
      expect(AturanPesanan.validasiRincian(_pesanan()),
          'Rincian menu wajib diisi');
      expect(AturanPesanan.validasiRincian(_pesananBB12), isNull);
    });
    test('BB-07: jumlah porsi kosong ditolak', () {
      expect(AturanPesanan.validasiPorsi(''), isNotNull);
    });
    test('BB-08: jumlah porsi 0 ditolak', () {
      expect(AturanPesanan.validasiPorsi('0'), 'Jumlah porsi minimal 1');
    });
    test('BB-09: jumlah porsi 1 diterima', () {
      expect(AturanPesanan.validasiPorsi('1'), isNull);
    });
    test('BB-10: harga per porsi kosong atau 0 ditolak', () {
      expect(AturanPesanan.validasiHarga(''), isNotNull);
      expect(AturanPesanan.validasiHarga('0'), isNotNull);
      expect(AturanPesanan.validasiHarga('40.000'), isNull);
    });
  });

  group('Perhitungan total', () {
    test('BB-11: 2 x Rp40.000 dan 1 x Rp25.000 = Rp105.000', () {
      expect(_pesananBB12.totalMenu, 105000);
    });
    test('BB-12: ongkir 4 x Rp9.000 = Rp36.000, tagihan Rp141.000', () {
      expect(_pesananBB12.totalOngkir, 36000);
      expect(_pesananBB12.totalTagihan, 141000);
    });
  });

  group('Status pembayaran', () {
    test('BB-15: tanpa pembayaran = Belum bayar, sisa = tagihan', () {
      expect(_pesananBB12.statusPembayaran, StatusPembayaran.belumBayar);
      expect(_pesananBB12.sisaTagihan, 141000);
    });
    test('BB-16: kurang Rp1 dari tagihan = DP, sisa Rp1', () {
      final p = _pesananBB12.copyWith(pembayaran: [_bayar(140999)]);
      expect(p.statusPembayaran, StatusPembayaran.dp);
      expect(p.sisaTagihan, 1);
    });
    test('BB-17: sama dengan tagihan = Lunas, sisa Rp0', () {
      final p = _pesananBB12.copyWith(pembayaran: [_bayar(141000)]);
      expect(p.statusPembayaran, StatusPembayaran.lunas);
      expect(p.sisaTagihan, 0);
    });
    test('BB-18: pembayaran melebihi sisa tagihan ditolak', () {
      expect(AturanPesanan.validasiNominal('141001', 141000),
          'Nominal melebihi sisa tagihan');
      expect(AturanPesanan.validasiNominal('141000', 141000), isNull);
    });
  });

  test('BB-13: ubah porsi 1 menjadi 2 tercatat di riwayat', () {
    final lama = _pesanan(rincian: [_menu(1, 'Beef semur', 1, 25000)]);
    final baru = lama.copyWith(rincian: [_menu(1, 'Beef semur', 2, 25000)]);
    final riwayat = AturanPesanan.bandingkan(lama, baru, DateTime(2026, 11, 4));

    expect(baru.totalMenu, 50000);
    expect(riwayat, hasLength(1));
    expect(riwayat.first.bagian, 'Porsi Beef semur');
    expect(riwayat.first.nilaiLama, '1');
    expect(riwayat.first.nilaiBaru, '2');
  });

  test('BB-22: saringan dikirim hari ini', () {
    final hariIni = DateTime(2026, 11, 13);
    final kirimHariIni =
        _pesanan(rincian: [_menu(1, 'Rica ayam', 1, 20000, kirim: hariIni)]);
    final kirimBesok = _pesanan(rincian: [
      _menu(1, 'Rica ayam', 1, 20000, kirim: DateTime(2026, 11, 14)),
    ]);

    expect(kirimHariIni.dikirimPada(hariIni), isTrue);
    expect(kirimBesok.dikirimPada(hariIni), isFalse);
    expect(AturanPesanan.jumlahDikirim([kirimHariIni, kirimBesok], hariIni), 1);
  });

  group('Rekap bulanan', () {
    test('BB-23: hanya nota 31 Oktober yang masuk rekap Oktober', () {
      final oktober = _pesanan(
          nota: DateTime(2026, 10, 31),
          rincian: [_menu(1, 'Rica ayam', 1, 20000)]);
      final november = _pesanan(
          nota: DateTime(2026, 11, 1),
          rincian: [_menu(1, 'Rica ayam', 1, 30000)]);

      final rekap = AturanPesanan.rekap([oktober, november], 2026, 10);
      expect(rekap.jumlahPesanan, 1);
      expect(rekap.totalPendapatan, 20000);
    });
    test('BB-24: pendapatan = total menu, tanpa ongkos kirim', () {
      final rekap = AturanPesanan.rekap([_pesananBB12], 2026, 11);
      expect(rekap.totalPendapatan, 105000);
      expect(rekap.sisaTagihan, 141000);
      expect(rekap.jumlahPerStatus[StatusPembayaran.belumBayar], 1);
    });
  });

  test('toMap dan fromMap menyimpan field sesuai Tabel 3.8', () {
    final map = _pesananBB12.toMap();
    expect(map['totalMenu'], 105000);
    expect(map['totalTagihan'], 141000);
    expect(map['statusPembayaran'], 'Belum bayar');
    expect(map['jenisPesanan'], 'Langganan harian');
    expect(map['daftarTanggalKirim'], ['2026-11-09']);

    final dibaca = Pesanan.fromMap('abc', map);
    expect(dibaca.id, 'abc');
    expect(dibaca.totalTagihan, 141000);
    expect(dibaca.rincian.first.namaMenu, 'Rica ayam');
  });
}
