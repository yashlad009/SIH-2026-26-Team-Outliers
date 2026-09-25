import 'package:cloud_firestore/cloud_firestore.dart';
import 'triage_result_model.dart';

enum CareCaseStatus {
  triaged,
  doctorAssigned,
  carePlanned,
  routed,
  inProgress,
  completed,
}

extension CareCaseStatusX on CareCaseStatus {
  String get label {
    switch (this) {
      case CareCaseStatus.triaged:
        return 'Triaged';
      case CareCaseStatus.doctorAssigned:
        return 'Doctor Assigned';
      case CareCaseStatus.carePlanned:
        return 'Care Planned';
      case CareCaseStatus.routed:
        return 'Route Confirmed';
      case CareCaseStatus.inProgress:
        return 'Care In Progress';
      case CareCaseStatus.completed:
        return 'Care Completed';
    }
  }

  static CareCaseStatus fromString(String s) {
    switch (s.toLowerCase().replaceAll(' ', '')) {
      case 'doctorassigned':
      case 'doctor_assigned':
        return CareCaseStatus.doctorAssigned;
      case 'careplanned':
      case 'care_planned':
        return CareCaseStatus.carePlanned;
      case 'routed':
      case 'routeconfirmed':
        return CareCaseStatus.routed;
      case 'inprogress':
      case 'in_progress':
        return CareCaseStatus.inProgress;
      case 'completed':
        return CareCaseStatus.completed;
      default:
        return CareCaseStatus.triaged;
    }
  }
}

class CareCaseModel {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String village;
  final String chiefComplaint;
  final List<String> symptoms;
  final Map<String, dynamic> vitals;
  final RiskLevel riskLevel;
  final int riskScore;
  final List<String> riskFlags;

  // Emergency Escalation
  final bool isEmergency;
  final String? emergencyReason;

  // Doctor Consultation & Decision Link
  final String? consultRequestId;
  final bool isDoctorConsulted;
  final String? doctorClinicalNote;

  // Action Items Tracking
  final Map<String, String> diagnosticsStatus; // testName -> 'pending' | 'completed'
  final Map<String, String> medicinesStatus;   // medicineName -> 'pending' | 'dispensed'

  // Smart Assignment
  final String? requiredSpecialty;
  final String? assignedDoctorUid;
  final String? assignedDoctorName;
  final String? assignedDoctorSpecialty;
  final String? assignmentReason;

  // Care Readiness & Routing
  final String? destinationFacilityId;
  final String? destinationFacilityName;
  final bool isFacilityCareReady;
  final String? facilityReadinessNotes;
  final String? recommendedRouteReason;

  // Minimum-trip care planning
  final String? minimumTripPlanTitle;
  final List<String> minimumTripServices;

  // Referral link
  final String? referralId;
  final String? referralStatus;

  // Clinical items
  final List<String> diagnosticsSummary;
  final List<String> medicinesSummary;

  // Follow-up
  final String? followUpTaskId;
  final DateTime? followUpDueDate;
  final bool isFollowUpDone;

  // Status & timestamps
  final CareCaseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CareCaseModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.village,
    required this.chiefComplaint,
    this.symptoms = const [],
    this.vitals = const {},
    required this.riskLevel,
    required this.riskScore,
    this.riskFlags = const [],
    this.isEmergency = false,
    this.emergencyReason,
    this.consultRequestId,
    this.isDoctorConsulted = false,
    this.doctorClinicalNote,
    this.diagnosticsStatus = const {},
    this.medicinesStatus = const {},
    this.requiredSpecialty,
    this.assignedDoctorUid,
    this.assignedDoctorName,
    this.assignedDoctorSpecialty,
    this.assignmentReason,
    this.destinationFacilityId,
    this.destinationFacilityName,
    this.isFacilityCareReady = false,
    this.facilityReadinessNotes,
    this.recommendedRouteReason,
    this.minimumTripPlanTitle,
    this.minimumTripServices = const [],
    this.referralId,
    this.referralStatus,
    this.diagnosticsSummary = const [],
    this.medicinesSummary = const [],
    this.followUpTaskId,
    this.followUpDueDate,
    this.isFollowUpDone = false,
    this.status = CareCaseStatus.triaged,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CareCaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CareCaseModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      patientAge: (data['patientAge'] as num?)?.toInt() ?? 0,
      patientGender: data['patientGender'] as String? ?? '',
      village: data['village'] as String? ?? '',
      chiefComplaint: data['chiefComplaint'] as String? ?? '',
      symptoms: (data['symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vitals: (data['vitals'] as Map<String, dynamic>?) ?? {},
      riskLevel: RiskLevelX.fromString(data['riskLevel'] as String? ?? 'low'),
      riskScore: (data['riskScore'] as num?)?.toInt() ?? 0,
      riskFlags: (data['riskFlags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isEmergency: data['isEmergency'] as bool? ?? false,
      emergencyReason: data['emergencyReason'] as String?,
      consultRequestId: data['consultRequestId'] as String?,
      isDoctorConsulted: data['isDoctorConsulted'] as bool? ?? false,
      doctorClinicalNote: data['doctorClinicalNote'] as String?,
      diagnosticsStatus: (data['diagnosticsStatus'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      medicinesStatus: (data['medicinesStatus'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      requiredSpecialty: data['requiredSpecialty'] as String?,
      assignedDoctorUid: data['assignedDoctorUid'] as String?,
      assignedDoctorName: data['assignedDoctorName'] as String?,
      assignedDoctorSpecialty: data['assignedDoctorSpecialty'] as String?,
      assignmentReason: data['assignmentReason'] as String?,
      destinationFacilityId: data['destinationFacilityId'] as String?,
      destinationFacilityName: data['destinationFacilityName'] as String?,
      isFacilityCareReady: data['isFacilityCareReady'] as bool? ?? false,
      facilityReadinessNotes: data['facilityReadinessNotes'] as String?,
      recommendedRouteReason: data['recommendedRouteReason'] as String?,
      minimumTripPlanTitle: data['minimumTripPlanTitle'] as String?,
      minimumTripServices: (data['minimumTripServices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      referralId: data['referralId'] as String?,
      referralStatus: data['referralStatus'] as String?,
      diagnosticsSummary: (data['diagnosticsSummary'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      medicinesSummary: (data['medicinesSummary'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      followUpTaskId: data['followUpTaskId'] as String?,
      followUpDueDate: (data['followUpDueDate'] as Timestamp?)?.toDate(),
      isFollowUpDone: data['isFollowUpDone'] as bool? ?? false,
      status: CareCaseStatusX.fromString(data['status'] as String? ?? 'triaged'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'village': village,
        'chiefComplaint': chiefComplaint,
        'symptoms': symptoms,
        'vitals': vitals,
        'riskLevel': riskLevel.name,
        'riskScore': riskScore,
        'riskFlags': riskFlags,
        'isEmergency': isEmergency,
        'emergencyReason': emergencyReason,
        'consultRequestId': consultRequestId,
        'isDoctorConsulted': isDoctorConsulted,
        'doctorClinicalNote': doctorClinicalNote,
        'diagnosticsStatus': diagnosticsStatus,
        'medicinesStatus': medicinesStatus,
        'requiredSpecialty': requiredSpecialty,
        'assignedDoctorUid': assignedDoctorUid,
        'assignedDoctorName': assignedDoctorName,
        'assignedDoctorSpecialty': assignedDoctorSpecialty,
        'assignmentReason': assignmentReason,
        'destinationFacilityId': destinationFacilityId,
        'destinationFacilityName': destinationFacilityName,
        'isFacilityCareReady': isFacilityCareReady,
        'facilityReadinessNotes': facilityReadinessNotes,
        'recommendedRouteReason': recommendedRouteReason,
        'minimumTripPlanTitle': minimumTripPlanTitle,
        'minimumTripServices': minimumTripServices,
        'referralId': referralId,
        'referralStatus': referralStatus,
        'diagnosticsSummary': diagnosticsSummary,
        'medicinesSummary': medicinesSummary,
        'followUpTaskId': followUpTaskId,
        'followUpDueDate':
            followUpDueDate != null ? Timestamp.fromDate(followUpDueDate!) : null,
        'isFollowUpDone': isFollowUpDone,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  CareCaseModel copyWith({
    bool? isEmergency,
    String? emergencyReason,
    String? consultRequestId,
    bool? isDoctorConsulted,
    String? doctorClinicalNote,
    Map<String, String>? diagnosticsStatus,
    Map<String, String>? medicinesStatus,
    String? requiredSpecialty,
    String? assignedDoctorUid,
    String? assignedDoctorName,
    String? assignedDoctorSpecialty,
    String? assignmentReason,
    String? destinationFacilityId,
    String? destinationFacilityName,
    bool? isFacilityCareReady,
    String? facilityReadinessNotes,
    String? recommendedRouteReason,
    String? minimumTripPlanTitle,
    List<String>? minimumTripServices,
    String? referralId,
    String? referralStatus,
    List<String>? diagnosticsSummary,
    List<String>? medicinesSummary,
    String? followUpTaskId,
    DateTime? followUpDueDate,
    bool? isFollowUpDone,
    CareCaseStatus? status,
    DateTime? updatedAt,
  }) =>
      CareCaseModel(
        id: id,
        patientId: patientId,
        patientName: patientName,
        patientAge: patientAge,
        patientGender: patientGender,
        village: village,
        chiefComplaint: chiefComplaint,
        symptoms: symptoms,
        vitals: vitals,
        riskLevel: riskLevel,
        riskScore: riskScore,
        riskFlags: riskFlags,
        isEmergency: isEmergency ?? this.isEmergency,
        emergencyReason: emergencyReason ?? this.emergencyReason,
        consultRequestId: consultRequestId ?? this.consultRequestId,
        isDoctorConsulted: isDoctorConsulted ?? this.isDoctorConsulted,
        doctorClinicalNote: doctorClinicalNote ?? this.doctorClinicalNote,
        diagnosticsStatus: diagnosticsStatus ?? this.diagnosticsStatus,
        medicinesStatus: medicinesStatus ?? this.medicinesStatus,
        requiredSpecialty: requiredSpecialty ?? this.requiredSpecialty,
        assignedDoctorUid: assignedDoctorUid ?? this.assignedDoctorUid,
        assignedDoctorName: assignedDoctorName ?? this.assignedDoctorName,
        assignedDoctorSpecialty:
            assignedDoctorSpecialty ?? this.assignedDoctorSpecialty,
        assignmentReason: assignmentReason ?? this.assignmentReason,
        destinationFacilityId:
            destinationFacilityId ?? this.destinationFacilityId,
        destinationFacilityName:
            destinationFacilityName ?? this.destinationFacilityName,
        isFacilityCareReady: isFacilityCareReady ?? this.isFacilityCareReady,
        facilityReadinessNotes:
            facilityReadinessNotes ?? this.facilityReadinessNotes,
        recommendedRouteReason:
            recommendedRouteReason ?? this.recommendedRouteReason,
        minimumTripPlanTitle: minimumTripPlanTitle ?? this.minimumTripPlanTitle,
        minimumTripServices: minimumTripServices ?? this.minimumTripServices,
        referralId: referralId ?? this.referralId,
        referralStatus: referralStatus ?? this.referralStatus,
        diagnosticsSummary: diagnosticsSummary ?? this.diagnosticsSummary,
        medicinesSummary: medicinesSummary ?? this.medicinesSummary,
        followUpTaskId: followUpTaskId ?? this.followUpTaskId,
        followUpDueDate: followUpDueDate ?? this.followUpDueDate,
        isFollowUpDone: isFollowUpDone ?? this.isFollowUpDone,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
