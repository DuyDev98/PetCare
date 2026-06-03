import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_pet_model.dart';

class LostPetService {
  static final _db  = FirebaseFirestore.instance;
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
      final list = snap.docs
          .map(LostPetPost.fromFirestore)
          .toList();

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
  static Future<void> createPost(LostPetPost post) =>
      _col.add(post.toMap());

  /// Cập nhật trạng thái
  static Future<void> updateStatus(String id, LostPetStatus status) {
    final val = status == LostPetStatus.found
        ? 'found'
        : status == LostPetStatus.injured
        ? 'injured'
        : 'lost';
    return _col.doc(id).update({'status': val});
  }

  /// Xoá bài
  static Future<void> deletePost(String id) => _col.doc(id).delete();
}
