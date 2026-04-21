import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Lưu thông tin User
  Future<void> saveUserInfo(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("[PetService] Lỗi lưu userInfo: $e");
    }
  }

  // 2. Lấy thông tin User hiện tại từ Firestore
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

  // 3. Lấy danh sách thú cưng của User hiện tại
  Future<List<Map<String, dynamic>>> getMyPets() async {
    User? user = _auth.currentUser;
    if (user == null) return [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: user.uid)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  // 4. Kiểm tra profile tồn tại
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

  // 5. Tạo mới hồ sơ thú cưng
  Future<bool> createPetProfile({
    required String name,
    required String age,
    required String type,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    try {
      await _firestore.collection('pets').add({
        'ownerId': user.uid,
        'name': name,
        'age': age,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
