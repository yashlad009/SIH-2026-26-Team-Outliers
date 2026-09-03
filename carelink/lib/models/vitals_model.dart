import 'package:cloud_firestore/cloud_firestore.dart';

class VitalsModel {
  final String id;
  final String patientId;
  final String recordedByUid;
  final double? temperature; // °C
  final int? bpSystolic; // mmHg
  final int? bpDiastolic; // mmHg
  final int? heartRate; // bpm
  final int? spO2; // %
  final int? respiratoryRate; // /min
  final double? weight; // kg
  final double? height; // cm
  final double? bmi; // computed
  final String? notes;
  final DateTime recordedAt;

  const VitalsModel({
    required this.id,
    required this.patientId,
    required this.recordedByUid,
    this.temperature,
    this.bpSystolic,
    this.bpDiastolic,
    this.heartRate,
    this.spO2,
    this.respiratoryRate,
    this.weight,
    this.height,
    this.bmi,
    this.notes,
    required this.recordedAt,
  });

  factory VitalsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VitalsModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      recordedByUid: data['recordedByUid'] as String? ?? '',
      temperature: (data['temperature'] as num?)?.toDouble(),
      bpSystolic: (data['bpSystolic'] as num?)?.toInt(),
      bpDiastolic: (data['bpDiastolic'] as num?)?.toInt(),
      heartRate: (data['heartRate'] as num?)?.toInt(),
      spO2: (data['spO2'] as num?)?.toInt(),
      respiratoryRate: (data['respiratoryRate'] as num?)?.toInt(),
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      bmi: (data['bmi'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory VitalsModel.fromMap(Map<String, dynamic> data, String id) {
    return VitalsModel(
      id: id,
      patientId: data['patientId'] as String? ?? '',
      recordedByUid: data['recordedByUid'] as String? ?? '',
      temperature: (data['temperature'] as num?)?.toDouble(),
      bpSystolic: (data['bpSystolic'] as num?)?.toInt(),
      bpDiastolic: (data['bpDiastolic'] as num?)?.toInt(),
      heartRate: (data['heartRate'] as num?)?.toInt(),
      spO2: (data['spO2'] as num?)?.toInt(),
      respiratoryRate: (data['respiratoryRate'] as num?)?.toInt(),
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      bmi: (data['bmi'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'recordedByUid': recordedByUid,
        'temperature': temperature,
        'bpSystolic': bpSystolic,
        'bpDiastolic': bpDiastolic,
        'heartRate': heartRate,
        'spO2': spO2,
        'respiratoryRate': respiratoryRate,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'notes': notes,
        'recordedAt': Timestamp.fromDate(recordedAt),
      };

  String get bpDisplay {
    if (bpSystolic != null && bpDiastolic != null) {
      return '$bpSystolic/$bpDiastolic mmHg';
    }
    return '—';
  }

  String get tempDisplay => temperature != null ? '${temperature!.toStringAsFixed(1)} °C' : '—';
  String get spO2Display => spO2 != null ? '$spO2%' : '—';
  String get hrDisplay => heartRate != null ? '$heartRate bpm' : '—';
  String get bmiDisplay => bmi != null ? bmi!.toStringAsFixed(1) : '—';
}
