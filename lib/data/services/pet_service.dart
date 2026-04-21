import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Lưu thông tin User vào Firestore (QUAN TRỌNG)
  Future<void> saveUserInfo(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge: true để không ghi đè dữ liệu cũ nếu đã có
      print("[PetService] Đã lưu UID: ${user.uid} lên Firestore");
    } catch (e) {
      print("[PetService] Lỗi lưu userInfo: $e");
    }
  }

  // 2. Kiểm tra xem người dùng đã tạo hồ sơ thú cưng chưa?
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
      print("[PetService] Lỗi kiểm tra profile: $e");
      return false;
    }
  }

  // 3. Tạo mới hồ sơ thú cưng
  Future<bool> createPetProfile({
    required String name,
    required String age,
    required String type,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      final newPet = {
        'ownerId': user.uid,
        'name': name,
        'age': age,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('pets').add(newPet);
      return true;
    } catch (e) {
      print("[PetService] Lỗi tạo profile: $e");
      return false;
    }
  }
}
