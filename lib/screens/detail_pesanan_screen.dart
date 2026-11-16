import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../models/aturan_pesanan.dart';
import '../models/konversi.dart';
import '../models/pembayaran.dart';
import '../models/pesanan.dart';
import '../models/riwayat_perubahan.dart';
import '../models/rincian_menu.dart';
import '../utils/format.dart';
import '../utils/rupiah_input.dart';
import '../utils/theme.dart';
import '../widgets/kartu_bagian.dart';
import '../widgets/status_badge.dart';
import 'form_pesanan_screen.dart';
import 'nota_screen.dart';

/// Hasil yang dikirim Detail Pesanan ke pemanggil lewat [Navigator.pop].
enum HasilDetail { dihapus }

/// Halaman Detail Pesanan (Gambar 3.7(e)).
///
/// Memuat data pesanan, rincian menu, ongkos kirim, total, status dan
/// daftar pembayaran (KF-07), riwayat perubahan (KF-06), serta tombol
/// Lihat Nota (KF-08), Ubah Pesanan, dan Hapus Pesanan dengan
/// konfirmasi (BB-14).
/// Data selalu diambil terbaru dari Firestore.
class DetailPesananScreen extends StatelessWidget {
  final Pesanan pesanan;

  const DetailPesananScreen({super.key, required this.pesanan});

  void _bukaNota(BuildContext context, Pesanan p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotaScreen(pesanan: p)),
    );
  }

  Future<void> _bukaUbah(BuildContext context, Pesanan p) async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormPesananScreen(pesananAwal: p),
      ),
    );
    if (berhasil != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Perubahan pesanan disimpan.')),
      );
  }

  Future<void> _catatPembayaran(BuildContext context, Pesanan p) async {
    final bayar = await showDialog<Pembayaran>(
      context: context,
      builder: (context) => _DialogPembayaran(pesanan: p),
    );
    if (bayar == null || !context.mounted) return;
    await Repositori.instance.ubahPesanan(
      p,
      p.copyWith(pembayaran: [...p.pembayaran, bayar]),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Pembayaran dicatat.')));
  }

  Future<void> _hapus(BuildContext context, Pesanan p) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pesanan ini?'),
        content: Text('Pesanan ${p.namaPelanggan} tanggal '
            '${Format.tanggal(p.tanggalNota)} akan dihapus dan tidak bisa '
            'dikembalikan.'),
        actions: [
          TextButton(
            key: const Key('batal-hapus'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            key: const Key('konfirmasi-hapus'),
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true || !context.mounted) return;
    await Repositori.instance.hapusPesanan(p.id);
    if (context.mounted) Navigator.pop(context, HasilDetail.dihapus);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pesanan?>(
      stream: Repositori.instance.pantauSatuPesanan(pesanan.id),
      initialData: pesanan,
      builder: (context, snapshot) {
        final p = snapshot.data;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Pesanan')),
            body: const Center(child: Text('Pesanan sudah dihapus.')),
          );
        }
        return Scaffold(
          backgroundColor: AppTheme.permukaan,
          appBar: AppBar(title: const Text('Detail Pesanan')),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppTheme.lebarKontenMaks),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.marginTepi),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _KartuRingkasan(pesanan: p),
                        const SizedBox(height: AppTheme.spacing12),
                        _IsiDetail(
                          pesanan: p,
                          onCatatPembayaran: () =>
                              _catatPembayaran(context, p),
                          onHapus: () => _hapus(context, p),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _TombolBawah(
            onUbah: () => _bukaUbah(context, p),
            onBukaNota: () => _bukaNota(context, p),
          ),
        );
      },
    );
  }
}

/// Kartu ringkasan di atas Detail: pelanggan, status, total tagihan, dan
/// progres pembayaran (dibayar dan sisa).
class _KartuRingkasan extends StatelessWidget {
  final Pesanan pesanan;

  const _KartuRingkasan({required this.pesanan});

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    final lunas = p.statusPembayaran == StatusPembayaran.lunas;
    final porsiDibayar =
        p.totalTagihan == 0 ? 0.0 : p.totalDibayar / p.totalTagihan;
    const gayaKecil = TextStyle(
      fontSize: 12.5,
      color: AppTheme.textSecondary,
      fontFeatures: AppTheme.angkaRata,
    );
    const gayaNilai = TextStyle(
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary,
    );

    return Container(
      decoration: AppTheme.dekorasiKartu,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.namaPelanggan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTheme.subjudul,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nota ${Format.tanggal(p.tanggalNota)} · '
                      '${p.jenisPesanan.label}',
                      style: gayaKecil,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              StatusBadge(p.statusPembayaran),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 12),
            child: Divider(color: AppTheme.garisKartu),
          ),
          const Text('Total tagihan', style: gayaKecil),
          const SizedBox(height: 2),
          Text(
            Format.rupiah(p.totalTagihan),
            key: const Key('total-tagihan'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              fontFeatures: AppTheme.angkaRata,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: porsiDibayar.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.permukaan,
              color: lunas ? const Color(0xFF3E8E4A) : AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Dibayar ',
                    children: [
                      TextSpan(
                        text: Format.rupiah(p.totalDibayar),
                        style: gayaNilai,
                      ),
                    ],
                  ),
                  style: gayaKecil,
                ),
              ),
              Text.rich(
                TextSpan(
                  text: 'Sisa ',
                  children: [
                    TextSpan(
                      text: Format.rupiah(p.sisaTagihan),
                      style: gayaNilai,
                    ),
                  ],
                ),
                key: const Key('sisa-tagihan'),
                style: gayaKecil,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol Ubah dan Lihat Nota yang selalu terlihat di bawah Detail.
class _TombolBawah extends StatelessWidget {
  final VoidCallback onUbah;
  final VoidCallback onBukaNota;

  const _TombolBawah({required this.onUbah, required this.onBukaNota});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.garisKartu)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.marginTepi,
            AppTheme.spacing12,
            AppTheme.marginTepi,
            AppTheme.spacing12,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  key: const Key('ubah-pesanan'),
                  onPressed: onUbah,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Ubah'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12 - 2),
              Expanded(
                flex: 7,
                child: FilledButton.icon(
                  key: const Key('lihat-nota'),
                  onPressed: onBukaNota,
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  label: const Text('Lihat Nota'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IsiDetail extends StatelessWidget {
  final Pesanan pesanan;
  final VoidCallback onCatatPembayaran;
  final VoidCallback onHapus;

  const _IsiDetail({
    required this.pesanan,
    required this.onCatatPembayaran,
    required this.onHapus,
  });

  static const _gayaIsi = TextStyle(
    fontSize: AppTheme.isi,
    color: AppTheme.textPrimary,
  );
  static const _gayaKecil = TextStyle(
    fontSize: AppTheme.keterangan,
    color: AppTheme.textSecondary,
  );
  static const _gayaUang = TextStyle(
    fontSize: AppTheme.isi,
    color: AppTheme.textPrimary,
    fontFeatures: AppTheme.angkaRata,
  );

  Widget _baris(String judul, String keterangan, String nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: _gayaIsi),
                  if (keterangan.isNotEmpty) Text(keterangan, style: _gayaKecil),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(nilai, style: _gayaUang),
          ],
        ),
      );

  Widget _total(String label, int nilai, {bool tebal = false}) {
    final gaya = tebal
        ? _gayaUang.copyWith(fontWeight: FontWeight.w700)
        : _gayaUang.copyWith(color: AppTheme.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: gaya)),
          Text(Format.rupiah(nilai), style: gaya),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = pesanan;

    // Rincian dikelompokkan per tanggal kirim, seperti nota langganan.
    final perTanggal = <String, List<RincianMenu>>{};
    for (final r in p.rincian) {
      perTanggal.putIfAbsent(Konversi.kunciTanggal(r.tanggalKirim), () => []).add(r);
    }
    final tanggalUrut = perTanggal.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KartuBagian(
          judul: 'Rincian menu',
          ikon: Icons.restaurant_menu_outlined,
          children: [
            for (final kunci in tanggalUrut) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMuda,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Kirim ${Format.tanggal(perTanggal[kunci]!.first.tanggalKirim)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              for (final r in perTanggal[kunci]!)
                _baris(
                  r.namaMenu,
                  '${r.jumlahPorsi} porsi x ${Format.rupiah(r.hargaPerPorsi)}',
                  Format.rupiah(r.subtotal),
                ),
            ],
            if (p.ongkosKirim.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: AppTheme.spacing8, bottom: 2),
                child: Text(
                  'Ongkos kirim (tidak dihitung pendapatan)',
                  style: TextStyle(
                    fontSize: AppTheme.keterangan,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              for (final o in p.ongkosKirim)
                _baris(
                  o.keterangan.isEmpty ? 'Ongkos kirim' : o.keterangan,
                  '${o.jumlahKirim} kali x ${Format.rupiah(o.tarif)}',
                  Format.rupiah(o.subtotal),
                ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacing8),
              child: Divider(),
            ),
            _total('Total menu', p.totalMenu),
            _total('Total ongkos kirim', p.totalOngkir),
            _total('Total tagihan', p.totalTagihan, tebal: true),
          ],
        ),
        KartuBagian(
          judul: 'Pembayaran',
          ikon: Icons.payments_outlined,
          children: [
            if (p.pembayaran.isEmpty)
              const Text('Belum ada pembayaran.', style: _gayaKecil)
            else
              for (final b in p.pembayaran)
                _baris(
                  Format.tanggal(b.tanggalBayar),
                  b.keterangan,
                  Format.rupiah(b.nominal),
                ),
            const SizedBox(height: AppTheme.spacing12),
            FilledButton.icon(
              key: const Key('catat-pembayaran'),
              onPressed: p.sisaTagihan > 0 ? onCatatPembayaran : null,
              icon: const Icon(Icons.add, size: 20),
              label: Text(p.sisaTagihan > 0
                  ? 'Catat Pembayaran'
                  : 'Sudah lunas'),
            ),
          ],
        ),
        KartuBagian(
          judul: 'Riwayat perubahan',
          ikon: Icons.history,
          children: [_RiwayatPerubahan(pesananId: p.id)],
        ),
        TextButton.icon(
          key: const Key('hapus-pesanan'),
          onPressed: onHapus,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.danger,
            minimumSize: const Size(0, AppTheme.tinggiTombol),
          ),
          icon: const Icon(Icons.delete_outline, size: 20),
          label: const Text('Hapus Pesanan'),
        ),
        const SizedBox(height: AppTheme.spacing8),
      ],
    );
  }
}

class _RiwayatPerubahan extends StatelessWidget {
  final String pesananId;

  const _RiwayatPerubahan({required this.pesananId});

  String _waktu(DateTime t) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${Format.tanggal(t)}, ${dua(t.hour)}.${dua(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RiwayatPerubahan>>(
      stream: Repositori.instance.pantauRiwayat(pesananId),
      builder: (context, snapshot) {
        final daftar = snapshot.data ?? const <RiwayatPerubahan>[];
        if (daftar.isEmpty) {
          return const Text(
            'Belum ada perubahan sejak pesanan dicatat.',
            style: TextStyle(
              fontSize: AppTheme.keterangan,
              color: AppTheme.textSecondary,
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < daftar.length; i++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 16,
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (i < daftar.length - 1)
                            Expanded(
                              child: Container(width: 1, color: AppTheme.garis),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              daftar[i].bagian,
                              style: const TextStyle(
                                fontSize: AppTheme.isi,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${daftar[i].nilaiLama.isEmpty ? '-' : daftar[i].nilaiLama}'
                              ' menjadi '
                              '${daftar[i].nilaiBaru.isEmpty ? '-' : daftar[i].nilaiBaru}',
                              style: const TextStyle(
                                fontSize: AppTheme.isi,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _waktu(daftar[i].waktu),
                              style: const TextStyle(
                                fontSize: AppTheme.keterangan,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Dialog pencatatan pembayaran (KF-07, BB-16 sampai BB-18).
class _DialogPembayaran extends StatefulWidget {
  final Pesanan pesanan;

  const _DialogPembayaran({required this.pesanan});

  @override
  State<_DialogPembayaran> createState() => _DialogPembayaranState();
}

class _DialogPembayaranState extends State<_DialogPembayaran> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  DateTime _tanggal = DateTime.now();

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final p = widget.pesanan;
    Navigator.pop(
      context,
      Pembayaran(
        noUrut: p.pembayaran.length + 1,
        tanggalBayar: _tanggal,
        nominal: AturanPesanan.bacaRupiah(_nominalController.text)!,
        keterangan: _keteranganController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sisa = widget.pesanan.sisaTagihan;
    return AlertDialog(
      title: const Text('Catat Pembayaran'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sisa tagihan ${Format.rupiah(sisa)}'),
            const SizedBox(height: AppTheme.spacing12),
            TextFormField(
              key: const Key('nominal-pembayaran'),
              controller: _nominalController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
              ),
              validator: (v) => AturanPesanan.validasiNominal(v, sisa),
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextFormField(
              controller: _keteranganController,
              decoration: const InputDecoration(
                labelText: 'Keterangan (boleh kosong)',
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            OutlinedButton.icon(
              onPressed: () async {
                final hasil = await showDatePicker(
                  context: context,
                  initialDate: _tanggal,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (hasil != null) setState(() => _tanggal = hasil);
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text('Tanggal bayar: ${Format.tanggal(_tanggal)}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          key: const Key('simpan-pembayaran'),
          onPressed: _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
