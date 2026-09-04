import 'package:cloud_firestore/cloud_firestore.dart';
import 'triage_result_model.dart';

enum Gender { male, female, other }

extension GenderX on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  static Gender fromString(String s) {
    switch (s.toLowerCase()) {
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      default:
        return Gender.male;
    }
  }
}

class PatientModel {
  final String id;
  final String name;
  final int age;
  final Gender gender;
  final String village;
  final String district;
  final String? contactNumber;
  final String? abhaId;
  final String? bloodGroup;
  final List<String> knownAllergies;
  final List<String> chronicConditions;
  final String registeredByUid; // CHW who registered
  final String? assignedDoctorUid;
  final DateTime registeredAt;
  final DateTime? lastVisitAt;
  final RiskLevel? triageRisk;
  final bool isPendingSync;

  const PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.village,
    required this.district,
    this.contactNumber,
    this.abhaId,
    this.bloodGroup,
    this.knownAllergies = const [],
    this.chronicConditions = const [],
    required this.registeredByUid,
    this.assignedDoctorUid,
    required this.registeredAt,
    this.lastVisitAt,
    this.triageRisk,
    this.isPendingSync = false,
  });

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: GenderX.fromString(data['gender'] as String? ?? 'male'),
      village: data['village'] as String? ?? '',
      district: data['district'] as String? ?? '',
      contactNumber: data['contactNumber'] as String?,
      abhaId: data['abhaId'] as String?,
      bloodGroup: data['bloodGroup'] as String?,
      knownAllergies: List<String>.from(data['knownAllergies'] ?? []),
      chronicConditions: List<String>.from(data['chronicConditions'] ?? []),
      registeredByUid: data['registeredByUid'] as String? ?? '',
      assignedDoctorUid: data['assignedDoctorUid'] as String?,
      registeredAt: (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastVisitAt: (data['lastVisitAt'] as Timestamp?)?.toDate(),
      triageRisk: data['triageRisk'] != null
          ? RiskLevelX.fromString(data['triageRisk'] as String)
          : null,
      isPendingSync: doc.metadata.hasPendingWrites,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'age': age,
        'gender': gender.name,
        'village': village,
        'district': district,
        'contactNumber': contactNumber,
        'abhaId': abhaId,
        'bloodGroup': bloodGroup,
        'knownAllergies': knownAllergies,
        'chronicConditions': chronicConditions,
        'registeredByUid': registeredByUid,
        'assignedDoctorUid': assignedDoctorUid,
        'registeredAt': Timestamp.fromDate(registeredAt),
        'lastVisitAt': lastVisitAt != null ? Timestamp.fromDate(lastVisitAt!) : null,
        if (triageRisk != null) 'triageRisk': triageRisk!.name,
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    Gender? gender,
    String? village,
    String? district,
    String? contactNumber,
    String? abhaId,
    String? bloodGroup,
    List<String>? knownAllergies,
    List<String>? chronicConditions,
    String? registeredByUid,
    String? assignedDoctorUid,
    DateTime? registeredAt,
    DateTime? lastVisitAt,
    RiskLevel? triageRisk,
    bool? isPendingSync,
  }) =>
      PatientModel(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        village: village ?? this.village,
        district: district ?? this.district,
        contactNumber: contactNumber ?? this.contactNumber,
        abhaId: abhaId ?? this.abhaId,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        knownAllergies: knownAllergies ?? this.knownAllergies,
        chronicConditions: chronicConditions ?? this.chronicConditions,
        registeredByUid: registeredByUid ?? this.registeredByUid,
        assignedDoctorUid: assignedDoctorUid ?? this.assignedDoctorUid,
        registeredAt: registeredAt ?? this.registeredAt,
        lastVisitAt: lastVisitAt ?? this.lastVisitAt,
        triageRisk: triageRisk ?? this.triageRisk,
        isPendingSync: isPendingSync ?? this.isPendingSync,
      );
}

