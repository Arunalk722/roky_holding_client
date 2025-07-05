import 'package:intl/intl.dart';

class NumberStyles {
  static String currencyStyle(String value) {
    NumberFormat formatter = NumberFormat('#,###.00', 'en_US');
    return formatter.format(double.tryParse(value) ?? 0);
  }
  static String qtyStyle(String value) {
    NumberFormat formatter = NumberFormat('#,###.000', 'en_US');
    return formatter.format(double.tryParse(value) ?? 0);
  }
}
