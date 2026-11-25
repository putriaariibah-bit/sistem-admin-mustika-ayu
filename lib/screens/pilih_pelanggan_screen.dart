import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../models/pelanggan.dart';
import '../utils/theme.dart';
import '../widgets/empty_state.dart';

/// Halaman data pelanggan (proses 2.0, KF-02).
///
/// Pemilik dapat mencari, menambah, dan mengubah nama pelanggan, lalu
/// memilih satu pelanggan untuk pesanan. Pelanggan yang dipilih
/// dikembalikan lewat [Navigator.pop].
class PilihPelangganScreen extends StatefulWidget {
  const PilihPelangganScreen({super.key});

  @override
  State<PilihPelangganScreen> createState() => _PilihPelangganScreenState();
}

class _PilihPelangganScreenState extends State<PilihPelangganScreen> {
  final _cariController = TextEditingController();
  late final Stream<List<Pelanggan>> _stream = Repositori.instance
      .pantauPelanggan();

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  /// Menambah (pelanggan null) atau mengubah nama pelanggan.
  Future<void> _bukaFormNama({Pelanggan? pelanggan}) async {
    final nama = await showDialog<String>(
      context: context,
      builder: (context) => _DialogNama(namaAwal: pelanggan?.nama ?? ''),
    );
    if (nama == null || !mounted) return;

    final disimpan = await Repositori.instance.simpanPelanggan(
      pelanggan == null
          ? Pelanggan(nama: nama)
          : pelanggan.copyWith(nama: nama),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            pelanggan == null
                ? 'Pelanggan ${disimpan.nama} ditambahkan.'
                : 'Nama pelanggan diubah.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Pelanggan')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.lebarKontenMaks,
            ),
            child: StreamBuilder<List<Pelanggan>>(
              stream: _stream,
              builder: (context, snapshot) {
                final semua = snapshot.data ?? const <Pelanggan>[];
                final kata = _cariController.text.trim().toLowerCase();
                final hasil = [
                  for (final p in semua)
                    if (p.nama.toLowerCase().contains(kata)) p,
                ];

                return ListView(
                  padding: const EdgeInsets.all(AppTheme.marginTepi),
                  children: [
                    TextField(
                      key: const Key('cari-pelanggan'),
                      controller: _cariController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama pelanggan',
                        prefixIcon: Icon(Icons.search, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    if (!snapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (hasil.isEmpty)
                      const EmptyState(
                        icon: Icons.person_search_outlined,
                        title: 'Pelanggan tidak ditemukan',
                        subtitle:
                            'Tambahkan pelanggan baru dengan tombol '
                            'di bawah.',
                      )
                    else
                      for (final p in hasil)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(p.nama),
                            onTap: () => Navigator.pop(context, p),
                            trailing: IconButton(
                              tooltip: 'Ubah nama',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _bukaFormNama(pelanggan: p),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.marginTepi,
            AppTheme.spacing8,
            AppTheme.marginTepi,
            AppTheme.spacing12,
          ),
          child: FilledButton.icon(
            key: const Key('tambah-pelanggan'),
            onPressed: _bukaFormNama,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
            label: const Text('Tambah Pelanggan'),
          ),
        ),
      ),
    );
  }
}

/// Dialog isian nama pelanggan (BB-04 dan BB-05).
class _DialogNama extends StatefulWidget {
  final String namaAwal;

  const _DialogNama({required this.namaAwal});

  @override
  State<_DialogNama> createState() => _DialogNamaState();
}

class _DialogNamaState extends State<_DialogNama> {
  final _formKey = GlobalKey<FormState>();
  late final _namaController = TextEditingController(text: widget.namaAwal);

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _namaController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.namaAwal.isEmpty ? 'Tambah Pelanggan' : 'Ubah Nama'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('nama-pelanggan'),
          controller: _namaController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama pelanggan'),
          validator: Pelanggan.validasiNama,
          onFieldSubmitted: (_) => _simpan(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          key: const Key('simpan-pelanggan'),
          onPressed: _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
