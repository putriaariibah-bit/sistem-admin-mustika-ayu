import 'package:flutter/material.dart';

import '../data/repositori.dart';
import '../models/aturan_pesanan.dart';
import '../models/ongkos_kirim.dart';
import '../models/pelanggan.dart';
import '../models/pesanan.dart';
import '../models/rincian_menu.dart';
import '../utils/format.dart';
import '../utils/rupiah_input.dart';
import '../utils/theme.dart';
import '../widgets/kartu_bagian.dart';
import 'pilih_pelanggan_screen.dart';

/// Form Tambah Pesanan dan Ubah Pesanan (proses 3.1 dan 3.3,
/// KF-03 sampai KF-06, Gambar 3.7(d)).
///
/// Satu pesanan berisi banyak baris rincian menu (tanggal kirim, nama
/// menu, jumlah porsi, harga per porsi) dan baris ongkos kirim yang
/// terpisah. Subtotal dan total dihitung otomatis saat pemilik mengetik.
/// Kolom jumlah porsi dibiarkan kosong sesuai masukan pemilik.
///
/// Mengembalikan true lewat [Navigator.pop] bila pesanan tersimpan.
class FormPesananScreen extends StatefulWidget {
  /// Pesanan yang diubah. Null berarti menambah pesanan baru.
  final Pesanan? pesananAwal;

  const FormPesananScreen({super.key, this.pesananAwal});

  @override
  State<FormPesananScreen> createState() => _FormPesananScreenState();
}

class _BarisMenu {
  DateTime tanggalKirim;
  final TextEditingController nama;
  final TextEditingController porsi;
  final TextEditingController harga;

  _BarisMenu({
    required this.tanggalKirim,
    String nama = '',
    String porsi = '',
    String harga = '',
  }) : nama = TextEditingController(text: nama),
       porsi = TextEditingController(text: porsi),
       harga = TextEditingController(text: harga);

  int get subtotal =>
      (int.tryParse(porsi.text.trim()) ?? 0) *
      (AturanPesanan.bacaRupiah(harga.text) ?? 0);

  void dispose() {
    nama.dispose();
    porsi.dispose();
    harga.dispose();
  }
}

class _BarisOngkir {
  final TextEditingController keterangan;
  final TextEditingController jumlah;
  final TextEditingController tarif;

  _BarisOngkir({String keterangan = '', String jumlah = '', String tarif = ''})
    : keterangan = TextEditingController(text: keterangan),
      jumlah = TextEditingController(text: jumlah),
      tarif = TextEditingController(text: tarif);

  int get subtotal =>
      (int.tryParse(jumlah.text.trim()) ?? 0) *
      (AturanPesanan.bacaRupiah(tarif.text) ?? 0);

  void dispose() {
    keterangan.dispose();
    jumlah.dispose();
    tarif.dispose();
  }
}

class _FormPesananScreenState extends State<FormPesananScreen> {
  final _formKey = GlobalKey<FormState>();

  String _pelangganId = '';
  String _namaPelanggan = '';
  late DateTime _tanggalNota;
  JenisPesanan _jenis = JenisPesanan.langgananHarian;
  final List<_BarisMenu> _menu = [];
  final List<_BarisOngkir> _ongkir = [];

  late final Stream<List<Pelanggan>> _streamPelanggan = Repositori.instance
      .pantauPelanggan();
  TextEditingController? _pelangganController;
  String? _pesanRincian;
  bool _menyimpan = false;

  bool get _modeUbah => widget.pesananAwal != null;

  @override
  void initState() {
    super.initState();
    final awal = widget.pesananAwal;
    if (awal == null) {
      final hariIni = DateTime.now();
      _tanggalNota = DateTime(hariIni.year, hariIni.month, hariIni.day);
      _menu.add(_BarisMenu(tanggalKirim: _tanggalNota));
      return;
    }
    _pelangganId = awal.pelangganId;
    _namaPelanggan = awal.namaPelanggan;
    _tanggalNota = awal.tanggalNota;
    _jenis = awal.jenisPesanan;
    for (final r in awal.rincian) {
      _menu.add(
        _BarisMenu(
          tanggalKirim: r.tanggalKirim,
          nama: r.namaMenu,
          porsi: '${r.jumlahPorsi}',
          harga: Format.ribuan(r.hargaPerPorsi),
        ),
      );
    }
    for (final o in awal.ongkosKirim) {
      _ongkir.add(
        _BarisOngkir(
          keterangan: o.keterangan,
          jumlah: '${o.jumlahKirim}',
          tarif: Format.ribuan(o.tarif),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final b in _menu) {
      b.dispose();
    }
    for (final b in _ongkir) {
      b.dispose();
    }
    super.dispose();
  }

  int get _totalMenu => _menu.fold(0, (j, b) => j + b.subtotal);
  int get _totalOngkir => _ongkir.fold(0, (j, b) => j + b.subtotal);

  /// Membuka halaman kelola pelanggan; pelanggan yang dipilih dipakai.
  Future<void> _pilihPelanggan() async {
    final dipilih = await Navigator.push<Pelanggan>(
      context,
      MaterialPageRoute(builder: (context) => const PilihPelangganScreen()),
    );
    if (dipilih == null || !mounted) return;
    _pakaiPelanggan(dipilih);
  }

  void _pakaiPelanggan(Pelanggan p) {
    setState(() {
      _pelangganId = p.id;
      _namaPelanggan = p.nama;
    });
    _pelangganController?.text = p.nama;
  }

  /// Saran nama dipilih; pelanggan baru langsung disimpan (KF-02).
  Future<void> _pilihSaran(_OpsiPelanggan opsi) async {
    final ada = opsi.pelanggan;
    if (ada != null) {
      _pakaiPelanggan(ada);
      return;
    }
    final baru = await Repositori.instance.simpanPelanggan(
      Pelanggan(nama: opsi.namaBaru),
    );
    if (!mounted) return;
    _pakaiPelanggan(baru);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Pelanggan ${baru.nama} ditambahkan.')),
      );
  }

  Future<DateTime?> _pilihTanggal(DateTime awal) => showDatePicker(
    context: context,
    initialDate: awal,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    helpText: 'Pilih tanggal',
    cancelText: 'Batal',
    confirmText: 'Pilih',
  );

  void _tambahMenu() {
    final tanggal = _menu.isEmpty ? _tanggalNota : _menu.last.tanggalKirim;
    setState(() {
      _menu.add(_BarisMenu(tanggalKirim: tanggal));
      _pesanRincian = null;
    });
  }

  void _hapusMenu(int i) {
    final baris = _menu.removeAt(i);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => baris.dispose());
  }

  void _hapusOngkir(int i) {
    final baris = _ongkir.removeAt(i);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => baris.dispose());
  }

  Pesanan _susunPesanan() {
    final awal = widget.pesananAwal;
    return Pesanan(
      id: awal?.id ?? '',
      pelangganId: _pelangganId,
      namaPelanggan: _namaPelanggan,
      tanggalNota: _tanggalNota,
      jenisPesanan: _jenis,
      rincian: [
        for (var i = 0; i < _menu.length; i++)
          RincianMenu(
            noUrut: i + 1,
            tanggalKirim: _menu[i].tanggalKirim,
            namaMenu: _menu[i].nama.text.trim(),
            jumlahPorsi: int.parse(_menu[i].porsi.text.trim()),
            hargaPerPorsi: AturanPesanan.bacaRupiah(_menu[i].harga.text)!,
          ),
      ],
      ongkosKirim: [
        for (var i = 0; i < _ongkir.length; i++)
          OngkosKirim(
            noUrut: i + 1,
            keterangan: _ongkir[i].keterangan.text.trim(),
            jumlahKirim: int.parse(_ongkir[i].jumlah.text.trim()),
            tarif: AturanPesanan.bacaRupiah(_ongkir[i].tarif.text)!,
          ),
      ],
      pembayaran: awal?.pembayaran ?? const [],
      dibuatPada: awal?.dibuatPada,
      diubahPada: awal?.diubahPada,
    );
  }

  Future<void> _simpan() async {
    final kolomValid = _formKey.currentState!.validate();
    setState(() {
      _pesanRincian = _menu.isEmpty ? 'Rincian menu wajib diisi' : null;
    });
    if (!kolomValid || _pesanRincian != null) return;

    final pesanan = _susunPesanan();
    final awal = widget.pesananAwal;
    if (awal != null && pesanan.totalTagihan < awal.totalDibayar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Total tagihan tidak boleh kurang dari jumlah yang '
            'sudah dibayar.',
          ),
        ),
      );
      return;
    }

    setState(() => _menyimpan = true);
    try {
      if (awal == null) {
        await Repositori.instance.tambahPesanan(pesanan);
      } else {
        await Repositori.instance.ubahPesanan(awal, pesanan);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pesanan gagal disimpan: $e')));
    }
  }

  // ── Tampilan ─────────────────────────────────────────────────

  Widget _tombolTanggal({
    required Key key,
    required String label,
    required DateTime tanggal,
    required ValueChanged<DateTime> onDipilih,
  }) => OutlinedButton.icon(
    key: key,
    onPressed: () async {
      final hasil = await _pilihTanggal(tanggal);
      if (hasil != null && mounted) setState(() => onDipilih(hasil));
    },
    icon: const Icon(Icons.calendar_today_outlined, size: 18),
    label: Text('$label: ${Format.tanggal(tanggal)}'),
  );

  Widget _kartuMenu(int i) {
    final b = _menu[i];
    return Container(
      key: ObjectKey(b),
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.permukaan,
        borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Menu ${i + 1}',
                    style: const TextStyle(
                      fontSize: AppTheme.isi,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('hapus-menu-$i'),
                  tooltip: 'Hapus baris menu',
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.danger,
                  onPressed: () => _hapusMenu(i),
                ),
              ],
            ),
            _tombolTanggal(
              key: Key('tanggal-kirim-$i'),
              label: 'Tanggal kirim',
              tanggal: b.tanggalKirim,
              onDipilih: (t) => b.tanggalKirim = t,
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextFormField(
              key: Key('nama-menu-$i'),
              controller: b.nama,
              decoration: const InputDecoration(labelText: 'Nama menu'),
              validator: AturanPesanan.validasiNamaMenu,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('porsi-$i'),
                    controller: b.porsi,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Porsi'),
                    validator: AturanPesanan.validasiPorsi,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: Key('harga-$i'),
                    controller: b.harga,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga per porsi',
                      prefixText: 'Rp ',
                    ),
                    inputFormatters: [RupiahInputFormatter()],
                    validator: AturanPesanan.validasiHarga,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Subtotal ${Format.rupiah(b.subtotal)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: AppTheme.keterangan,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuOngkir(int i) {
    final b = _ongkir[i];
    return Container(
      key: ObjectKey(b),
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.permukaan,
        borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('keterangan-ongkir-$i'),
                    controller: b.keterangan,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (boleh kosong)',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus ongkos kirim',
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.danger,
                  onPressed: () => _hapusOngkir(i),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('jumlah-kirim-$i'),
                    controller: b.jumlah,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah kirim',
                    ),
                    validator: AturanPesanan.validasiJumlahKirim,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: Key('tarif-$i'),
                    controller: b.tarif,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tarif',
                      prefixText: 'Rp ',
                    ),
                    inputFormatters: [RupiahInputFormatter()],
                    validator: AturanPesanan.validasiTarif,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Subtotal ${Format.rupiah(b.subtotal)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: AppTheme.keterangan,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barisTotal(String label, int nilai, {bool tebal = false}) {
    final gaya = TextStyle(
      fontSize: tebal ? AppTheme.subjudul : AppTheme.isi,
      fontWeight: tebal ? FontWeight.w700 : FontWeight.w400,
      color: AppTheme.textPrimary,
      fontFeatures: AppTheme.angkaRata,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: gaya)),
          Text(Format.rupiah(nilai), style: gaya),
        ],
      ),
    );
  }

  Widget _kolomPelanggan() {
    return StreamBuilder<List<Pelanggan>>(
      stream: _streamPelanggan,
      builder: (context, snapshot) {
        final daftar = snapshot.data ?? const <Pelanggan>[];
        return Autocomplete<_OpsiPelanggan>(
          initialValue: TextEditingValue(text: _namaPelanggan),
          displayStringForOption: (o) => o.nama,
          optionsBuilder: (nilai) {
            final kata = nilai.text.trim();
            if (kata.isEmpty) return const <_OpsiPelanggan>[];
            final kecil = kata.toLowerCase();
            final cocok = [
              for (final p in daftar)
                if (p.nama.toLowerCase().contains(kecil)) _OpsiPelanggan.ada(p),
            ];
            final sudahAda = daftar.any((p) => p.nama.toLowerCase() == kecil);
            if (!sudahAda) cocok.add(_OpsiPelanggan.baru(kata));
            return cocok;
          },
          onSelected: _pilihSaran,
          optionsViewBuilder: (context, onSelected, opsi) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppTheme.sudutKartu),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                  maxWidth: 480,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final o in opsi)
                      ListTile(
                        key: Key(
                          o.pelanggan == null
                              ? 'saran-pelanggan-baru'
                              : 'saran-${o.pelanggan!.id}',
                        ),
                        leading: Icon(
                          o.pelanggan == null
                              ? Icons.person_add_alt_1_outlined
                              : Icons.person_outline,
                          color: AppTheme.primary,
                        ),
                        title: Text(
                          o.pelanggan == null
                              ? 'Tambah pelanggan baru: ${o.nama}'
                              : o.nama,
                        ),
                        onTap: () => onSelected(o),
                      ),
                  ],
                ),
              ),
            ),
          ),
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            _pelangganController = controller;
            return TextFormField(
              key: const Key('kolom-pelanggan'),
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Pelanggan',
                hintText: 'Ketik nama pelanggan',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                suffixIcon: IconButton(
                  key: const Key('pilih-pelanggan'),
                  tooltip: 'Kelola pelanggan',
                  icon: const Icon(Icons.people_alt_outlined),
                  onPressed: _pilihPelanggan,
                ),
              ),
              onChanged: (teks) {
                if (_pelangganId.isNotEmpty && teks.trim() != _namaPelanggan) {
                  setState(() => _pelangganId = '');
                }
              },
              validator: (_) =>
                  _pelangganId.isEmpty ? 'Pelanggan wajib dipilih' : null,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.permukaan,
      appBar: AppBar(
        title: Text(_modeUbah ? 'Ubah Pesanan' : 'Tambah Pesanan'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.marginTepi),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.lebarKontenMaks,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KartuBagian(
                      judul: 'Pesanan',
                      ikon: Icons.receipt_long_outlined,
                      children: [
                        _kolomPelanggan(),
                        const SizedBox(height: AppTheme.spacing12),
                        _tombolTanggal(
                          key: const Key('tanggal-nota'),
                          label: 'Tanggal nota',
                          tanggal: _tanggalNota,
                          onDipilih: (t) => _tanggalNota = t,
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        SegmentedButton<JenisPesanan>(
                          key: const Key('jenis-pesanan'),
                          showSelectedIcon: false,
                          segments: [
                            for (final j in JenisPesanan.values)
                              ButtonSegment(value: j, label: Text(j.label)),
                          ],
                          selected: {_jenis},
                          onSelectionChanged: (pilihan) =>
                              setState(() => _jenis = pilihan.first),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          _jenis == JenisPesanan.sekaligus
                              ? 'Satu kali kirim, misalnya pesanan untuk acara.'
                              : 'Dikirim beberapa hari dalam satu nota.',
                          style: const TextStyle(
                            fontSize: AppTheme.keterangan,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    KartuBagian(
                      judul: 'Rincian menu',
                      ikon: Icons.restaurant_menu_outlined,
                      children: [
                        for (var i = 0; i < _menu.length; i++) _kartuMenu(i),
                        if (_pesanRincian != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacing8,
                            ),
                            child: Text(
                              _pesanRincian!,
                              key: const Key('pesan-rincian'),
                              style: const TextStyle(
                                color: AppTheme.danger,
                                fontSize: AppTheme.keterangan,
                              ),
                            ),
                          ),
                        OutlinedButton.icon(
                          key: const Key('tambah-menu'),
                          onPressed: _tambahMenu,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah menu'),
                        ),
                      ],
                    ),
                    KartuBagian(
                      judul: 'Ongkos kirim',
                      ikon: Icons.local_shipping_outlined,
                      children: [
                        const Text(
                          'Dicatat di nota, tidak dihitung sebagai pendapatan.',
                          style: TextStyle(
                            fontSize: AppTheme.keterangan,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        for (var i = 0; i < _ongkir.length; i++)
                          _kartuOngkir(i),
                        OutlinedButton.icon(
                          key: const Key('tambah-ongkir'),
                          onPressed: () =>
                              setState(() => _ongkir.add(_BarisOngkir())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah ongkos kirim'),
                        ),
                      ],
                    ),
                    KartuBagian(
                      judul: 'Total',
                      ikon: Icons.calculate_outlined,
                      children: [
                        _barisTotal('Total menu', _totalMenu),
                        _barisTotal('Total ongkos kirim', _totalOngkir),
                        const Divider(),
                        _barisTotal(
                          'Total tagihan',
                          _totalMenu + _totalOngkir,
                          tebal: true,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.marginTepi,
            AppTheme.spacing8,
            AppTheme.marginTepi,
            AppTheme.spacing12,
          ),
          child: FilledButton(
            key: const Key('simpan-pesanan'),
            onPressed: _menyimpan ? null : _simpan,
            child: Text(_modeUbah ? 'Simpan Perubahan' : 'Simpan Pesanan'),
          ),
        ),
      ),
    );
  }
}

/// Satu saran pada kolom pelanggan: pelanggan yang sudah ada, atau
/// pelanggan baru dengan nama yang sedang diketik.
class _OpsiPelanggan {
  final Pelanggan? pelanggan;
  final String namaBaru;

  const _OpsiPelanggan.ada(Pelanggan this.pelanggan) : namaBaru = '';
  const _OpsiPelanggan.baru(this.namaBaru) : pelanggan = null;

  String get nama => pelanggan?.nama ?? namaBaru;
}
