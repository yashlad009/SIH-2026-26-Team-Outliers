import 'package:cloud_firestore/cloud_firestore.dart';

enum RiskLevel { low, medium, high }

extension RiskLevelX on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }

  static RiskLevel fromString(String s) {
    switch (s.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }
}

class TriageResultModel {
  final String id;
  final String patientId;
  final String assessedByUid;
  final String chiefComplaint;
  final List<String> symptoms;

  // Vitals snapshot at time of triage
  final double? temperature;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? heartRate;
  final int? spO2;
  final int? respiratoryRate;

  final RiskLevel riskLevel;
  final int riskScore; // 0–100
  final List<String> riskFlags; // human-readable reasons

  // AI-generated note
  final String? aiNote;
  final bool aiNoteGenerated;

  final String? additionalNotes;
  final DateTime assessedAt;

  const TriageResultModel({
    required this.id,
    required this.patientId,
    required this.assessedByUid,
    required this.chiefComplaint,
    this.symptoms = const [],
    this.temperature,
    this.bpSystolic,
    this.bpDiastolic,
    this.heartRate,
    this.spO2,
    this.respiratoryRate,
    required this.riskLevel,
    required this.riskScore,
    this.riskFlags = const [],
    this.aiNote,
    this.aiNoteGenerated = false,
    this.additionalNotes,
    required this.assessedAt,
  });

  factory TriageResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TriageResultModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      assessedByUid: data['assessedByUid'] as String? ?? '',
      chiefComplaint: data['chiefComplaint'] as String? ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      temperature: (data['temperature'] as num?)?.toDouble(),
      bpSystolic: (data['bpSystolic'] as num?)?.toInt(),
      bpDiastolic: (data['bpDiastolic'] as num?)?.toInt(),
      heartRate: (data['heartRate'] as num?)?.toInt(),
      spO2: (data['spO2'] as num?)?.toInt(),
      respiratoryRate: (data['respiratoryRate'] as num?)?.toInt(),
      riskLevel: RiskLevelX.fromString(data['riskLevel'] as String? ?? 'low'),
      riskScore: (data['riskScore'] as num?)?.toInt() ?? 0,
      riskFlags: List<String>.from(data['riskFlags'] ?? []),
      aiNote: data['aiNote'] as String?,
      aiNoteGenerated: data['aiNoteGenerated'] as bool? ?? false,
      additionalNotes: data['additionalNotes'] as String?,
      assessedAt: (data['assessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory TriageResultModel.fromMap(Map<String, dynamic> data, String id) {
    return TriageResultModel(
      id: id,
      patientId: data['patientId'] as String? ?? '',
      assessedByUid: data['assessedByUid'] as String? ?? '',
      chiefComplaint: data['chiefComplaint'] as String? ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      temperature: (data['temperature'] as num?)?.toDouble(),
      bpSystolic: (data['bpSystolic'] as num?)?.toInt(),
      bpDiastolic: (data['bpDiastolic'] as num?)?.toInt(),
      heartRate: (data['heartRate'] as num?)?.toInt(),
      spO2: (data['spO2'] as num?)?.toInt(),
      respiratoryRate: (data['respiratoryRate'] as num?)?.toInt(),
      riskLevel: RiskLevelX.fromString(data['riskLevel'] as String? ?? 'low'),
      riskScore: (data['riskScore'] as num?)?.toInt() ?? 0,
      riskFlags: List<String>.from(data['riskFlags'] ?? []),
      aiNote: data['aiNote'] as String?,
      aiNoteGenerated: data['aiNoteGenerated'] as bool? ?? false,
      additionalNotes: data['additionalNotes'] as String?,
      assessedAt: (data['assessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'assessedByUid': assessedByUid,
        'chiefComplaint': chiefComplaint,
        'symptoms': symptoms,
        'temperature': temperature,
        'bpSystolic': bpSystolic,
        'bpDiastolic': bpDiastolic,
        'heartRate': heartRate,
        'spO2': spO2,
        'respiratoryRate': respiratoryRate,
        'riskLevel': riskLevel.name,
        'riskScore': riskScore,
        'riskFlags': riskFlags,
        'aiNote': aiNote,
        'aiNoteGenerated': aiNoteGenerated,
        'additionalNotes': additionalNotes,
        'assessedAt': Timestamp.fromDate(assessedAt),
      };

  TriageResultModel copyWith({
    String? id,
    String? aiNote,
    bool? aiNoteGenerated,
  }) =>
      TriageResultModel(
        id: id ?? this.id,
        patientId: patientId,
        assessedByUid: assessedByUid,
        chiefComplaint: chiefComplaint,
        symptoms: symptoms,
        temperature: temperature,
        bpSystolic: bpSystolic,
        bpDiastolic: bpDiastolic,
        heartRate: heartRate,
        spO2: spO2,
        respiratoryRate: respiratoryRate,
        riskLevel: riskLevel,
        riskScore: riskScore,
        riskFlags: riskFlags,
        aiNote: aiNote ?? this.aiNote,
        aiNoteGenerated: aiNoteGenerated ?? this.aiNoteGenerated,
        additionalNotes: additionalNotes,
        assessedAt: assessedAt,
      );
}
