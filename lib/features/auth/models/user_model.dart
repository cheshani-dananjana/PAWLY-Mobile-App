import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String accountStatus;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.role = 'user',
    this.accountStatus = 'active',
    required this.createdAt,
  });

  // Convert Firebase Document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      accountStatus: map['account_status'] ?? 'active',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert UserModel to Map for Firebase writing
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'role': role,
      'account_status': accountStatus,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
