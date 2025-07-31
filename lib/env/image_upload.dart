import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'api_info.dart';
import 'app_logs_to.dart';
import 'print_debug.dart';
import 'platform_ind/image_picker_mobile.dart' if (dart.library.html) 'image_picker_web.dart';

class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({super.key});

  @override
  State<ImageUploadPage> createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  String? imageUrl;
  Uint8List? _byteData;
  Future<void> startFilePicker() async {
    final pickedBytes = await pickImage();
    if (pickedBytes != null) {
      setState(() {
        _byteData = pickedBytes;
      });
    }
  }
  Future<void> _uploadImage() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );

      String? token = APIToken().token;
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No API token found.'), backgroundColor: Colors.red),
        );
        return;
      }
      var uri = Uri.parse("${APIHost().apiURL}/payment_request_management.php/ImageUpload");
      PD.pd(text: uri.toString());
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        _byteData!,
        filename: 'image.png',
        contentType: MediaType('image', 'png'),
      ));

      request.fields['Authorization'] = token;
      request.fields['EndPoint'] = 'endPoint';
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseBody);
      PD.pd(text: "Server Response: $decodedResponse");

      if (response.statusCode == 200) {
        if (decodedResponse['status'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${decodedResponse['message'] ?? 'Unexpected response format.'}'), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}, Response: $responseBody'), backgroundColor: Colors.red),
        );
      }
    } catch (e,st) {
      ExceptionLogger.logToError(message: e.toString(),errorLog: st.toString(), logFile: 'image_upload.dart');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload Example'),
      ),
      body:
      Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: startFilePicker,
                child: const Text('Pick Image'),
              ),
              SizedBox(height: 20),
              if (_byteData != null)
                Image.memory(
                  _byteData!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage, // Only enable upload if image is selected
                child: const Text('Upload Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
