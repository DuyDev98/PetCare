import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Pet Model ───────────────────────────────────────────────────────────────

class Pet {
  final String id;
  final String name;
  final String breed;
  final String avatarUrl;

  const Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.avatarUrl,
  });

  factory Pet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'breed': breed,
    'avatarUrl': avatarUrl,
  };
}

// ─── Task Type ────────────────────────────────────────────────────────────────

enum TaskType { bath, vaccine, feed, checkup, walk, other }

extension TaskTypeExtension on TaskType {
  String get label {
    switch (this) {
      case TaskType.bath:
        return 'Tắm';
      case TaskType.vaccine:
        return 'Tiêm vaccine';
      case TaskType.feed:
        return 'Cho ăn';
      case TaskType.checkup:
        return 'Khám bệnh';
      case TaskType.walk:
        return 'Đi dạo';
      case TaskType.other:
        return 'Khác';
    }
  }

  String get firestoreKey {
    switch (this) {
      case TaskType.bath:
        return 'bath';
      case TaskType.vaccine:
        return 'vaccine';
      case TaskType.feed:
        return 'feed';
      case TaskType.checkup:
        return 'checkup';
      case TaskType.walk:
        return 'walk';
      case TaskType.other:
        return 'other';
    }
  }

  static TaskType fromString(String? value) {
    switch (value) {
      case 'bath':
        return TaskType.bath;
      case 'vaccine':
        return TaskType.vaccine;
      case 'feed':
        return TaskType.feed;
      case 'checkup':
        return TaskType.checkup;
      case 'walk':
        return TaskType.walk;
      default:
        return TaskType.other;
    }
  }
}

// ─── Task Model ───────────────────────────────────────────────────────────────

class PetTask {
  final String id;
  final String title;
  final TaskType type;
  final String time; // e.g. "08:30"
  final String petId;
  final String petName;
  final String petBreed;
  final bool isCompleted;
  final DateTime date;

  const PetTask({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.petId,
    required this.petName,
    required this.petBreed,
    required this.isCompleted,
    required this.date,
  });

  factory PetTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetTask(
      id: doc.id,
      title: data['title'] ?? '',
      type: TaskTypeExtension.fromString(data['type']),
      time: data['time'] ?? '',
      petId: data['petId'] ?? '',
      petName: data['petName'] ?? '',
      petBreed: data['petBreed'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type.firestoreKey,
    'time': time,
    'petId': petId,
    'petName': petName,
    'petBreed': petBreed,
    'isCompleted': isCompleted,
    'date': Timestamp.fromDate(date),
  };

  PetTask copyWith({bool? isCompleted}) {
    return PetTask(
      id: id,
      title: title,
      type: type,
      time: time,
      petId: petId,
      petName: petName,
      petBreed: petBreed,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date,
    );
  }
}