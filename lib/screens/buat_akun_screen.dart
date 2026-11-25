import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/theme.dart';
import '../utils/validasi_masuk.dart';

/// Halaman Buat Akun untuk pemilik katering baru.
///
/// Pengembangan lanjutan di luar rancangan Bab III. Setelah akun dibuat,
/// Firebase Authentication langsung memasukkan akun itu, lalu
/// [GerbangProfil] membuka halaman Profil Usaha.
class BuatAkunScreen extends StatefulWidget {
  /// Fungsi pembuat akun. Bawaannya Firebase Authentication; dapat
  /// diganti pada pengujian.
  final Future<void> Function(String email, String kataSandi)? fungsiBuatAkun;

  const BuatAkunScreen({super.key, this.fungsiBuatAkun});

  @override
  State<BuatAkunScreen> createState() => _BuatAkunScreenState();
}

class _BuatAkunScreenState extends State<BuatAkunScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _ulangi = TextEditingController();

  bool _memproses = false;
  bool _sandiTersembunyi = true;
  String? _pesanGagal;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    _ulangi.dispose();
    super.dispose();
  }

  /// Membuat akun, lalu mengirim email verifikasi. Email yang sudah
  /// diverifikasi membuat Firebase menggabungkan cara masuk Google dengan
  /// kata sandi (bukan menghapus kata sandinya) bila pemilik nanti masuk
  /// dengan Google memakai email yang sama.
  Future<void> _buatFirebase(String email, String kataSandi) async {
    final hasil = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: kataSandi,
    );
    try {
      await hasil.user?.sendEmailVerification();
    } catch (_) {
      // Gagal mengirim email verifikasi tidak menghalangi akun dipakai.
    }
  }

  Future<void> _kirim() async {
    setState(() => _pesanGagal = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _memproses = true);
    try {
      await (widget.fungsiBuatAkun ?? _buatFirebase)(
        _email.text.trim(),
        _sandi.text,
      );
      // Akun baru langsung masuk; tutup halaman ini agar halaman di
      // bawahnya (Profil Usaha) terlihat.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _pesanGagal = ValidasiMasuk.pesanBuatAkun(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _pesanGagal = 'Gagal membuat akun. Silakan coba lagi.');
      }
    }
    if (mounted) setState(() => _memproses = false);
  }

  InputDecoration _dekorasiSandi(String label) => InputDecoration(
    labelText: label,
    suffixIcon: IconButton(
      tooltip: _sandiTersembunyi
          ? 'Tampilkan kata sandi'
          : 'Sembunyikan kata sandi',
      icon: Icon(
        _sandiTersembunyi
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(() => _sandiTersembunyi = !_sandiTersembunyi),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.marginTepi),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Buat akun untuk mencatat pesanan usaha katering milikmu. '
                      'Setelah itu kamu akan diminta mengisi profil usaha, '
                      'dan kami mengirim email untuk memverifikasi alamat '
                      'emailmu.',
                      style: TextStyle(
                        fontSize: AppTheme.isi,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    TextFormField(
                      key: const Key('akun-email'),
                      controller: _email,
                      enabled: !_memproses,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: ValidasiMasuk.email,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      key: const Key('akun-kata-sandi'),
                      controller: _sandi,
                      enabled: !_memproses,
                      obscureText: _sandiTersembunyi,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _dekorasiSandi(
                        'Kata sandi (minimal 6 karakter)',
                      ),
                      validator: ValidasiMasuk.kataSandiBaru,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      key: const Key('akun-ulangi-sandi'),
                      controller: _ulangi,
                      enabled: !_memproses,
                      obscureText: _sandiTersembunyi,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _kirim(),
                      decoration: _dekorasiSandi('Ulangi kata sandi'),
                      validator: (v) =>
                          ValidasiMasuk.ulangiKataSandi(v, _sandi.text),
                    ),
                    if (_pesanGagal != null) ...[
                      const SizedBox(height: AppTheme.spacing12),
                      Text(
                        _pesanGagal!,
                        key: const Key('akun-pesan-gagal'),
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: AppTheme.keterangan,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacing24),
                    FilledButton(
                      key: const Key('kirim-buat-akun'),
                      onPressed: _memproses ? null : _kirim,
                      child: _memproses
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.onPrimary,
                              ),
                            )
                          : const Text('Buat Akun'),
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
