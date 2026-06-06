import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet_photo_model.dart';

class PetPhotoService {
  final CollectionReference _db = FirebaseFirestore.instance.collection(
    'pet_photos',
  );

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> addPetPhoto({
    required String petId,
    required String petName,
    required String title,
    required String imageUrl,
    required DateTime timestamp,
  }) async {
    await _db.add({
      'userId': _uid,
      'petId': petId,
      'petName': petName,
      'title': title,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PetPhotoModel>> getPhotosByDate(DateTime date, {String? petId}) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    Query query = _db
        .where('userId', isEqualTo: _uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true);

    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) =>
                PetPhotoModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .where(
            (photo) => petId == null || petId.isEmpty || photo.petId == petId,
          )
          .toList(),
    );
  }

  Future<void> deletePetPhoto(String photoId) async {
    if (photoId.isEmpty) return;

    await _db.doc(photoId).delete();
  }

  /// Lấy stream tất cả ảnh của user hiện tại (Dùng timestamp để ổn định hơn createdAt)
  Stream<List<PetPhotoModel>> getUserPhotosStream() {
    return _db
        .where('userId', isEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PetPhotoModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Lấy stream ảnh của riêng một thú cưng
  Stream<List<PetPhotoModel>> getPhotosByPet(String petId) {
    return _db
        .where('userId', isEqualTo: _uid)
        .where('petId', isEqualTo: petId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PetPhotoModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Xóa document ảnh trên Firestore
  Future<void> deletePetPhoto(String docId) async {
    await _db.doc(docId).delete();
  }
}
