import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PetService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "";
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? "";

  // 1. Lưu thông tin User (Named Parameters)
  Future<void> saveUserInfo({String? role, String? displayName, String? photoURL}) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    try {
      Map<String, dynamic> data = {
        'uid': user.uid,
        'email': user.email,
        'lastLogin': FieldValue.serverTimestamp(),
      };
      if (role != null) data['role'] = role;
      if (displayName != null) data['displayName'] = displayName;
      if (photoURL != null) data['photoURL'] = photoURL;

      await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
    } catch (e) {
      print("[PetService] Lỗi lưu userInfo: $e");
    }
  }

  // 2. Tải ảnh lên Cloudinary
  Future<String?> uploadToCloudinary(File file) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      print("[PetService] Lỗi: Chưa cấu hình Cloudinary trong .env");
      return null;
    }
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
      var request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send().timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = utf8.decode(responseData);
        var json = jsonDecode(responseString);
        return json['secure_url']; 
      }
      return null;
    } catch (e) {
      print("[PetService] Lỗi upload: $e");
      return null;
    }
  }

  // 3. Lấy thông tin User hiện tại
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // 4. Lấy Role
  Future<String?> getUserRole() async {
    final data = await getCurrentUserData();
    return data?['role'] as String?;
  }

  // 5. Kiểm tra hồ sơ thú cưng
  Future<bool> checkUserProfileExists() async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: user.uid)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 6. Lấy danh sách thú cưng
  Future<List<Map<String, dynamic>>> getMyPets() async {
    User? user = _auth.currentUser;
    if (user == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("[PetService] Lỗi lấy danh sách thú cưng: $e");
      QuerySnapshot snapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: user.uid)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    }
  }

  // 7. Tạo hồ sơ thú cưng
  Future<bool> createPetProfile({
    required String name,
    required String age,
    required String type,
    String? imageUrl,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    try {
      await _firestore.collection('pets').add({
        'ownerId': user.uid,
        'name': name,
        'age': age,
        'type': type,
        'avatarUrl': imageUrl ?? '', 
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
