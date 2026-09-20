import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/firestore_paths.dart';
import '../core/services/adaptive_routing_service.dart';
import '../core/services/minimum_trip_service.dart';
import '../core/services/smart_assignment_service.dart';
import '../data/repositories/care_case_repository.dart';
import '../data/repositories/facility_repository.dart';
import '../data/repositories/follow_up_repository.dart';

import '../models/care_case_model.dart';
import '../models/consult_request_model.dart';
import '../models/facility_model.dart';
import '../models/follow_up_task_model.dart';
import '../models/patient_model.dart';
import '../models/triage_result_model.dart';
import '../models/user_model.dart';

final facilityRepositoryProvider = Provider((ref) => FacilityRepository());
final careCaseRepositoryProvider = Provider((ref) => CareCaseRepository());

final allFacilitiesProvider = StreamProvider<List<FacilityModel>>((ref) {
  return ref.watch(facilityRepositoryProvider).watchAllFacilities();
});

final allCareCasesProvider = StreamProvider<List<CareCaseModel>>((ref) {
  return ref.watch(careCaseRepositoryProvider).watchAllCareCases();
});

final careCasesByDoctorProvider =
    StreamProvider.family<List<CareCaseModel>, String>((ref, doctorUid) {
  return ref.watch(careCaseRepositoryProvider).watchCareCasesByDoctor(doctorUid);
});

final careCasesByPatientProvider =
    StreamProvider.family<List<CareCaseModel>, String>((ref, patientId) {
  return ref.watch(careCaseRepositoryProvider).watchCareCasesByPatient(patientId);
});

final careCaseByIdProvider =
    FutureProvider.family<CareCaseModel?, String>((ref, id) async {
  return ref.watch(careCaseRepositoryProvider).getCareCase(id);
});

final careOrchestrationEngineProvider = Provider((ref) {
  return CareOrchestrationEngine();
});

class CareOrchestrationEngine {
  CareOrchestrationEngine();

  /// Orchestrates end-to-end Care Case creation from a CHW Triage event
  Future<CareCaseModel> orchestrateCareCase({
    required PatientModel patient,
    required TriageResultModel triage,
    required String chwUid,
    required String chwName,
  }) async {
    final db = FirebaseFirestore.instance;

    // 1. Identify required specialty
    final requiredSpecialty = SmartAssignmentService.identifyRequiredSpecialty(
      chiefComplaint: triage.chiefComplaint,
      symptoms: triage.symptoms,
      age: patient.age,
      temperature: triage.temperature,
      bpSystolic: triage.bpSystolic,
      bpDiastolic: triage.bpDiastolic,
      spO2: triage.spO2,
      chronicConditions: patient.chronicConditions,
    );

    // 2. Query available doctors
    final usersSnap = await db.collection(FirestorePaths.users).get();
    final users = usersSnap.docs.map(UserModel.fromFirestore).toList();

    // Smart Doctor Assignment
    final assignment = SmartAssignmentService.selectBestDoctor(
      availableDoctors: users,
      requiredSpecialty: requiredSpecialty,
      urgency: triage.riskLevel == RiskLevel.high
          ? UrgencyLevel.emergency
          : triage.riskLevel == RiskLevel.medium
              ? UrgencyLevel.urgent
              : UrgencyLevel.routine,
    );

    // 3. Query seeded facilities & audit Care Readiness
    final facilitiesSnap = await db.collection(FirestorePaths.facilities).get();
    final facilities = facilitiesSnap.docs.map(FacilityModel.fromFirestore).toList();

    // Determine required lab tests & medicines based on symptoms/vitals
    final requiredDiagnostics = <String>[];
    if (triage.symptoms.contains('Chest pain') || (triage.bpSystolic ?? 0) >= 160) {
      requiredDiagnostics.add('ECG');
    }
    if (triage.symptoms.contains('Fever') || triage.symptoms.contains('Cough')) {
      requiredDiagnostics.add('CBC + Blood Sugar');
    }
    if (requiredDiagnostics.isEmpty) {
      requiredDiagnostics.add('Routine Vitals Check');
    }

    final requiredMedicines = <String>[];
    if ((triage.bpSystolic ?? 0) >= 140) {
      requiredMedicines.add('Amlodipine 5mg');
    }
    if (triage.symptoms.contains('Difficulty breathing') || triage.symptoms.contains('Wheezing')) {
      requiredMedicines.add('Salbutamol Inhaler');
    }
    if (triage.symptoms.contains('Fever')) {
      requiredMedicines.add('Paracetamol 500mg');
    }
    if (requiredMedicines.isEmpty) {
      requiredMedicines.add('Essential Medical Kit');
    }

    // 4. Adaptive Care Routing
    final routeRec = AdaptiveRoutingService.computeRecommendedRoute(
      facilities: facilities,
      preferredFacilityName: 'Nashik PHC Ward 3',
      requiredSpecialty: requiredSpecialty,
      requiredDiagnostics: requiredDiagnostics,
      requiredMedicines: requiredMedicines,
    );

    // 5. Minimum-Trip Care Planning
    final tripPlan = MinimumTripService.generatePlan(
      doctorName: assignment.assignedDoctor?.displayName ?? 'District Physician',
      diagnostics: requiredDiagnostics,
      medicines: requiredMedicines,
      facilityName: routeRec.recommendedFacility.name,
    );

    final now = DateTime.now();

    // Construct Care Case
    final careCase = CareCaseModel(
      id: '',
      patientId: patient.id,
      patientName: patient.name,
      patientAge: patient.age,
      patientGender: patient.gender.name,
      village: patient.village,
      chiefComplaint: triage.chiefComplaint,
      symptoms: triage.symptoms,
      vitals: {
        'temperature': triage.temperature,
        'bpSystolic': triage.bpSystolic,
        'bpDiastolic': triage.bpDiastolic,
        'heartRate': triage.heartRate,
        'spO2': triage.spO2,
        'respiratoryRate': triage.respiratoryRate,
      },
      riskLevel: triage.riskLevel,
      riskScore: triage.riskScore,
      riskFlags: triage.riskFlags,
      requiredSpecialty: requiredSpecialty,
      assignedDoctorUid: assignment.assignedDoctor?.uid,
      assignedDoctorName: assignment.assignedDoctor?.displayName,
      assignedDoctorSpecialty: assignment.assignedDoctor?.specialty ?? requiredSpecialty,
      assignmentReason: assignment.assignmentReason,
      destinationFacilityId: routeRec.recommendedFacility.id,
      destinationFacilityName: routeRec.recommendedFacility.name,
      isFacilityCareReady: routeRec.readinessResult.isCareReady,
      facilityReadinessNotes: routeRec.readinessResult.missingReasons.isEmpty
          ? 'All required care available at ${routeRec.recommendedFacility.name}'
          : routeRec.readinessResult.missingReasons.join('; '),
      recommendedRouteReason: routeRec.routingReason,
      minimumTripPlanTitle: tripPlan.title,
      minimumTripServices: tripPlan.bundledServices,
      diagnosticsSummary: requiredDiagnostics,
      medicinesSummary: requiredMedicines,
      status: CareCaseStatus.doctorAssigned,
      createdAt: now,
      updatedAt: now,
    );

    // Save Care Case to Firestore
    final careCaseId = await CareCaseRepository().createCareCase(careCase);

    // 6. Automated Follow-up Task Creation
    final followUpTask = FollowUpTaskModel(
      id: '',
      patientId: patient.id,
      patientName: patient.name,
      assignedToUid: chwUid,
      title: 'Post-Triage Follow-up: ${patient.name}',
      description:
          'Verify patient travel to ${routeRec.recommendedFacility.name} for ${tripPlan.title} with ${assignment.assignedDoctor?.displayName ?? "Doctor"}.',
      category: patient.age < 12 ? FollowUpCategory.child : FollowUpCategory.general,
      dueDate: now.add(const Duration(days: 2)),
      isDone: false,
      createdByUid: chwUid,
      createdAt: now,
    );
    final taskId = await FollowUpRepository().createTask(followUpTask);

    final finalCareCase = careCase.copyWith(
      followUpTaskId: taskId,
      followUpDueDate: followUpTask.dueDate,
    );
    await db
        .collection(FirestorePaths.careCases)
        .doc(careCaseId)
        .update({'followUpTaskId': taskId, 'followUpDueDate': Timestamp.fromDate(followUpTask.dueDate)});

    return finalCareCase;
  }
}
