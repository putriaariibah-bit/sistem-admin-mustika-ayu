import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../models/aturan_pesanan.dart';
import '../models/pembayaran.dart';
import '../models/pesanan.dart';
import '../models/riwayat_perubahan.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import '../widgets/status_badge.dart';
import 'form_pesanan_screen.dart';

/// Hasil yang dikirim Detail Pesanan ke pemanggil lewat [Navigator.pop].
enum HasilDetail { dihapus }

/// Halaman Detail Pesanan (Gambar 3.7(e)).
///
/// Memuat data pesanan, rincian menu, ongkos kirim, total, status dan
/// daftar pembayaran (KF-07), riwayat perubahan (KF-06), serta tombol
/// Ubah Pesanan dan Hapus Pesanan dengan konfirmasi (BB-14).
/// Data selalu diambil terbaru dari Firestore.
class DetailPesananScreen extends StatelessWidget {
  final Pesanan pesanan;

  const DetailPesananScreen({super.key, required this.pesanan});

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
          appBar: AppBar(title: const Text('Detail Pesanan')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.marginTepi),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppTheme.lebarKontenMaks),
                  child: _IsiDetail(
                    pesanan: p,
                    onUbah: () => _bukaUbah(context, p),
                    onCatatPembayaran: () => _catatPembayaran(context, p),
                    onHapus: () => _hapus(context, p),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IsiDetail extends StatelessWidget {
  final Pesanan pesanan;
  final VoidCallback onUbah;
  final VoidCallback onCatatPembayaran;
  final VoidCallback onHapus;

  const _IsiDetail({
    required this.pesanan,
    required this.onUbah,
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

  Widget _label(String teks) => Padding(
        padding: const EdgeInsets.only(
          top: AppTheme.spacing24,
          bottom: AppTheme.spacing8,
        ),
        child: Text(teks.toUpperCase(), style: AppTheme.gayaLabelSeksi),
      );

  Widget _baris(String kiri, String kanan, {bool tebal = false, Key? key}) {
    final gaya = tebal
        ? _gayaIsi.copyWith(fontWeight: FontWeight.w700)
        : _gayaIsi;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(kiri, style: gaya)),
          const SizedBox(width: AppTheme.spacing8),
          Text(kanan, key: key, style: gaya),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          p.namaPelanggan,
          style: const TextStyle(
            fontSize: AppTheme.judul,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'Nota ${Format.tanggal(p.tanggalNota)} · ${p.jenisPesanan.label}',
          style: _gayaKecil,
        ),
        _label('Rincian menu'),
        for (final r in p.rincian)
          _baris(
            '${Format.tanggal(r.tanggalKirim)} · ${r.namaMenu}\n'
                '${r.jumlahPorsi} x ${Format.rupiah(r.hargaPerPorsi)}',
            Format.rupiah(r.subtotal),
          ),
        if (p.ongkosKirim.isNotEmpty) ...[
          _label('Ongkos kirim'),
          for (final o in p.ongkosKirim)
            _baris(
              '${o.keterangan.isEmpty ? 'Ongkos kirim' : o.keterangan}\n'
                  '${o.jumlahKirim} x ${Format.rupiah(o.tarif)}',
              Format.rupiah(o.subtotal),
            ),
        ],
        _label('Total'),
        _baris('Total menu', Format.rupiah(p.totalMenu)),
        _baris('Total ongkos kirim', Format.rupiah(p.totalOngkir)),
        const Divider(),
        _baris('Total tagihan', Format.rupiah(p.totalTagihan),
            tebal: true, key: const Key('total-tagihan')),
        _baris('Sudah dibayar', Format.rupiah(p.totalDibayar)),
        _baris('Sisa tagihan', Format.rupiah(p.sisaTagihan),
            tebal: true, key: const Key('sisa-tagihan')),
        const SizedBox(height: AppTheme.spacing8),
        Row(
          children: [
            const Text('Status pembayaran  ', style: _gayaKecil),
            StatusBadge(p.statusPembayaran),
          ],
        ),
        _label('Daftar pembayaran'),
        if (p.pembayaran.isEmpty)
          const Text('Belum ada pembayaran.', style: _gayaKecil)
        else
          for (final b in p.pembayaran)
            _baris(
              Format.tanggal(b.tanggalBayar) +
                  (b.keterangan.isEmpty ? '' : ' · ${b.keterangan}'),
              Format.rupiah(b.nominal),
            ),
        const SizedBox(height: AppTheme.spacing12),
        FilledButton.icon(
          key: const Key('catat-pembayaran'),
          onPressed: p.sisaTagihan > 0 ? onCatatPembayaran : null,
          icon: const Icon(Icons.payments_outlined, size: 20),
          label: const Text('Catat Pembayaran'),
        ),
        _label('Riwayat perubahan'),
        _RiwayatPerubahan(pesananId: p.id),
        const SizedBox(height: AppTheme.spacing24),
        OutlinedButton.icon(
          key: const Key('ubah-pesanan'),
          onPressed: onUbah,
          icon: const Icon(Icons.edit_outlined, size: 20),
          label: const Text('Ubah Pesanan'),
        ),
        const SizedBox(height: AppTheme.spacing12),
        OutlinedButton.icon(
          key: const Key('hapus-pesanan'),
          onPressed: onHapus,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.danger,
            side: const BorderSide(color: AppTheme.danger, width: 1.5),
          ),
          icon: const Icon(Icons.delete_outline, size: 20),
          label: const Text('Hapus Pesanan'),
        ),
      ],
    );
  }
}

class _RiwayatPerubahan extends StatelessWidget {
  final String pesananId;

  const _RiwayatPerubahan({required this.pesananId});

  String _waktu(DateTime t) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${Format.tanggal(t)} ${dua(t.hour)}.${dua(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RiwayatPerubahan>>(
      stream: Repositori.instance.pantauRiwayat(pesananId),
      builder: (context, snapshot) {
        final daftar = snapshot.data ?? const <RiwayatPerubahan>[];
        if (daftar.isEmpty) {
          return const Text(
            'Belum ada perubahan.',
            style: TextStyle(
              fontSize: AppTheme.keterangan,
              color: AppTheme.textSecondary,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in daftar)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
                child: Text(
                  '${_waktu(r.waktu)} · ${r.bagian}: '
                  '${r.nilaiLama.isEmpty ? '-' : r.nilaiLama} → '
                  '${r.nilaiBaru.isEmpty ? '-' : r.nilaiBaru}',
                  style: const TextStyle(
                    fontSize: AppTheme.keterangan,
                    color: AppTheme.textPrimary,
                  ),
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
