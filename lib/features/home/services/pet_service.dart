// lib/features/home/services/pet_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Logic kiểm tra: Người dùng đã có hồ sơ thú cưng chưa?
  Future<bool> checkUserProfileExists() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Tìm xem trong Database có tài liệu nào mang tên UID của người dùng này không
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print("Lỗi kiểm tra profile: $e");
      return false;
    }
  }

  // 2. Logic tạo mới: Lưu thông tin thú cưng lên Database
  Future<bool> createPetProfile({
    required String name,
    required String age,
    required String type,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Tạo một Document mới với ID là UID của người dùng
      await _firestore.collection('users').doc(user.uid).set({
        'petName': name,
        'petAge': age,
        'petType': type,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true; // Lưu thành công
    } catch (e) {
      print("Lỗi tạo profile: $e");
      return false; // Lưu thất bại
    }
  }
}