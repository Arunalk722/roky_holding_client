import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

Future<Uint8List?> pickImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );
  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    return file.bytes;
  }
  return null;
}
