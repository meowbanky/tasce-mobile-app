// lib/utils/extensions.dart

import 'number_formatter.dart';

extension NumberFormatting on num {
  String toCurrency() {
    return NumberFormatter.formatCurrency(this);
  }

  String toFormattedString() {
    return NumberFormatter.formatNumber(this);
  }
}

extension StringFormatting on String {
  String toCurrency() {
    return NumberFormatter.formatCurrency(this);
  }

  String toFormattedNumber() {
    return NumberFormatter.formatNumber(this);
  }
}
