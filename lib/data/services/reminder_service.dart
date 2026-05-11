import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final CollectionReference _db = FirebaseFirestore.instance.collection('reminders');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> createReminder({
    required String title,
    required DateTime dateTime,
    required ReminderType type,
    required String petId,
    required String petName,
    required String petBreed,
    String notes = '',
    String status = 'pending',
    String? imageUrl,
  }) async {
    await _db.add({
      'userId': _uid,
      'title': title,
      'timestamp': Timestamp.fromDate(dateTime),
      'type': type.firestoreKey,
      'notes': notes,
      'status': status,
      'petId': petId,
      'petName': petName,
      'petBreed': petBreed,
      'imageUrl': imageUrl,
    });
  }

  Stream<List<ReminderModel>> getRemindersByDate(DateTime date, {String? petId}) {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    Query query = _db
        .where('userId', isEqualTo: _uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp');

    if (petId != null && petId.isNotEmpty) {
      query = query.where('petId', isEqualTo: petId);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => ReminderModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  Future<void> toggleReminder(String docId, bool isDone) async {
    await _db.doc(docId).update({
      'status': isDone ? 'done' : 'pending',
    });
  }

  Future<void> deleteReminder(String docId) async {
    await _db.doc(docId).delete();
  }
}
