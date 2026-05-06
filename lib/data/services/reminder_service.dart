// lib/data/services/reminder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final CollectionReference _db =
  FirebaseFirestore.instance.collection('reminders');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Tạo nhắc nhở mới ─────────────────────────────────────
  Future<void> createReminder({
    required String title,
    required DateTime dateTime,
    required ReminderType type,
    required String petId,
    required String petName,
    required String petBreed,
    String notes  = '',
    String status = 'pending',
  }) async {
    await _db.add({
      'userId':    _uid,
      'title':     title,
      'timestamp': Timestamp.fromDate(dateTime),
      'type':      type.firestoreKey,
      'notes':     notes,
      'status':    status,
      'petId':     petId,
      'petName':   petName,
      'petBreed':  petBreed,
    });
  }

  // ── Lấy danh sách theo ngày, tuỳ chọn lọc theo pet ───────
  Stream<List<ReminderModel>> getRemindersByDate(
      DateTime date, {
        String? petId,
      }) {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);

    Query query = _db
        .where('userId',    isEqualTo: _uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo:    Timestamp.fromDate(end))
        .orderBy('timestamp');

    if (petId != null && petId.isNotEmpty) {
      query = query.where('petId', isEqualTo: petId);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => ReminderModel.fromMap(
        d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ── Lấy danh sách quá hạn ────────────────────────────────
  Stream<List<ReminderModel>> getOverdueReminders() {
    return _db
        .where('userId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .where('timestamp', isLessThan: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ReminderModel.fromMap(
        d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ── Toggle done / pending ─────────────────────────────────
  Future<void> toggleReminder(String docId, bool isDone) async {
    await _db.doc(docId).update({
      'status': isDone ? 'done' : 'pending',
    });
  }

  // ── Reschedule ────────────────────────────────────────────
  Future<void> reschedule(String docId, DateTime newTime) async {
    await _db.doc(docId).update({
      'timestamp': Timestamp.fromDate(newTime),
      'status':    'pending',
    });
  }

  // ── Xoá ──────────────────────────────────────────────────
  Future<void> deleteReminder(String docId) async {
    await _db.doc(docId).delete();
  }
}