import 'package:cloud_firestore/cloud_firestore.dart';

enum LostPetStatus { lost, found, injured }

class LostPetPost {
  final String id;
  final String userId;
  final String name;
  final String kind;   // 'Chó' | 'Mèo' | 'Khác: ...'
  final String breed;
  final String description;
  final double weight;
  final String imageUrl;
  final LostPetStatus status;
  final bool isUrgent;
  final GeoPoint location;
  final String locationName; // tên khu vực hiển thị
  final String phone;
  final DateTime createdAt;

  const LostPetPost({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    required this.breed,
    required this.description,
    required this.weight,
    required this.imageUrl,
    required this.status,
    required this.isUrgent,
    required this.location,
    required this.locationName,
    required this.phone,
    required this.createdAt,
  });

  factory LostPetPost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LostPetPost(
      id:           doc.id,
      userId:       d['userId']       ?? '',
      name:         d['name']         ?? '',
      kind:         d['kind']         ?? '',
      breed:        d['breed']        ?? '',
      description:  d['description']  ?? '',
      weight:       (d['weight'] as num?)?.toDouble() ?? 0,
      imageUrl:     d['imageUrl']     ?? '',
      status:       d['status'] == 'found'
          ? LostPetStatus.found
          : d['status'] == 'injured'
          ? LostPetStatus.injured
          : LostPetStatus.lost,
      isUrgent:     d['isUrgent']     ?? false,
      location:     d['location']     as GeoPoint? ?? const GeoPoint(0, 0),
      locationName: d['locationName'] ?? '',
      phone:        d['phone']        ?? '',
      createdAt:    (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId':       userId,
    'name':         name,
    'kind':         kind,
    'breed':        breed,
    'description':  description,
    'weight':       weight,
    'imageUrl':     imageUrl,
    'status':       status == LostPetStatus.found
        ? 'found'
        : status == LostPetStatus.injured
        ? 'injured'
        : 'lost',
    'isUrgent':     isUrgent,
    'location':     location,
    'locationName': locationName,
    'phone':        phone,
    'createdAt':    FieldValue.serverTimestamp(),
  };
}
