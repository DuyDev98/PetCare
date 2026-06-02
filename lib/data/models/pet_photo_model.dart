import 'package:cloud_firestore/cloud_firestore.dart';

class PetPhotoModel {
  final String id;
  final String userId;
  final String petId;
  final String petName;
  final String title;
  final String imageUrl;
  final DateTime timestamp;

  const PetPhotoModel({
    required this.id,
    required this.userId,
    required this.petId,
    required this.petName,
    required this.title,
    required this.imageUrl,
    required this.timestamp,
  });

  factory PetPhotoModel.fromMap(Map<String, dynamic> map, String docId) {
    return PetPhotoModel(
      id: docId,
      userId: map['userId'] ?? '',
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
