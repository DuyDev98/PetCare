import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType { bath, vaccine, feed, checkup, walk, other }

class ReminderModel {
  final String id;
  final String title;
  final DateTime timestamp;
  final ReminderType type;
  final String? imageUrl; // Trường lưu ảnh kỷ niệm
  final bool isCompleted;

  ReminderModel({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.type,
    this.imageUrl,
    this.isCompleted = false,
  });

  factory ReminderModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReminderModel(
      id: docId,
      title: map['title'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ReminderType.other,
      ),
      imageUrl: map['imageUrl'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'imageUrl': imageUrl,
      'isCompleted': isCompleted,
    };
  }
}
