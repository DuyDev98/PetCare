import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "";
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? "";

  Future<String?> uploadImage(File file) async {
    // Debug logging to verify variables are loaded
    debugPrint("[CloudinaryService] Attempting upload with:");
    debugPrint(" - Cloud Name: ${_cloudName.isNotEmpty ? _cloudName : 'MISSING'}");
    debugPrint(" - Upload Preset: ${_uploadPreset.isNotEmpty ? _uploadPreset : 'MISSING'}");

    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      debugPrint("[CloudinaryService] ERROR: Missing configuration in .env. Please check CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.");
      return null;
    }

    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
      var request = http.MultipartRequest("POST", url);

      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      debugPrint("[CloudinaryService] Sending request to: $url");
      var response = await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = await response.stream.toBytes();
        var responseString = utf8.decode(responseData);
        var json = jsonDecode(responseString);
        debugPrint("[CloudinaryService] Upload SUCCESS: ${json['secure_url']}");
        return json['secure_url'];
      } else {
        var responseData = await response.stream.toBytes();
        var errorResponse = utf8.decode(responseData);
        debugPrint("[CloudinaryService] Upload FAILED with status ${response.statusCode}");
        debugPrint("[CloudinaryService] Error details: $errorResponse");
        return null;
      }
    } catch (e) {
      debugPrint("[CloudinaryService] Exception during upload: $e");
      return null;
    }
  }
}
