// lib/data/services/reminder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_care/data/services/local_notification_service.dart';
import 'package:pet_care/data/services/notification_service.dart';
import 'package:pet_care/features/calendar/models/reminder_model.dart';
import 'package:pet_care/services/home_widget_service.dart';

class ReminderService {
  final CollectionReference _db = FirebaseFirestore.instance.collection('reminders');
  final _localNotificationService = LocalNotificationService();
  final _notificationService = NotificationService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Tạo nhắc nhở đơn (không lặp) ────────────────────────
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
    final docRef = await _db.add({
      'userId':      _uid,
      'title':       title,
      'timestamp':   Timestamp.fromDate(dateTime),
      'type':        type.firestoreKey,
      'notes':       notes,
      'status':      status,
      'petId':       petId,
      'petName':     petName,
      'petBreed':    petBreed,
      'imageUrl':    imageUrl,
      'repeatType':  'none',
      'repeatDays':  [],
      'repeatUntil': null,
      'parentId':    null,
    });

    // Cập nhật Home Screen Widget
    await HomeWidgetService.refreshWidget();

    // Schedule local notification
    await _localNotificationService.scheduleNotification(
      id: docRef.id.hashCode,
      title: 'Nhắc nhở: $title',
      body: 'Đã đến giờ chăm sóc $petName rồi!',
      scheduledDate: dateTime,
    );

    // Add to in-app notification history
    await _notificationService.addNotification(
      title: 'Đã tạo nhắc nhở: $title',
      content: 'Nhắc nhở cho $petName vào ${dateTime.hour}:${dateTime.minute} ngày ${dateTime.day}/${dateTime.month}',
      type: 'reminder',
    );
  }

  // ── Tạo nhắc nhở lặp lại ─────────────────────────────────
  Future<void> createRepeatingReminder({
    required String title,
    required DateTime startDateTime,
    required ReminderType type,
    required String petId,
    required String petName,
    required String petBreed,
    required RepeatType repeatType,
    required DateTime repeatUntil,
    List<int> repeatDays = const [],
    String notes = '',
    String? imageUrl,
  }) async {
    // 1. Tạo template document
    final templateRef = await _db.add({
      'userId':      _uid,
      'title':       title,
      'timestamp':   Timestamp.fromDate(startDateTime),
      'type':        type.firestoreKey,
      'notes':       notes,
      'status':      'pending',
      'petId':       petId,
      'petName':     petName,
      'petBreed':    petBreed,
      'imageUrl':    imageUrl,
      'repeatType':  repeatType.key,
      'repeatDays':  repeatDays,
      'repeatUntil': Timestamp.fromDate(repeatUntil),
      'parentId':    null,
    });

    // 2. Tính tất cả ngày cần tạo instance
    final dates = _generateDates(
      start:       startDateTime,
      until:       repeatUntil,
      repeatType:  repeatType,
      repeatDays:  repeatDays,
    );

    // 3. Batch write tất cả instances
    final batch = FirebaseFirestore.instance.batch();
    for (final date in dates) {
      final instanceRef = _db.doc();
      batch.set(instanceRef, {
        'userId':      _uid,
        'title':       title,
        'timestamp':   Timestamp.fromDate(date),
        'type':        type.firestoreKey,
        'notes':       notes,
        'status':      'pending',
        'petId':       petId,
        'petName':     petName,
        'petBreed':    petBreed,
        'imageUrl':    imageUrl,
        'repeatType':  repeatType.key,
        'repeatDays':  repeatDays,
        'repeatUntil': Timestamp.fromDate(repeatUntil),
        'parentId':    templateRef.id,
      });

      // Schedule local notification for each instance
      await _localNotificationService.scheduleNotification(
        id: instanceRef.id.hashCode,
        title: 'Nhắc nhở lặp lại: $title',
        body: 'Đã đến giờ chăm sóc $petName rồi!',
        scheduledDate: date,
      );
    }
    await batch.commit();

    // Cập nhật Home Screen Widget
    await HomeWidgetService.refreshWidget();

    // Add to in-app notification history
    await _notificationService.addNotification(
      title: 'Đã tạo nhắc nhở lặp lại: $title',
      content: 'Nhắc nhở $repeatType.key cho $petName',
      type: 'reminder',
    );
  }

  List<DateTime> _generateDates({
    required DateTime start,
    required DateTime until,
    required RepeatType repeatType,
    required List<int> repeatDays,
  }) {
    final dates = <DateTime>[];
    final hour  = start.hour;
    final min   = start.minute;

    switch (repeatType) {
      case RepeatType.daily:
        var current = start;
        while (!current.isAfter(until)) {
          dates.add(DateTime(current.year, current.month, current.day, hour, min));
          current = current.add(const Duration(days: 1));
        }
        break;

      case RepeatType.weekly:
        var current = start;
        while (!current.isAfter(until)) {
          dates.add(DateTime(current.year, current.month, current.day, hour, min));
          current = current.add(const Duration(days: 7));
        }
        break;

      case RepeatType.custom:
        var current = start;
        while (!current.isAfter(until)) {
          if (repeatDays.contains(current.weekday)) {
            dates.add(DateTime(current.year, current.month, current.day, hour, min));
          }
          current = current.add(const Duration(days: 1));
        }
        break;

      default:
        break;
    }
    return dates;
  }

  // ── Lấy danh sách theo ngày ───────────────────────────────
  Stream<List<ReminderModel>> getRemindersByDate(DateTime date, {String? petId}) {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);

    Query query = _db
        .where('userId',    isEqualTo: _uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp');

    return query.snapshots().map((snap) => snap.docs
        .map((d) => ReminderModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .where((r) => !r.isTemplate)
        .where((r) => petId == null || petId.isEmpty || r.petId == petId)
        .toList());
  }

  // ── Lấy danh sách quá hạn ────────────────────────────────
  Stream<List<ReminderModel>> getOverdueReminders() {
    return _db
        .where('userId',    isEqualTo: _uid)
        .where('status',    isEqualTo: 'pending')
        .where('timestamp', isLessThan: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ReminderModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .where((r) => !r.isTemplate)
        .toList());
  }

  // ── Toggle done / pending ─────────────────────────────────
  Future<void> toggleReminder(String docId, bool isDone) async {
    await _db.doc(docId).update({'status': isDone ? 'done' : 'pending'});
    await HomeWidgetService.refreshWidget();
  }

  // ── Reschedule ────────────────────────────────────────────
  Future<void> reschedule(String docId, DateTime newTime) async {
    await _db.doc(docId).update({
      'timestamp': Timestamp.fromDate(newTime),
      'status':    'pending',
    });
    await HomeWidgetService.refreshWidget();
  }

  Future<void> deleteReminder(String docId) async {
    await _db.doc(docId).delete();
    await HomeWidgetService.refreshWidget();
  }
}
