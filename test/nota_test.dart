import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelola_katering/data/berkas_nota.dart';
import 'package:kelola_katering/models/nota.dart';
import 'package:kelola_katering/models/ongkos_kirim.dart';
import 'package:kelola_katering/models/pembayaran.dart';
import 'package:kelola_katering/models/pesanan.dart';
import 'package:kelola_katering/models/rincian_menu.dart';
import 'package:kelola_katering/screens/nota_screen.dart';
import 'package:kelola_katering/utils/theme.dart';

/// Pesanan BB-12: 2 x Rp40.000 + 1 x Rp25.000, ongkir 4 x Rp9.000.
final _pesananBB12 = Pesanan(
  id: 'bb12',
  pelangganId: 'p1',
  namaPelanggan: 'Pelanggan A',
  tanggalNota: DateTime(2026, 11, 3),
  jenisPesanan: JenisPesanan.sekaligus,
  rincian: [
    RincianMenu(
      noUrut: 1,
      tanggalKirim: DateTime(2026, 11, 3),
      namaMenu: 'Rica ayam',
      jumlahPorsi: 2,
      hargaPerPorsi: 40000,
    ),
    RincianMenu(
      noUrut: 2,
      tanggalKirim: DateTime(2026, 11, 3),
      namaMenu: 'Sayur asem',
      jumlahPorsi: 1,
      hargaPerPorsi: 25000,
    ),
  ],
  ongkosKirim: const [OngkosKirim(noUrut: 1, jumlahKirim: 4, tarif: 9000)],
  pembayaran: [
    Pembayaran(noUrut: 1, tanggalBayar: DateTime(2026, 11, 3), nominal: 50000),
  ],
);

/// Tiruan [BerkasNota] agar uji tidak menyentuh galeri dan menu berbagi.
class _BerkasTiruan implements BerkasNota {
  final disimpan = <String>[];
  final dibagikan = <String>[];
  int ukuranTerakhir = 0;

  @override
  Future<void> simpan(List<int> png, String namaBerkas) async {
    ukuranTerakhir = png.length;
    disimpan.add(namaBerkas);
  }

  @override
  Future<void> bagikan(List<int> png, String namaBerkas) async {
    ukuranTerakhir = png.length;
    dibagikan.add(namaBerkas);
  }
}

/// Menekan tombol yang memicu pembuatan gambar. Pembuatan gambar butuh
/// waktu nyata, jadi ditunggu di dalam runAsync sampai [selesai].
Future<void> _tekanDanTunggu(
  WidgetTester tester,
  Key kunci,
  bool Function() selesai,
) async {
  await tester.runAsync(() async {
    await tester.tap(find.byKey(kunci));
    for (var i = 0; i < 100 && !selesai(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
  await tester.pump();
}

void main() {
  test('BB-19: rincian, ongkos kirim, dan total nota sama dengan pesanan', () {
    final nota = Nota.dariPesanan(_pesananBB12);

    final menu = nota.menu.expand((k) => k.baris).toList();
    expect(menu.map((b) => b.nama), ['Rica ayam', 'Sayur asem']);
    expect(menu.map((b) => b.banyak), ['2 pcs', '1 pcs']);
    expect(menu.map((b) => b.harga), [40000, 25000]);
    expect(menu.map((b) => b.jumlah), [80000, 25000]);

    expect(nota.ongkosKirim.single.banyak, '4x');
    expect(nota.ongkosKirim.single.jumlah, 36000);

    expect(nota.totalMenu, _pesananBB12.totalMenu);
    expect(nota.totalOngkir, _pesananBB12.totalOngkir);
    expect(nota.jumlahRp, 141000);
    expect(nota.sudahDibayar, 50000);
    expect(nota.sisa, 91000);
    expect(nota.status, StatusPembayaran.dp);
    expect(nota.tampilkanTanggalKirim, isFalse);
    expect(nota.namaBerkas, 'Nota_Pelanggan_A_2026-11-03.png');
    expect(nota.jenis, 'Sekaligus');
    expect(nota.teksTanggalKirim, '03/11/2026');
  });

  test('Nota langganan memakai subjudul tanggal kirim, urut per tanggal', () {
    final langganan = _pesananBB12.copyWith(
      jenisPesanan: JenisPesanan.langgananHarian,
      rincian: [
        RincianMenu(
          noUrut: 1,
          tanggalKirim: DateTime(2026, 11, 5),
          namaMenu: 'Sop sayur',
          jumlahPorsi: 3,
          hargaPerPorsi: 15000,
        ),
        RincianMenu(
          noUrut: 2,
          tanggalKirim: DateTime(2026, 11, 4),
          namaMenu: 'Ayam bakar',
          jumlahPorsi: 3,
          hargaPerPorsi: 20000,
        ),
      ],
    );
    final nota = Nota.dariPesanan(langganan);
    expect(nota.tampilkanTanggalKirim, isTrue);
    expect(nota.menu.map((k) => k.tanggalKirim.day), [4, 5]);
    expect(nota.totalMenu, langganan.totalMenu);
    expect(nota.jenis, 'Langganan harian');
    expect(nota.teksTanggalKirim, '04/11 – 05/11/2026');
  });

  testWidgets('BB-19: layar nota menampilkan isi pesanan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: NotaScreen(pesanan: _pesananBB12)),
    );

    expect(find.text('Rica ayam'), findsOneWidget);
    expect(find.text('Sayur asem'), findsOneWidget);
    expect(find.text('Ongkos kirim'), findsOneWidget);
    expect(find.text('36.000'), findsOneWidget);
    expect(find.text('NOTA'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('nota-tanggal'))).data,
      '03/11/2026',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('nota-nama'))).data,
      'Pelanggan A',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('nota-jenis'))).data,
      'Sekaligus',
    );
    expect(
      find.text('Terima kasih atas pesanan Anda di Mustika Ayu Catering.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('nota-jumlah'))).data,
      '141.000',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('nota-sisa'))).data,
      '91.000',
    );
    // Sisa yang belum lunas ditulis merah.
    expect(
      tester.widget<Text>(find.byKey(const Key('nota-sisa'))).style?.color,
      AppTheme.bayarBelum,
    );
  });

  testWidgets('Nota lunas menulis sisa 0 dengan warna hijau', (tester) async {
    final lunas = _pesananBB12.copyWith(
      pembayaran: [
        Pembayaran(
          noUrut: 1,
          tanggalBayar: DateTime(2026, 11, 3),
          nominal: 141000,
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(home: NotaScreen(pesanan: lunas)));

    final sisa = tester.widget<Text>(find.byKey(const Key('nota-sisa')));
    expect(sisa.data, '0');
    expect(sisa.style?.color, AppTheme.bayarLunas);
  });

  testWidgets('BB-20: Simpan lalu Bagikan memakai berkas gambar nota', (
    tester,
  ) async {
    final tiruan = _BerkasTiruan();
    BerkasNota.instance = tiruan;
    addTearDown(() => BerkasNota.instance = BerkasNotaPerangkat());

    await tester.pumpWidget(
      MaterialApp(home: NotaScreen(pesanan: _pesananBB12)),
    );

    await _tekanDanTunggu(
      tester,
      const Key('simpan-nota'),
      () => tiruan.disimpan.isNotEmpty,
    );
    expect(tiruan.disimpan, ['Nota_Pelanggan_A_2026-11-03.png']);
    expect(tiruan.ukuranTerakhir, greaterThan(0));
    expect(find.textContaining('Nota tersimpan'), findsOneWidget);

    await _tekanDanTunggu(
      tester,
      const Key('bagikan-nota'),
      () => tiruan.dibagikan.isNotEmpty,
    );
    expect(tiruan.dibagikan, ['Nota_Pelanggan_A_2026-11-03.png']);
  });
}
