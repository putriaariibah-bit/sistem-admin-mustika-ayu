import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repositori.dart';
import '../models/profil_usaha.dart';
import '../utils/theme.dart';
import '../utils/validasi_profil.dart';
import '../widgets/logo_usaha.dart';

/// Halaman Profil Usaha: nama usaha, alamat, nomor WhatsApp, dan logo.
///
/// Pengembangan lanjutan di luar rancangan Bab III, agar aplikasi dapat
/// dipakai pemilik katering lain. Isinya dipakai pada kepala nota dan
/// kepala Dashboard.
///
/// - [wajib] = true: dibuka otomatis setelah Buat Akun atau saat profil
///   belum pernah diisi; tanpa tombol kembali, ada tombol Keluar.
/// - [wajib] = false: dibuka dari Dashboard untuk mengubah profil.
class ProfilUsahaScreen extends StatefulWidget {
  /// Batas ukuran logo agar dokumen Firestore tetap kecil.
  static const int batasLogo = 400 * 1024;

  final ProfilUsaha awal;
  final bool wajib;
  final VoidCallback? onKeluar;

  /// Pemilih gambar. Bawaannya galeri ponsel; dapat diganti pada
  /// pengujian.
  final Future<Uint8List?> Function()? pilihGambar;

  const ProfilUsahaScreen({
    super.key,
    this.awal = ProfilUsaha.kosong,
    this.wajib = false,
    this.onKeluar,
    this.pilihGambar,
  });

  @override
  State<ProfilUsahaScreen> createState() => _ProfilUsahaScreenState();
}

class _ProfilUsahaScreenState extends State<ProfilUsahaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.awal.nama);
  late final _alamat = TextEditingController(text: widget.awal.alamat);
  late final _whatsapp = TextEditingController(text: widget.awal.whatsapp);
  late String? _logo = widget.awal.logo;
  bool _menyimpan = false;

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  ProfilUsaha get _draf => ProfilUsaha(
        nama: _nama.text,
        alamat: _alamat.text,
        whatsapp: _whatsapp.text,
        logo: _logo,
      );

  void _tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<Uint8List?> _pilihDariGaleri() async {
    final berkas = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    return berkas?.readAsBytes();
  }

  Future<void> _pilihLogo() async {
    final Uint8List? bytes;
    try {
      bytes = await (widget.pilihGambar ?? _pilihDariGaleri)();
    } catch (_) {
      if (mounted) _tampilkanPesan('Gambar tidak dapat dibuka.');
      return;
    }
    if (bytes == null || !mounted) return;
    if (bytes.length > ProfilUsahaScreen.batasLogo) {
      _tampilkanPesan(
        'Ukuran logo terlalu besar (maksimal 400 KB). Pilih gambar lain.',
      );
      return;
    }
    final teks = base64Encode(bytes);
    setState(() => _logo = teks);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    final profil = _draf.dirapikan;
    try {
      await Repositori.instance.simpanProfil(profil);
      ProfilUsaha.aktif.value = profil;
      if (mounted && !widget.wajib) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _tampilkanPesan(
          'Profil gagal disimpan. Periksa koneksi internet lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Usaha'),
        automaticallyImplyLeading: !widget.wajib,
        actions: [
          if (widget.wajib && widget.onKeluar != null)
            TextButton(
              key: const Key('keluar-profil'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: widget.onKeluar,
              child: const Text('Keluar'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.marginTepi),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.wajib) ...[
                      const Text(
                        'Lengkapi profil usahamu. Nama, alamat, nomor '
                        'WhatsApp, dan logo ini tampil di kepala nota.',
                        style: TextStyle(
                          fontSize: AppTheme.isi,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                    ],
                    Center(child: LogoUsaha(ukuran: 88, profil: _draf)),
                    const SizedBox(height: AppTheme.spacing12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppTheme.spacing8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('pilih-logo'),
                          onPressed: _menyimpan ? null : _pilihLogo,
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: Text(_logo == null ? 'Pilih logo' : 'Ganti logo'),
                        ),
                        if (_logo != null)
                          TextButton(
                            key: const Key('hapus-logo'),
                            onPressed: _menyimpan
                                ? null
                                : () => setState(() => _logo = null),
                            child: const Text('Hapus logo'),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    const Text(
                      'Logo boleh dikosongkan. Bila kosong, nota memakai huruf '
                      'depan nama usaha.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTheme.keterangan,
                        color: AppTheme.textTersier,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    TextFormField(
                      key: const Key('profil-nama'),
                      controller: _nama,
                      enabled: !_menyimpan,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nama usaha'),
                      validator: ValidasiProfil.nama,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      key: const Key('profil-alamat'),
                      controller: _alamat,
                      enabled: !_menyimpan,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Alamat (boleh kosong)',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      key: const Key('profil-whatsapp'),
                      controller: _whatsapp,
                      enabled: !_menyimpan,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp (boleh kosong)',
                        hintText: 'contoh: 081234567890',
                      ),
                      validator: ValidasiProfil.whatsapp,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    FilledButton(
                      key: const Key('simpan-profil'),
                      onPressed: _menyimpan ? null : _simpan,
                      child: _menyimpan
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.onPrimary,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
