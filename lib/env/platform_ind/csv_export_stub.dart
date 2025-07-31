import 'package:flutter/material.dart';

class MobileCSVExporter {
  static Future<void> export({
    required BuildContext context,
    required List<List<String>> headersAndRows,
    required String fileNamePrefix,
    required VoidCallback onSuccess,
    required void Function(Object e, StackTrace st) onError,
  }) async {
    onError(UnsupportedError("Platform not supported for CSV export."), StackTrace.current);
  }
}
