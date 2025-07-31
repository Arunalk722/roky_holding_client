import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

class MobileCSVExporter {
  static Future<void> export({
    required BuildContext context,
    required List<List<String>> headersAndRows,
    required String fileNamePrefix,
    required VoidCallback onSuccess,
    required void Function(Object e, StackTrace st) onError,
  }) async {
    try {
      final csvData = const ListToCsvConverter().convert(headersAndRows);
      final blob = html.Blob([csvData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "$fileNamePrefix${DateFormat('yyyyMMdd').format(DateTime.now())}.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
      onSuccess();
    } catch (e, st) {
      onError(e, st);
    }
  }
}
