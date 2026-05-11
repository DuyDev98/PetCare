import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType { bath, vaccine, feed, checkup, walk, other }

extension ReminderTypeExtension on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.bath:     return 'Tắm';
      case ReminderType.vaccine:  return 'Tiêm vaccine';
      case ReminderType.feed:     return 'Cho ăn';
      case ReminderType.checkup:  return 'Khám bệnh';
      case ReminderType.walk:     return 'Đi dạo';
      default:                    return 'Khác';
    }
  }

  String get firestoreKey {
    switch (this) {
      case ReminderType.bath:     return 'bath';
      case ReminderType.vaccine:  return 'vaccine';
      case ReminderType.feed:     return 'feed';
      case ReminderType.checkup:  return 'checkup';
      case ReminderType.walk:     return 'walk';
      default:                    return 'other';
    }
  }

  static ReminderType fromString(String? value) {
    switch (value) {
      case 'bath':    return ReminderType.bath;
      case 'vaccine': return ReminderType.vaccine;
      case 'feed':    return ReminderType.feed;
      case 'checkup': return ReminderType.checkup;
      case 'walk':    return ReminderType.walk;
      default:        return ReminderType.other;
    }
  }
}

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final DateTime timestamp;
  final ReminderType type;
  final String notes;
  final String status; // 'pending' | 'done'
  final String petId;
  final String petName;
  final String petBreed;
  final String? imageUrl;

  bool get isCompleted => status == 'done';

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.timestamp,
    required this.type,
    required this.notes,
    required this.status,
    required this.petId,
    required this.petName,
    required this.petBreed,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId':    userId,
      'title':     title,
      'timestamp': Timestamp.fromDate(timestamp),
      'type':      type.firestoreKey,
      'notes':     notes,
      'status':    status,
      'petId':     petId,
      'petName':   petName,
      'petBreed':  petBreed,
      'imageUrl':  imageUrl,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReminderModel(
      id:        docId,
      userId:    map['userId']   ?? '',
      title:     map['title']    ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type:      ReminderTypeExtension.fromString(map['type']),
      notes:     map['notes']    ?? '',
      status:    map['status']   ?? 'pending',
      petId:     map['petId']    ?? '',
      petName:   map['petName']  ?? '',
      petBreed:  map['petBreed'] ?? '',
      imageUrl:  map['imageUrl'],
    );
  }
}
