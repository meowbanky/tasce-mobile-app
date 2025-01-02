// lib/utils/number_formatter.dart

import 'package:intl/intl.dart';

class NumberFormatter {
  static final _currencyFormatter = NumberFormat("#,##0.00", "en_US");

  // For UI display (with Naira symbol)
  static String formatCurrency(dynamic amount) {
    try {
      final double value = amount is String
          ? double.parse(amount.replaceAll(RegExp(r'[^0-9.]'), ''))
          : (amount ?? 0).toDouble();

      return "₦${_currencyFormatter.format(value)}";
    } catch (e) {
      return "₦0.00";
    }
  }

  // For PDF (with NGN)
  static String formatCurrencyPDF(dynamic amount) {
    try {
      final double value = amount is String
          ? double.parse(amount.replaceAll(RegExp(r'[^0-9.]'), ''))
          : (amount ?? 0).toDouble();

      return "NGN ${_currencyFormatter.format(value)}";
    } catch (e) {
      return "NGN 0.00";
    }
  }

  // For formatting numbers without currency
  static String formatNumber(dynamic number) {
    try {
      final double value = number is String
          ? double.parse(number.replaceAll(RegExp(r'[^0-9.]'), ''))
          : (number ?? 0).toDouble();

      return _currencyFormatter.format(value);
    } catch (e) {
      return "0.00";
    }
  }
}
