// lib/data/models/reminder_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String userId; // - Dùng chung định dạng uid
  final String title;
  final DateTime timestamp;
  final String type;
  final String notes;
  final String status;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.timestamp,
    required this.type,
    required this.notes,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'notes': notes,
      'status': status,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReminderModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: map['type'] ?? 'other',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}