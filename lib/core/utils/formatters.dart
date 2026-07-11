import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Money + date formatting helpers used across screens.
class Fmt {
  Fmt._();

  static final NumberFormat _money = NumberFormat('#,###', 'en_US');
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateShort = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy • HH:mm');

  /// The 9-digit national significant number: strips spaces/punctuation and the
  /// country code or trunk '0', so '+255 712 345 678', '255712345678' and
  /// '0712345678' all render as '712345678'. Inputs of 9 or fewer digits are
  /// returned as their digits. Matches the backend's login matching.
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }

  /// e.g. 12450000 -> "TZS 12,450,000"
  static String tzs(num amount) => 'TZS ${_money.format(amount)}';

  /// e.g. 12450000 -> "12,450,000" (no currency prefix)
  static String number(num amount) => _money.format(amount);

  static String date(DateTime d) => _date.format(d);
  static String dateShort(DateTime d) => _dateShort.format(d);

  /// e.g. "07/07/2026 • 14:30" — used where each transaction's exact time
  /// matters (member transaction history).
  static String dateTime(DateTime d) => _dateTime.format(d);

  /// Signed money, used in cashbook / activity rows: "+50,000" / "-5,000"
  static String signed(num amount) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign${_money.format(amount.abs())}';
  }
}

/// Groups an amount field's digits with commas as the user types, so typing
/// "300000" shows "300,000". Strip the separators before parsing, e.g.
/// `text.replaceAll(RegExp('[^0-9]'), '')` (the money screens already do this).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _grp = NumberFormat('#,###', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = _grp.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      // Keep the caret at the end — simplest correct behavior for amount entry.
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Constrains a phone field to a Tanzanian number: a leading '+' (only at the
/// start) plus digits, with the national significant number capped at 9 digits.
/// So the user may type '+255 7XXXXXXXX', '07XXXXXXXX' or a bare '7XXXXXXXX',
/// but never more than 9 digits after the +255/0 prefix. Save it via
/// [Fmt.phone] to store the 9-digit form.
class TzPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Keep only a leading '+' and digits.
    final sb = StringBuffer();
    for (var i = 0; i < newValue.text.length; i++) {
      final c = newValue.text[i];
      if (i == 0 && c == '+') {
        sb.write(c);
      } else if (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
        sb.write(c);
      }
    }
    var text = sb.toString();
    // Max total length keeps the national part at 9 digits, per prefix.
    final int max = text.startsWith('+255')
        ? 13 // +255 + 9
        : text.startsWith('255')
            ? 12 // 255 + 9
            : text.startsWith('0')
                ? 10 // 0 + 9
                : 9; // bare 9 digits
    if (text.length > max) text = text.substring(0, max);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
