// lib/data/services/reminder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final CollectionReference _db = FirebaseFirestore.instance.collection('reminders');

  // Lấy UID của người dùng từ FirebaseAuth
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // LOGIC TRANG 2: THÊM NHẮC NHỞ
  Future<void> createReminder({
    required String title,
    required DateTime dateTime,
    required String type,
    String? notes,
    String? status, // Thêm dòng này
  }) async {
    await _db.add({
      'userId': _uid, // Gắn ID người dùng để bảo mật
      'title': title,
      'timestamp': Timestamp.fromDate(dateTime),
      'type': type,
      'notes': notes ?? '',
      'status': status ?? 'pending',
    });
  }

  // LOGIC TRANG 1: LẤY DANH SÁCH THEO NGÀY (Sửa lỗi named arguments)
  Stream<List<ReminderModel>> getRemindersByDate(DateTime date) {
    DateTime start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .where('userId', isEqualTo: _uid) // Sửa: Dùng isEqualTo thay vì '=='
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => ReminderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // LOGIC TRANG 3: LẤY DANH SÁCH QUÁ HẠN (Sửa lỗi positional arguments)
  Stream<List<ReminderModel>> getOverdueReminders() {
    return _db
        .where('userId', isEqualTo: _uid) // Sửa: isEqualTo
        .where('status', isEqualTo: 'pending') // Sửa: isEqualTo
        .where('timestamp', isLessThan: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => ReminderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // LOGIC NÚT RESCHEDULE: CẬP NHẬT GIỜ MỚI
  Future<void> reschedule(String docId, DateTime newTime) async {
    await _db.doc(docId).update({
      'timestamp': Timestamp.fromDate(newTime),
      'status': 'pending',
    });
  }
}