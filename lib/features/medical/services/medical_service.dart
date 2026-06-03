import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MedicalService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy stream danh sách hồ sơ y tế của một thú cưng
  Stream<QuerySnapshot> getMedicalRecordsStream(String petId) {
    return _firestore
        .collection('medical_records')
        .where('petId', isEqualTo: petId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Thêm hồ sơ y tế mới
  Future<bool> addMedicalRecord({
    required String petId,
    required String recordType,
    required DateTime date,
    required String title,
    required String clinicName,
    required String note,
    String? imageUrl,
    Map<String, dynamic>? extraData,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    try {
      final data = <String, dynamic>{
        'petId': petId,
        'userId': user.uid,
        'recordType': recordType,
        'date': Timestamp.fromDate(date),
        'title': title,
        'clinicName': clinicName,
        'note': note,
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (extraData != null) data.addAll(extraData);
      await _firestore.collection('medical_records').add(data);
      return true;
    } catch (e) {
      debugPrint("[MedicalService] Loi them ho so y te: $e");
      return false;
    }
  }

  Future<bool> updateMedicalRecord({
    required String recordId,
    required String recordType,
    required DateTime date,
    required String title,
    required String clinicName,
    required String note,
    String? imageUrl,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final data = <String, dynamic>{
        'recordType': recordType,
        'date': Timestamp.fromDate(date),
        'title': title,
        'clinicName': clinicName,
        'note': note,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (extraData != null) data.addAll(extraData);
      await _firestore.collection('medical_records').doc(recordId).update(data);
      return true;
    } catch (e) {
      debugPrint("[MedicalService] Loi cap nhat ho so y te: $e");
      return false;
    }
  }

  // Xóa hồ sơ y tế
  Future<bool> deleteMedicalRecord(String recordId) async {
    try {
      await _firestore.collection('medical_records').doc(recordId).delete();
      return true;
    } catch (e) {
      debugPrint("[MedicalService] Lỗi xóa hồ sơ y tế: $e");
      return false;
    }
  }
}
