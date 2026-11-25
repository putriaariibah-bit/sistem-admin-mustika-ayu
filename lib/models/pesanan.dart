import 'konversi.dart';
import 'ongkos_kirim.dart';
import 'pembayaran.dart';
import 'rincian_menu.dart';

/// Jenis pesanan (batasan masalah nomor 2). Hanya keterangan; cara
/// menghitung total sama untuk kedua jenis.
enum JenisPesanan {
  sekaligus('Sekaligus'),
  langgananHarian('Langganan harian');

  const JenisPesanan(this.label);

  /// Teks yang tampil dan disimpan di field jenisPesanan.
  final String label;

  static JenisPesanan dariLabel(String? label) =>
      JenisPesanan.values.firstWhere(
        (j) => j.label == label,
        orElse: () => JenisPesanan.sekaligus,
      );
}

/// Status pembayaran (aturan 3.2.4 nomor 3).
enum StatusPembayaran {
  belumBayar('Belum bayar'),
  dp('DP'),
  lunas('Lunas');

  const StatusPembayaran(this.label);

  /// Teks yang tampil dan disimpan di field statusPembayaran.
  final String label;
}

/// Dokumen pada koleksi `pesanan` (Tabel 3.8).
///
/// Field turunan (totalMenu, totalOngkir, totalTagihan, totalDibayar,
/// statusPembayaran, daftarTanggalKirim) selalu dihitung dari rincian,
/// ongkos kirim, dan pembayaran, lalu ikut disimpan saat [toMap] agar
/// rekap dan saringan dapat langsung membacanya.
class Pesanan {
  /// ID dokumen Firestore. Kosong untuk pesanan yang belum disimpan.
  final String id;

  /// ID dokumen pelanggan yang dirujuk (field pelangganId).
  final String pelangganId;

  /// Salinan nama pelanggan saat pesanan dibuat, agar nota lama tetap sama.
  final String namaPelanggan;

  final DateTime tanggalNota;
  final JenisPesanan jenisPesanan;
  final List<RincianMenu> rincian;
  final List<OngkosKirim> ongkosKirim;
  final List<Pembayaran> pembayaran;
  final DateTime? dibuatPada;
  final DateTime? diubahPada;

  const Pesanan({
    this.id = '',
    required this.pelangganId,
    required this.namaPelanggan,
    required this.tanggalNota,
    required this.jenisPesanan,
    this.rincian = const [],
    this.ongkosKirim = const [],
    this.pembayaran = const [],
    this.dibuatPada,
    this.diubahPada,
  });

  // ── Field turunan (aturan 3.2.4) ─────────────────────────────

  /// Nomor 1: jumlah seluruh subtotal menu. Dasar pendapatan.
  int get totalMenu => rincian.fold(0, (jumlah, r) => jumlah + r.subtotal);

  /// Nomor 2: jumlah seluruh subtotal ongkos kirim.
  int get totalOngkir =>
      ongkosKirim.fold(0, (jumlah, o) => jumlah + o.subtotal);

  /// Nomor 2: nilai yang dibayar pelanggan.
  int get totalTagihan => totalMenu + totalOngkir;

  /// Nomor 3: jumlah seluruh pembayaran yang tercatat.
  int get totalDibayar => pembayaran.fold(0, (jumlah, p) => jumlah + p.nominal);

  /// Nomor 3: total tagihan dikurangi pembayaran.
  int get sisaTagihan => totalTagihan - totalDibayar;

  /// Nomor 3: Belum bayar, DP, atau Lunas.
  StatusPembayaran get statusPembayaran {
    if (totalDibayar <= 0) return StatusPembayaran.belumBayar;
    if (totalDibayar < totalTagihan) return StatusPembayaran.dp;
    return StatusPembayaran.lunas;
  }

  /// Seluruh tanggal kirim pada rincian, tanpa duplikat, berurutan.
  List<String> get daftarTanggalKirim {
    final kunci = rincian.map((r) => Konversi.kunciTanggal(r.tanggalKirim));
    return kunci.toSet().toList()..sort();
  }

  /// True bila ada rincian yang dikirim pada [tanggal] (saringan KF-09).
  bool dikirimPada(DateTime tanggal) =>
      daftarTanggalKirim.contains(Konversi.kunciTanggal(tanggal));

  // ── Firestore ────────────────────────────────────────────────

  Map<String, Object?> toMap() => {
    'pelangganId': pelangganId,
    'namaPelanggan': namaPelanggan.trim(),
    'tanggalNota': Konversi.tanpaJam(tanggalNota),
    'jenisPesanan': jenisPesanan.label,
    'rincian': [for (final r in rincian) r.toMap()],
    'daftarTanggalKirim': daftarTanggalKirim,
    'ongkosKirim': [for (final o in ongkosKirim) o.toMap()],
    'pembayaran': [for (final p in pembayaran) p.toMap()],
    'totalMenu': totalMenu,
    'totalOngkir': totalOngkir,
    'totalTagihan': totalTagihan,
    'totalDibayar': totalDibayar,
    'statusPembayaran': statusPembayaran.label,
    'dibuatPada': dibuatPada,
    'diubahPada': diubahPada,
  };

  /// Membaca dokumen pesanan. Field turunan tidak dibaca dari dokumen,
  /// tetapi dihitung ulang dari rincian, ongkos kirim, dan pembayaran.
  factory Pesanan.fromMap(String id, Map<String, Object?> data) {
    List<Map<String, Object?>> daftar(Object? nilai) => [
      for (final item in (nilai as List?) ?? const [])
        Map<String, Object?>.from(item as Map),
    ];

    return Pesanan(
      id: id,
      pelangganId: (data['pelangganId'] as String?) ?? '',
      namaPelanggan: (data['namaPelanggan'] as String?) ?? '',
      tanggalNota: Konversi.tanggal(data['tanggalNota']),
      jenisPesanan: JenisPesanan.dariLabel(data['jenisPesanan'] as String?),
      rincian: [
        for (final m in daftar(data['rincian'])) RincianMenu.fromMap(m),
      ],
      ongkosKirim: [
        for (final m in daftar(data['ongkosKirim'])) OngkosKirim.fromMap(m),
      ],
      pembayaran: [
        for (final m in daftar(data['pembayaran'])) Pembayaran.fromMap(m),
      ],
      dibuatPada: data['dibuatPada'] == null
          ? null
          : Konversi.tanggal(data['dibuatPada']),
      diubahPada: data['diubahPada'] == null
          ? null
          : Konversi.tanggal(data['diubahPada']),
    );
  }

  Pesanan copyWith({
    String? id,
    String? pelangganId,
    String? namaPelanggan,
    DateTime? tanggalNota,
    JenisPesanan? jenisPesanan,
    List<RincianMenu>? rincian,
    List<OngkosKirim>? ongkosKirim,
    List<Pembayaran>? pembayaran,
    DateTime? dibuatPada,
    DateTime? diubahPada,
  }) => Pesanan(
    id: id ?? this.id,
    pelangganId: pelangganId ?? this.pelangganId,
    namaPelanggan: namaPelanggan ?? this.namaPelanggan,
    tanggalNota: tanggalNota ?? this.tanggalNota,
    jenisPesanan: jenisPesanan ?? this.jenisPesanan,
    rincian: rincian ?? this.rincian,
    ongkosKirim: ongkosKirim ?? this.ongkosKirim,
    pembayaran: pembayaran ?? this.pembayaran,
    dibuatPada: dibuatPada ?? this.dibuatPada,
    diubahPada: diubahPada ?? this.diubahPada,
  );
}
