class PetModel {
  final String id;
  final String ownerId;
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

  // Chuyển từ Object sang Map để lưu lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'age': age,
      'type': type,
    };
  }

  // Chuyển từ Firebase Map sang Object
  factory PetModel.fromMap(String id, Map<String, dynamic> map) {
    return PetModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? '',
      type: map['type'] ?? '',
    );
  }
}
