import 'package:cloud_firestore/cloud_firestore.dart';

class FacilityModel {
  final String id;
  final String name;
  final String tier; // 'Primary', 'Secondary', 'Tertiary'
  final bool isOperational;
  final List<String> availableSpecialties;
  final List<String> availableDiagnostics;
  final List<String> availableMedicines;
  final int bedCapacity;
  final int occupiedBeds;
  final String district;
  final String? contactPhone;

  const FacilityModel({
    required this.id,
    required this.name,
    required this.tier,
    this.isOperational = true,
    this.availableSpecialties = const [],
    this.availableDiagnostics = const [],
    this.availableMedicines = const [],
    this.bedCapacity = 20,
    this.occupiedBeds = 5,
    this.district = 'Nashik',
    this.contactPhone,
  });

  bool get hasBedAvailable => occupiedBeds < bedCapacity;
  int get availableBeds => bedCapacity - occupiedBeds;

  factory FacilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FacilityModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Facility',
      tier: data['tier'] as String? ?? 'Primary',
      isOperational: data['isOperational'] as bool? ?? true,
      availableSpecialties: (data['availableSpecialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availableDiagnostics: (data['availableDiagnostics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availableMedicines: (data['availableMedicines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      bedCapacity: (data['bedCapacity'] as num?)?.toInt() ?? 20,
      occupiedBeds: (data['occupiedBeds'] as num?)?.toInt() ?? 5,
      district: data['district'] as String? ?? 'Nashik',
      contactPhone: data['contactPhone'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'tier': tier,
        'isOperational': isOperational,
        'availableSpecialties': availableSpecialties,
        'availableDiagnostics': availableDiagnostics,
        'availableMedicines': availableMedicines,
        'bedCapacity': bedCapacity,
        'occupiedBeds': occupiedBeds,
        'district': district,
        'contactPhone': contactPhone,
      };
}
