// lib/models/pet_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String id;
  final String ownerId; // Rất quan trọng: Để biết con pet này của ai
  final String name;
  final String age;
  final String type;

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.age,
    required this.type,
  });

  // 1. Chuyển từ Firebase (Map) -> App (Object) để hiển thị lên màn hình
  factory PetModel.fromMap(String documentId, Map<String, dynamic> map) {
    return PetModel(
      id: documentId,
      ownerId: map['ownerId'] ?? '',
      name: map['petName'] ?? '',
      age: map['petAge'] ?? '',
      type: map['petType'] ?? 'dog',
    );
  }

  // 2. Chuyển từ App (Object) -> Firebase (Map) để lưu lên mạng
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'petName': name,
      'petAge': age,
      'petType': type,
      'createdAt': FieldValue.serverTimestamp(), // Tự động lấy giờ hiện tại
    };
  }
}