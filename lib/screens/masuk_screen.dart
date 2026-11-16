import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/theme.dart';
import '../utils/validasi_masuk.dart';
import '../widgets/logo_usaha.dart';

/// Halaman Masuk (proses 1.0 pada DFD level 0, KF-01).
///
/// Aplikasi hanya punya satu akun, yaitu akun pemilik yang dibuat lewat
/// Firebase Console (Authentication > Users > Add user). Karena itu
/// halaman ini hanya berisi mode Masuk, tanpa mode Daftar.
///
/// Pemeriksaan email dan kata sandi dilakukan oleh Firebase Authentication.
/// Setelah berhasil masuk, [CekStatusLogin] otomatis menampilkan Dashboard.
class MasukScreen extends StatefulWidget {
  /// Fungsi masuk. Bawaannya memakai Firebase Authentication; dapat diganti
  /// pada pengujian agar tidak menghubungi server.
  final Future<void> Function(String email, String kataSandi)? fungsiMasuk;

  const MasukScreen({super.key, this.fungsiMasuk});

  @override
  State<MasukScreen> createState() => _MasukScreenState();
}

class _MasukScreenState extends State<MasukScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _sandiController = TextEditingController();

  bool _sedangMemproses = false;
  bool _sandiTersembunyi = true;
  String? _pesanGagal;

  @override
  void dispose() {
    _emailController.dispose();
    _sandiController.dispose();
    super.dispose();
  }

  Future<void> _masukFirebase(String email, String kataSandi) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: kataSandi,
    );
  }

  Future<void> _tekanMasuk() async {
    setState(() => _pesanGagal = null);

    // BB-01: kolom kosong ditolak sebelum menghubungi server.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sedangMemproses = true);
    try {
      final masuk = widget.fungsiMasuk ?? _masukFirebase;
      await masuk(_emailController.text.trim(), _sandiController.text);
    } on FirebaseAuthException catch (e) {
      // BB-02: kredensial salah ditolak dengan pesan kesalahan.
      if (mounted) {
        setState(() => _pesanGagal = ValidasiMasuk.pesanDariKode(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _pesanGagal = 'Gagal masuk. Silakan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _sedangMemproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const Center(child: LogoUsaha(ukuran: 72)),
                    const SizedBox(height: AppTheme.spacing16),
                    const Text(
                      'Mustika Ayu Catering',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTheme.judul,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    const Text(
                      'Masuk untuk mencatat pesanan dan melihat rekap.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTheme.isi,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    TextFormField(
                      key: const Key('masuk-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !_sedangMemproses,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: ValidasiMasuk.email,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      key: const Key('masuk-kata-sandi'),
                      controller: _sandiController,
                      obscureText: _sandiTersembunyi,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enabled: !_sedangMemproses,
                      onFieldSubmitted: (_) => _tekanMasuk(),
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        suffixIcon: IconButton(
                          tooltip: _sandiTersembunyi
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          icon: Icon(
                            _sandiTersembunyi
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _sandiTersembunyi = !_sandiTersembunyi,
                          ),
                        ),
                      ),
                      validator: ValidasiMasuk.kataSandi,
                    ),
                    if (_pesanGagal != null) ...[
                      const SizedBox(height: AppTheme.spacing12),
                      Text(
                        _pesanGagal!,
                        key: const Key('masuk-pesan-gagal'),
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: AppTheme.keterangan,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacing24),
                    FilledButton(
                      key: const Key('tombol-masuk'),
                      onPressed: _sedangMemproses ? null : _tekanMasuk,
                      child: _sedangMemproses
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.onPrimary,
                              ),
                            )
                          : const Text('Masuk'),
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
