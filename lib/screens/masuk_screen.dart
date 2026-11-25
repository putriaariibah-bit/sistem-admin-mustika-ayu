import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/theme.dart';
import '../utils/validasi_masuk.dart';
import '../widgets/logo_usaha.dart';
import 'buat_akun_screen.dart';

/// Halaman Masuk (proses 1.0 pada DFD level 0, KF-01).
///
/// Sesuai Bab III, pemilik masuk dengan email dan kata sandi. Sebagai
/// pengembangan lanjutan, halaman ini juga punya tautan "Lupa kata
/// sandi?", tombol "Masuk dengan Google", dan "Buat Akun" agar pemilik
/// katering lain dapat mendaftar.
///
/// Pemeriksaan email dan kata sandi dilakukan oleh Firebase Authentication.
/// Setelah berhasil masuk, [CekStatusLogin] otomatis menampilkan Dashboard.
class MasukScreen extends StatefulWidget {
  /// Fungsi masuk. Bawaannya memakai Firebase Authentication; dapat diganti
  /// pada pengujian agar tidak menghubungi server.
  final Future<void> Function(String email, String kataSandi)? fungsiMasuk;

  /// Diteruskan ke [BuatAkunScreen]; untuk pengujian.
  final Future<void> Function(String email, String kataSandi)? fungsiBuatAkun;

  /// Pengirim email ganti kata sandi. Bawaannya Firebase Authentication.
  final Future<void> Function(String email)? fungsiLupaSandi;

  /// Masuk dengan akun Google. Bawaannya Firebase Authentication.
  final Future<void> Function()? fungsiMasukGoogle;

  const MasukScreen({
    super.key,
    this.fungsiMasuk,
    this.fungsiBuatAkun,
    this.fungsiLupaSandi,
    this.fungsiMasukGoogle,
  });

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

  void _tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  /// Web memakai jendela pop-up Google; Android memakai alur penyedia
  /// Firebase (perlu SHA-1 aplikasi terdaftar di Firebase).
  Future<void> _masukGoogleFirebase() async {
    final penyedia = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(penyedia);
    } else {
      await FirebaseAuth.instance.signInWithProvider(penyedia);
    }
  }

  Future<void> _tekanMasukGoogle() async {
    setState(() {
      _pesanGagal = null;
      _sedangMemproses = true;
    });
    try {
      await (widget.fungsiMasukGoogle ?? _masukGoogleFirebase)();
    } on FirebaseAuthException catch (e) {
      if (mounted && !ValidasiMasuk.dibatalkanPengguna(e.code)) {
        setState(() => _pesanGagal = ValidasiMasuk.pesanGoogle(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _pesanGagal = 'Gagal masuk dengan Google. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _sedangMemproses = false);
    }
  }

  Future<void> _kirimResetFirebase(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email);

  void _bukaBuatAkun() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuatAkunScreen(fungsiBuatAkun: widget.fungsiBuatAkun),
      ),
    );
  }

  Future<void> _lupaSandi() async {
    final kontrol = TextEditingController(text: _emailController.text.trim());
    final kunciForm = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa kata sandi'),
        content: Form(
          key: kunciForm,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Masukkan email akunmu. Tautan untuk membuat kata sandi baru '
                'akan dikirim ke email tersebut.',
              ),
              const SizedBox(height: AppTheme.spacing12),
              TextFormField(
                key: const Key('lupa-email'),
                controller: kontrol,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: ValidasiMasuk.email,
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
            key: const Key('kirim-lupa-sandi'),
            onPressed: () {
              if (kunciForm.currentState!.validate()) {
                Navigator.pop(ctx, kontrol.text.trim());
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (email == null || !mounted) return;

    try {
      final kirim = widget.fungsiLupaSandi ?? _kirimResetFirebase;
      await kirim(email);
      if (mounted) {
        _tampilkanPesan(
          'Jika email terdaftar, tautan untuk membuat kata sandi baru sudah '
          'dikirim. Periksa kotak masuk atau folder spam.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Email tidak terdaftar diberi pesan yang sama dengan berhasil agar
      // orang lain tidak dapat menebak email yang terdaftar.
      _tampilkanPesan(
        e.code == 'user-not-found'
            ? 'Jika email terdaftar, tautan untuk membuat kata sandi baru '
                  'sudah dikirim. Periksa kotak masuk atau folder spam.'
            : ValidasiMasuk.pesanLupaSandi(e.code),
      );
    } catch (_) {
      if (mounted) _tampilkanPesan('Gagal mengirim email. Silakan coba lagi.');
    }
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
                    const Center(child: LogoAplikasi(ukuran: 72)),
                    const SizedBox(height: AppTheme.spacing16),
                    const Text(
                      'KelolaKatering',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTheme.judul,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    const Text(
                      'Catat pesanan katering, buat nota, dan lihat rekap '
                      'pendapatan.',
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('tombol-lupa-sandi'),
                        onPressed: _sedangMemproses ? null : _lupaSandi,
                        child: const Text('Lupa kata sandi?'),
                      ),
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
                    const SizedBox(height: AppTheme.spacing16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing8,
                          ),
                          child: Text(
                            'atau',
                            style: TextStyle(
                              fontSize: AppTheme.keterangan,
                              color: AppTheme.textTersier,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    OutlinedButton(
                      key: const Key('tombol-masuk-google'),
                      onPressed: _sedangMemproses ? null : _tekanMasukGoogle,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'G',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          SizedBox(width: AppTheme.spacing8),
                          Text('Masuk dengan Google'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun?',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          key: const Key('tombol-buat-akun'),
                          onPressed: _sedangMemproses ? null : _bukaBuatAkun,
                          child: const Text('Buat Akun'),
                        ),
                      ],
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
