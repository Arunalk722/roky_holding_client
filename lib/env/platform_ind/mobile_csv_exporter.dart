import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

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
      final fileName = "$fileNamePrefix${DateFormat('yyyyMMdd').format(DateTime.now())}.csv";

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (path == null) return;

      final file = File(path);
      await file.writeAsString(csvData);
      onSuccess();
    } catch (e, st) {
      onError(e, st);
    }
  }
}
