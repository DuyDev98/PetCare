// lib/data/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── User ──────────────────────────────────────────────────

  /// Lưu / cập nhật thông tin user sau khi đăng nhập
  Future<void> saveUserInfo(User user) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        'uid':         user.uid,
        'email':       user.email,
        'displayName': user.displayName ?? '',
        'photoURL':    user.photoURL    ?? '',
        'lastLogin':   FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('[FirebaseService] Lỗi lưu userInfo: $e');
    }
  }

  // ── Pets ──────────────────────────────────────────────────

  /// Stream danh sách pet của user hiện tại
  Stream<List<PetModel>> petsStream() {
    return _db
        .collection('pets')
        .where('ownerId', isEqualTo: _uid)
        .orderBy('name')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => PetModel.fromFirestore(d)).toList());
  }

  /// Kiểm tra user đã có pet chưa (dùng cho onboarding)
  Future<bool> checkUserProfileExists() async {
    if (_uid.isEmpty) return false;
    try {
      final snap = await _db
          .collection('pets')
          .where('ownerId', isEqualTo: _uid)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      print('[FirebaseService] Lỗi kiểm tra profile: $e');
      return false;
    }
  }

  /// Tạo pet mới từ form onboarding
  Future<bool> createPetProfile({
    required String name,
    required String age,
    required String kind,   // ✅ "kind" thay vì "type"
    required String breed,
    String avatarUrl = '',
  }) async {
    if (_uid.isEmpty) return false;
    try {
      await _db.collection('pets').add({
        'ownerId':   _uid,
        'name':      name,
        'age':       age,
        'kind':      kind,
        'breed':     breed,
        'avatarUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('[FirebaseService] Lỗi tạo pet: $e');
      return false;
    }
  }

  /// Thêm pet từ PetModel đầy đủ
  Future<void> addPet(PetModel pet) async {
    await _db.collection('pets').add(pet.toMap());
  }

  /// Cập nhật pet
  Future<void> updatePet(PetModel pet) async {
    await _db.collection('pets').doc(pet.id).update(pet.toMap());
  }

  /// Xoá pet
  Future<void> deletePet(String petId) async {
    await _db.collection('pets').doc(petId).delete();
  }
}