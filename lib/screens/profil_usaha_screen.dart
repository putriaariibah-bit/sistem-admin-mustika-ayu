import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/repositori.dart';
import '../models/profil_usaha.dart';
import '../utils/theme.dart';
import '../utils/validasi_masuk.dart';
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

  /// Apakah akun sudah bisa masuk dengan email dan kata sandi. Bawaannya
  /// dibaca dari Firebase Authentication; dapat diisi pada pengujian.
  final bool? punyaKataSandi;

  /// Menambahkan kata sandi ke akun yang masuk lewat Google. Bawaannya
  /// Firebase Authentication; dapat diganti pada pengujian.
  final Future<void> Function(String kataSandi)? fungsiAturSandi;

  const ProfilUsahaScreen({
    super.key,
    this.awal = ProfilUsaha.kosong,
    this.wajib = false,
    this.onKeluar,
    this.pilihGambar,
    this.punyaKataSandi,
    this.fungsiAturSandi,
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
  late bool _perluKataSandi = !(widget.punyaKataSandi ?? _cekKataSandi());

  /// true bila akun yang sedang masuk sudah punya cara masuk email dan
  /// kata sandi. Bernilai true bila Firebase belum siap (mis. pengujian)
  /// agar tombol Atur kata sandi tidak tampil.
  static bool _cekKataSandi() {
    try {
      final pengguna = FirebaseAuth.instance.currentUser;
      if (pengguna == null) return true;
      return pengguna.providerData.any((p) => p.providerId == 'password');
    } catch (_) {
      return true;
    }
  }

  Future<void> _aturSandiFirebase(String kataSandi) async {
    final pengguna = FirebaseAuth.instance.currentUser;
    final email = pengguna?.email;
    if (pengguna == null || email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await pengguna.linkWithCredential(
      EmailAuthProvider.credential(email: email, password: kataSandi),
    );
  }

  static String _pesanAturSandi(String kode) {
    switch (kode) {
      case 'requires-recent-login':
        return 'Demi keamanan, keluar lalu masuk lagi dengan Google, '
            'kemudian coba lagi.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
      case 'provider-already-linked':
        return 'Akun ini sudah punya kata sandi.';
      case 'network-request-failed':
        return 'Tidak dapat terhubung. Periksa koneksi internet.';
      default:
        return 'Kata sandi gagal diatur. Silakan coba lagi.';
    }
  }

  Future<void> _aturKataSandi() async {
    final sandi = TextEditingController();
    final ulangi = TextEditingController();
    final kunciForm = GlobalKey<FormState>();
    final kataSandi = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur kata sandi'),
        content: Form(
          key: kunciForm,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Setelah kata sandi diatur, akun ini bisa dimasuki dengan '
                'Google maupun email dan kata sandi.',
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                key: const Key('sandi-baru'),
                controller: sandi,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi (minimal 6 karakter)',
                ),
                validator: ValidasiMasuk.kataSandiBaru,
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                key: const Key('ulangi-sandi-baru'),
                controller: ulangi,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Ulangi kata sandi'),
                validator: (v) => ValidasiMasuk.ulangiKataSandi(v, sandi.text),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('simpan-sandi-baru'),
            onPressed: () {
              if (kunciForm.currentState!.validate()) {
                Navigator.pop(ctx, sandi.text);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (kataSandi == null || !mounted) return;

    try {
      await (widget.fungsiAturSandi ?? _aturSandiFirebase)(kataSandi);
      if (!mounted) return;
      setState(() => _perluKataSandi = false);
      _tampilkanPesan(
        'Kata sandi berhasil diatur. Sekarang akun ini juga bisa dimasuki '
        'dengan email dan kata sandi.',
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) _tampilkanPesan(_pesanAturSandi(e.code));
    } catch (_) {
      if (mounted) _tampilkanPesan('Kata sandi gagal diatur. Silakan coba lagi.');
    }
  }

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
                          label: Text(
                            _logo == null ? 'Pilih logo' : 'Ganti logo',
                          ),
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
                      decoration: const InputDecoration(
                        labelText: 'Nama usaha',
                      ),
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
                    if (!widget.wajib && _perluKataSandi) ...[
                      const SizedBox(height: AppTheme.spacing24),
                      const Divider(),
                      const SizedBox(height: AppTheme.spacing12),
                      const Text(
                        'Akun ini masuk lewat Google. Atur kata sandi agar '
                        'juga bisa masuk dengan email dan kata sandi.',
                        style: TextStyle(
                          fontSize: AppTheme.keterangan,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      OutlinedButton.icon(
                        key: const Key('atur-kata-sandi'),
                        onPressed: _menyimpan ? null : _aturKataSandi,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: const Text('Atur kata sandi'),
                      ),
                    ],
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
