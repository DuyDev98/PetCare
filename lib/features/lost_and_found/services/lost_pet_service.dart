import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_pet_model.dart';

class LostPetService {
  static final _db = FirebaseFirestore.instance;
  static final _col = _db.collection('lost_pets');

  /// Stream toàn bộ bài đăng (lọc theo status nếu có)
  static Stream<List<LostPetPost>> postsStream({LostPetStatus? filter}) {
    Query q = _col;
    if (filter != null) {
      final val = filter == LostPetStatus.found
          ? 'found'
          : filter == LostPetStatus.injured
          ? 'injured'
          : 'lost';
      q = q.where('status', isEqualTo: val);
    }
    return q.snapshots().map((snap) {
      final list = snap.docs.map(LostPetPost.fromFirestore).toList();

      list.sort((a, b) {
        // Ưu tiên bài khẩn cấp lên trên
        if (a.isUrgent && !b.isUrgent) return -1;
        if (!a.isUrgent && b.isUrgent) return 1;
        // Cùng mức khẩn cấp → mới nhất lên trên
        return b.createdAt.compareTo(a.createdAt);
      });

      return list;
    });
  }

  /// Đăng bài tìm thất lạc
  static Future<void> createPost(LostPetPost post) => _col.add(post.toMap());

  static Stream<LostPetPost?> postStream(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return LostPetPost.fromFirestore(doc);
    });
  }

  /// Cập nhật trạng thái
  static Future<void> updateStatus(String id, LostPetStatus status) {
    final val = status == LostPetStatus.found
        ? 'found'
        : status == LostPetStatus.injured
        ? 'injured'
        : 'lost';
    return _col.doc(id).update({'status': val});
  }

  /// Cập nhật thông tin bài đăng
  static Future<void> updatePost(
    String id, {
    required String name,
    required String kind,
    required String breed,
    required String description,
    required double weight,
    required String locationName,
    required String phone,
    required LostPetStatus status,
    required bool isUrgent,
  }) {
    final val = status == LostPetStatus.found
        ? 'found'
        : status == LostPetStatus.injured
        ? 'injured'
        : 'lost';
    return _col.doc(id).update({
      'name': name,
      'kind': kind,
      'breed': breed,
      'description': description,
      'weight': weight,
      'locationName': locationName,
      'phone': phone,
      'status': val,
      'isUrgent': isUrgent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Đóng/Mở bài đăng
  static Future<void> setClosed(String id, bool isClosed) {
    return _col.doc(id).update({
      'isClosed': isClosed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Báo cáo bài đăng
  static Future<void> reportPost({
    required LostPetPost post,
    required String reason,
    required String reporterId,
  }) {
    return _db.collection('lost_pet_reports').add({
      'postId': post.id,
      'postOwnerId': post.userId,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'postName': post.name,
      'postPhone': post.phone,
    });
  }

  /// Xoá bài
  static Future<void> deletePost(String id) => _col.doc(id).delete();
}
