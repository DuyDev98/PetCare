import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/pet_photo_model.dart';

class PhotoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Trả về Stream danh sách ảnh của user, sắp xếp mới nhất lên đầu
  Stream<List<PetPhotoModel>> getPhotoStream({required String userId}) {
    return _db
        .collection('pet_photos')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PetPhotoModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Xóa vĩnh viễn document của bức ảnh trên Firestore
  Future<void> deletePhoto(String docId) async {
    try {
      // Comment tiếng Việt: Thực hiện lệnh xóa document trên Firestore
      await _db.collection('pet_photos').doc(docId).delete();
    } catch (e) {
      print('Lỗi khi xóa ảnh trên Firestore: $e');
      rethrow;
    }
  }
}
