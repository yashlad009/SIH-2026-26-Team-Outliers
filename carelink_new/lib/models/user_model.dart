import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { chw, doctor, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.chw:
        return 'Community Health Worker';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String s) {
    switch (s.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.chw;
    }
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? facilityName;
  final String? facilityId;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.facilityName,
    this.facilityId,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: UserRoleX.fromString(data['role'] as String? ?? 'chw'),
      facilityName: data['facilityName'] as String?,
      facilityId: data['facilityId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'facilityName': facilityName,
        'facilityId': facilityId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? facilityName,
    String? facilityId,
    DateTime? createdAt,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        facilityName: facilityName ?? this.facilityName,
        facilityId: facilityId ?? this.facilityId,
        createdAt: createdAt ?? this.createdAt,
      );
}
