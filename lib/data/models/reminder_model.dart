// lib/data/models/reminder_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Repeat Type ───────────────────────────────────────────

enum RepeatType { none, daily, weekly, custom }

extension RepeatTypeExtension on RepeatType {
  String get label {
    switch (this) {
      case RepeatType.none:   return 'Không lặp';
      case RepeatType.daily:  return 'Hằng ngày';
      case RepeatType.weekly: return 'Hằng tuần';
      case RepeatType.custom: return 'Tuỳ chọn';
    }
  }

  String get key {
    switch (this) {
      case RepeatType.none:   return 'none';
      case RepeatType.daily:  return 'daily';
      case RepeatType.weekly: return 'weekly';
      case RepeatType.custom: return 'custom';
    }
  }

  static RepeatType fromString(String? v) {
    switch (v) {
      case 'daily':  return RepeatType.daily;
      case 'weekly': return RepeatType.weekly;
      case 'custom': return RepeatType.custom;
      default:       return RepeatType.none;
    }
  }
}

// Ngày trong tuần: 1=T2 ... 7=CN (theo DateTime.weekday)
const Map<int, String> weekdayLabels = {
  1: 'T2', 2: 'T3', 3: 'T4',
  4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN',
};

// ── Reminder Type ─────────────────────────────────────────

enum ReminderType { bath, vaccine, feed, checkup, walk, other }

extension ReminderTypeExtension on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.bath:     return 'Tắm';
      case ReminderType.vaccine:  return 'Tiêm vaccine';
      case ReminderType.feed:     return 'Cho ăn';
      case ReminderType.checkup:  return 'Khám bệnh';
      case ReminderType.walk:     return 'Đi dạo';
      case ReminderType.other:    return 'Khác';
    }
  }

  String get firestoreKey {
    switch (this) {
      case ReminderType.bath:     return 'bath';
      case ReminderType.vaccine:  return 'vaccine';
      case ReminderType.feed:     return 'feed';
      case ReminderType.checkup:  return 'checkup';
      case ReminderType.walk:     return 'walk';
      case ReminderType.other:    return 'other';
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

// ── Reminder Model ────────────────────────────────────────

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

  // Repeat fields
  final RepeatType repeatType;
  final List<int> repeatDays;   // [1,3,5] = T2,T4,T6 (custom)
  final DateTime? repeatUntil;  // ngày kết thúc
  final String? parentId;       // null = template, có = instance

  bool get isCompleted => status == 'done';
  bool get isTemplate  => parentId == null && repeatType != RepeatType.none;
  bool get isInstance  => parentId != null;

  const ReminderModel({
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
    this.repeatType  = RepeatType.none,
    this.repeatDays  = const [],
    this.repeatUntil,
    this.parentId,
  });

  Map<String, dynamic> toMap() => {
    'userId':      userId,
    'title':       title,
    'timestamp':   Timestamp.fromDate(timestamp),
    'type':        type.firestoreKey,
    'notes':       notes,
    'status':      status,
    'petId':       petId,
    'petName':     petName,
    'petBreed':    petBreed,
    'imageUrl':    imageUrl,
    'repeatType':  repeatType.key,
    'repeatDays':  repeatDays,
    'repeatUntil': repeatUntil != null ? Timestamp.fromDate(repeatUntil!) : null,
    'parentId':    parentId,
  };

  factory ReminderModel.fromMap(Map<String, dynamic> map, String docId) =>
      ReminderModel(
        id:          docId,
        userId:      map['userId']    ?? '',
        title:       map['title']     ?? '',
        timestamp:   (map['timestamp'] as Timestamp).toDate(),
        type:        ReminderTypeExtension.fromString(map['type']),
        notes:       map['notes']     ?? '',
        status:      map['status']    ?? 'pending',
        petId:       map['petId']     ?? '',
        petName:     map['petName']   ?? '',
        petBreed:    map['petBreed']  ?? '',
        imageUrl:    map['imageUrl'],
        repeatType:  RepeatTypeExtension.fromString(map['repeatType']),
        repeatDays:  List<int>.from(map['repeatDays'] ?? []),
        repeatUntil: (map['repeatUntil'] as Timestamp?)?.toDate(),
        parentId:    map['parentId'],
      );

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) =>
      ReminderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  ReminderModel copyWith({String? status, DateTime? timestamp, String? imageUrl}) => ReminderModel(
    id:          id,
    userId:      userId,
    title:       title,
    timestamp:   timestamp ?? this.timestamp,
    type:        type,
    notes:       notes,
    status:      status ?? this.status,
    petId:       petId,
    petName:     petName,
    petBreed:    petBreed,
    imageUrl:    imageUrl ?? this.imageUrl,
    repeatType:  repeatType,
    repeatDays:  repeatDays,
    repeatUntil: repeatUntil,
    parentId:    parentId,
  );
}
