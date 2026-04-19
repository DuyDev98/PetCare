// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String userName;

  UserModel({
    required this.uid,
    required this.email,
    required this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'userName': userName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}