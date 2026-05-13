import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Pets ──────────────────────────────────────────────────────────────────

  Stream<List<Pet>> petsStream() {
    return _db.collection('pets').orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => Pet.fromFirestore(d)).toList(),
    );
  }

  Future<void> addPet(Pet pet) async {
    await _db.collection('pets').add(pet.toMap());
  }

  // ─── Tasks ─────────────────────────────────────────────────────────────────

  /// Returns tasks for a specific date, optionally filtered by petId.
  Stream<List<PetTask>> tasksStream({
    required DateTime date,
    String? petId,
  }) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    Query query = _db
        .collection('tasks')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .orderBy('time');

    if (petId != null && petId.isNotEmpty) {
      query = query.where('petId', isEqualTo: petId);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map((d) => PetTask.fromFirestore(d)).toList(),
    );
  }

  /// Toggle completion status of a task.
  Future<void> toggleTask(String taskId, bool newValue) async {
    await _db.collection('tasks').doc(taskId).update({'isCompleted': newValue});
  }

  /// Add a new task.
  Future<void> addTask(PetTask task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  /// Delete a task.
  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  // ─── Seed demo data ────────────────────────────────────────────────────────
  /// Call once during development to populate Firestore with sample data.
  Future<void> seedDemoData() async {
    final batch = _db.batch();

    // Pets
    final pets = [
      {'id': 'milo', 'name': 'Milo', 'breed': 'Mèo Cam', 'avatarUrl': ''},
      {
        'id': 'bella',
        'name': 'Bella',
        'breed': 'Golden Retriever',
        'avatarUrl': ''
      },
      {'id': 'coco', 'name': 'Coco', 'breed': 'Mèo Ba Tư', 'avatarUrl': ''},
      {'id': 'max', 'name': 'Max', 'breed': 'Beagle', 'avatarUrl': ''},
    ];

    for (final p in pets) {
      batch.set(_db.collection('pets').doc(p['id']), p);
    }

    // Tasks for today
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final tasks = [
      {
        'title': 'Tắm cho chó Bella',
        'type': 'bath',
        'time': '08:30',
        'petId': 'bella',
        'petName': 'Bella',
        'petBreed': 'Golden Retriever',
        'isCompleted': false,
        'date': Timestamp.fromDate(todayStart.add(const Duration(hours: 8, minutes: 30))),
      },
      {
        'title': 'Tiêm vaccine phòng dại cho Max',
        'type': 'vaccine',
        'time': '10:00',
        'petId': 'max',
        'petName': 'Max',
        'petBreed': 'Beagle',
        'isCompleted': false,
        'date': Timestamp.fromDate(todayStart.add(const Duration(hours: 10))),
      },
      {
        'title': 'Cho Bella ăn trưa',
        'type': 'feed',
        'time': '12:00',
        'petId': 'bella',
        'petName': 'Bella',
        'petBreed': 'Golden Retriever',
        'isCompleted': true,
        'date': Timestamp.fromDate(todayStart.add(const Duration(hours: 12))),
      },
      {
        'title': 'Tắm cho mèo Coco',
        'type': 'bath',
        'time': '15:00',
        'petId': 'coco',
        'petName': 'Coco',
        'petBreed': 'Mèo Ba Tư',
        'isCompleted': true,
        'date': Timestamp.fromDate(todayStart.add(const Duration(hours: 15))),
      },
      {
        'title': 'Cho Milo ăn tối',
        'type': 'feed',
        'time': '18:45',
        'petId': 'milo',
        'petName': 'Milo',
        'petBreed': 'Mèo Cam',
        'isCompleted': false,
        'date': Timestamp.fromDate(todayStart.add(const Duration(hours: 18, minutes: 45))),
      },
      {
        'title': 'Tiêm vaccine mới 3 cho Coco',
        'type': 'vaccine',
        'time': '21:04',
        'petId': 'coco',
        'petName': 'Coco',
        'petBreed': 'Mèo Ba Tư',
        'isCompleted': false,
        'date': Timestamp.fromDate(todayStart.add(const Duration(hours: 21, minutes: 4))),
      },
      {
        'title': 'Cho Max ăn sáng',
        'type': 'feed',
        'time': '07:00',
        'petId': 'max',
        'petName': 'Max',
        'petBreed': 'Beagle',
        'isCompleted': false,
        'date': Timestamp.fromDate(todayStart.add(const Duration(hours: 7))),
      },
      {
        'title': 'Đi dạo cùng Bella',
        'type': 'walk',
        'time': '17:30',
        'petId': 'bella',
        'petName': 'Bella',
        'petBreed': 'Golden Retriever',
        'isCompleted': false,
        'date': Timestamp.fromDate(todayStart.add(const Duration(hours: 17, minutes: 30))),
      },
    ];

    for (final t in tasks) {
      batch.set(_db.collection('tasks').doc(), t);
    }

    await batch.commit();
  }
}