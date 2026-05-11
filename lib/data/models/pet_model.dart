// lib/data/models/pet_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String id;
  final String ownerId;       // UID của chủ pet (Firebase Auth)
  final String name;          // Tên pet: "Bella", "Milo"
  final String age;           // Tuổi: "5"
  final String kind;          // Loài: "Mèo", "Chó"
  final String breed;         // Giống cụ thể: "Mèo Ba Tư", "Golden Retriever"
  final String avatarUrl;     // URL ảnh (Cloudinary / Storage)
  final DateTime? createdAt;  // Thời điểm tạo

  const PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.age,
    required this.kind,
    required this.breed,
    required this.avatarUrl,
    this.createdAt,
  });

  // ── Firestore → Object ────────────────────────────────────
  factory PetModel.fromMap(String id, Map<String, dynamic> map) {
    return PetModel(
      id:        id,
      ownerId:   map['ownerId']   ?? '',
      name:      map['name']      ?? '',
      age:       map['age']       ?? '',
      kind:      map['kind']      ?? '',
      breed:     map['breed']     ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // ── Dùng với DocumentSnapshot (dành cho stream/query) ─────
  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    return PetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // ── Object → Firestore ────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'ownerId':   ownerId,
      'name':      name,
      'age':       age,
      'kind':      kind,
      'breed':     breed,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  PetModel copyWith({
    String? name,
    String? age,
    String? kind,
    String? breed,
    String? avatarUrl,
  }) {
    return PetModel(
      id:        id,
      ownerId:   ownerId,
      name:      name      ?? this.name,
      age:       age       ?? this.age,
      kind:      kind      ?? this.kind,
      breed:     breed     ?? this.breed,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}