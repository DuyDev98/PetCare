import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Lấy stream danh sách thông báo ───────────────────────
  Stream<List<NotificationModel>> getNotificationsStream() {
    if (_uid.isEmpty) return Stream.value([]);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  // ── Đếm số thông báo chưa đọc ────────────────────────────
  Stream<int> getUnreadCountStream() {
    if (_uid.isEmpty) return Stream.value(0);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── Thêm thông báo mới ────────────────────────────────────
  Future<void> addNotification({
    required String title,
    required String content,
    String? type,
  }) async {
    if (_uid.isEmpty) return;
    await _db.collection('notifications').add({
      'userId': _uid,
      'title': title,
      'content': content,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'type': type,
    });
  }

  // ── Đánh dấu tất cả là đã đọc ─────────────────────────────
  Future<void> markAllAsRead() async {
    if (_uid.isEmpty) return;
    final batch = _db.batch();
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Đánh dấu một thông báo là đã đọc ──────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }
}
