import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String? type; // reminder, medical, community, etc.

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.type,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: data['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
    };
  }
}
