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

  /// Xóa ảnh trên Cloudinary bằng Public ID
  /// (Yêu cầu API Key và Secret để gọi Admin API hoặc dùng logic Backend)
  /// Dưới đây là logic mẫu nếu bạn có credentials
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // 1. Trích xuất public_id từ URL
      // URL ví dụ: https://res.cloudinary.com/cloud_name/image/upload/v1234567/public_id.jpg
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) return false;

      // Public ID thường là phần cuối cùng bỏ đuôi file
      final fileName = pathSegments.last;
      final publicId = fileName.split('.').first;

      debugPrint("[CloudinaryService] Attempting to delete publicId: $publicId");

      // Lưu ý: Cloudinary yêu cầu Signature cho yêu cầu xóa
      // Thông thường việc xóa nên thực hiện ở Backend để bảo mật API Secret.
      // Nếu làm ở App, bạn cần điền API Key/Secret vào .env

      // return await _callDeleteApi(publicId);

      return true; // Tạm thời trả về true để Firestore có thể xóa tiếp
    } catch (e) {
      debugPrint("[CloudinaryService] Error deleting image: $e");
      return false;
    }
  }
}
