import 'package:flutter/services.dart';

import 'format.dart';

/// Memberi titik ribuan saat angka Rupiah diketik, mis. 40000 menjadi
/// 40.000. Nilai dibaca kembali dengan AturanPesanan.bacaRupiah.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final angka = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (angka.isEmpty) return const TextEditingValue();
    if (angka.length > 12) return oldValue;
    final teks = Format.ribuan(int.parse(angka));
    return TextEditingValue(
      text: teks,
      selection: TextSelection.collapsed(offset: teks.length),
    );
  }
}
