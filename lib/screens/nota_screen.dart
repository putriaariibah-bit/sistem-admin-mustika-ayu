import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/berkas_nota.dart';
import '../models/nota.dart';
import '../models/pesanan.dart';
import '../utils/theme.dart';
import '../widgets/nota_kertas.dart';

/// Halaman Nota (proses 5.0, KF-08, Gambar 3.8(f)).
///
/// Nota disusun dari data pesanan. Tombol Simpan menyimpan nota sebagai
/// berkas gambar PNG di ponsel, dan tombol Bagikan membuka menu berbagi
/// agar pemilik dapat mengirimkannya lewat WhatsApp (BB-20, UAT-06).
class NotaScreen extends StatefulWidget {
  final Pesanan pesanan;

  const NotaScreen({super.key, required this.pesanan});

  @override
  State<NotaScreen> createState() => _NotaScreenState();
}

class _NotaScreenState extends State<NotaScreen> {
  final _kunciNota = GlobalKey();
  bool _sibuk = false;

  late final Nota _nota = Nota.dariPesanan(widget.pesanan);

  Future<void> _jalankan(
    AksiNota aksi, {
    String? pesanBerhasil,
    required String pesanGagal,
  }) async {
    if (_sibuk) return;
    setState(() => _sibuk = true);
    String? pesan;
    try {
      final batas = _kunciNota.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final png = await gambarNota(batas);
      await aksi(png, _nota.namaBerkas);
      pesan = pesanBerhasil;
    } catch (e) {
      pesan = '$pesanGagal $e';
    }
    if (!mounted) return;
    setState(() => _sibuk = false);
    if (pesan != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pesan)));
    }
  }

  void _simpan() => _jalankan(
        BerkasNota.instance.simpan,
        pesanBerhasil: 'Nota tersimpan di Galeri, album '
            '${BerkasNotaPerangkat.album}.',
        pesanGagal: 'Nota gagal disimpan.',
      );

  void _bagikan() => _jalankan(
        BerkasNota.instance.bagikan,
        pesanGagal: 'Menu berbagi gagal dibuka.',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.permukaan,
      appBar: AppBar(title: const Text('Nota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.marginTepi),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.garis),
                borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
                child: RepaintBoundary(
                  key: _kunciNota,
                  child: NotaKertas(nota: _nota),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.marginTepi,
            AppTheme.spacing8,
            AppTheme.marginTepi,
            AppTheme.spacing12,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('simpan-nota'),
                  onPressed: _sibuk ? null : _simpan,
                  icon: const Icon(Icons.download_outlined, size: 20),
                  label: const Text('Simpan'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('bagikan-nota'),
                  onPressed: _sibuk ? null : _bagikan,
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: const Text('Bagikan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
