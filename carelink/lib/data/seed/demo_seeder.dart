import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';

class DemoSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Idempotently seeds Demo Doctor (Dr. Vikram Deshmukh) and 2 Patient Consultations (Kavita Jadhav & Mahesh Pawar).
  static Future<void> seedDemoDoctorAndConsults() async {
    final now = DateTime.now();

    // 0. Clean up stale/duplicate doctor records in Firestore users collection
    try {
      final usersSnap = await _db.collection(FirestorePaths.users).get();
      const validDoctorUids = {'demo_doctor_vikram', 'doctor_uid', 'obgyn_doctor_uid'};
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        if (data['role'] == 'doctor' && !validDoctorUids.contains(doc.id)) {
          await doc.reference.delete().catchError((_) {});
        }
      }

      // Reassign any orphaned consult requests (null or stale doctor UIDs) to Dr. Vikram Deshmukh
      final consultsSnap = await _db.collection(FirestorePaths.consultRequests).get();
      for (final doc in consultsSnap.docs) {
        final dUid = doc.data()['doctorUid'] as String?;
        if (dUid == null || dUid.isEmpty || !validDoctorUids.contains(dUid)) {
          await doc.reference.update({
            'doctorUid': 'demo_doctor_vikram',
            'doctorName': 'Dr. Vikram Deshmukh',
          }).catchError((_) {});
        }
      }
    } catch (_) {}

    // 1. Seed Demo Doctor Vikram Deshmukh
    await _db.collection(FirestorePaths.users).doc('demo_doctor_vikram').set({
      'email': 'doctor.vikram@carelink.demo',
      'displayName': 'Dr. Vikram Deshmukh',
      'role': 'doctor',
      'facilityName': 'Nashik Civil Hospital',
      'specialty': 'Pulmonology',
      'isOnDuty': true,
      'activeWorkload': 1,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
    }, SetOptions(merge: true));

    // 2. Seed Doctor Rajesh Patil
    await _db.collection(FirestorePaths.users).doc('doctor_uid').set({
      'email': 'doctor@carelink.demo',
      'displayName': 'Dr. Rajesh Patil',
      'role': 'doctor',
      'facilityName': 'Nashik PHC Ward 3',
      'specialty': 'Cardiology',
      'isOnDuty': true,
      'activeWorkload': 2,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
    }, SetOptions(merge: true));

    // 2b. Seed Doctor Anita Sharma (ObGyn)
    await _db.collection(FirestorePaths.users).doc('obgyn_doctor_uid').set({
      'email': 'obgyn.doc@carelink.demo',
      'displayName': 'Dr. Anita Sharma',
      'role': 'doctor',
      'facilityName': 'Nashik Civil Hospital',
      'specialty': 'Obstetrics & Gynecology',
      'isOnDuty': true,
      'activeWorkload': 1,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
    }, SetOptions(merge: true));

    // 3. Seed Patient 1: Kavita Jadhav
    await _db.collection(FirestorePaths.patients).doc('demo_patient_kavita').set({
      'name': 'Kavita Jadhav',
      'age': 52,
      'gender': 'female',
      'village': 'Igatpuri',
      'district': 'Nashik',
      'contactNumber': '9823456781',
      'bloodGroup': 'O+',
      'chronicConditions': ['Hypertension'],
      'knownAllergies': [],
      'registeredByUid': 'chw_uid',
      'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'lastVisitAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
    }, SetOptions(merge: true));

    // Triage 1
    await _db.collection(FirestorePaths.triageResults).doc('demo_triage_kavita').set({
      'patientId': 'demo_patient_kavita',
      'assessedByUid': 'chw_uid',
      'chiefComplaint': 'Palpitations and dizziness',
      'symptoms': ['Palpitations', 'Dizziness'],
      'temperature': 37.1,
      'bpSystolic': 142,
      'bpDiastolic': 90,
      'heartRate': 108,
      'spO2': 97,
      'respiratoryRate': 18,
      'riskLevel': 'medium',
      'riskScore': 58,
      'riskFlags': ['Tachycardia (HR 108 bpm)', 'Elevated BP (142/90 mmHg)'],
      'aiNote': '52-year-old female presenting with palpitations and tachycardia (108 bpm). Recommended cardiology consultation and ECG.',
      'aiNoteGenerated': true,
      'assessedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
    }, SetOptions(merge: true));

    // Care Case 1
    await _db.collection(FirestorePaths.careCases).doc('demo_case_kavita').set({
      'patientId': 'demo_patient_kavita',
      'patientName': 'Kavita Jadhav',
      'patientAge': 52,
      'patientGender': 'female',
      'village': 'Igatpuri',
      'chiefComplaint': 'Palpitations and dizziness',
      'symptoms': ['Palpitations', 'Dizziness'],
      'vitals': {
        'temperature': 37.1,
        'bpSystolic': 142,
        'bpDiastolic': 90,
        'heartRate': 108,
        'spO2': 97,
      },
      'riskLevel': 'medium',
      'riskScore': 58,
      'riskFlags': ['Tachycardia (HR 108 bpm)', 'Elevated BP (142/90 mmHg)'],
      'isEmergency': false,
      'consultRequestId': 'demo_consult_kavita',
      'isDoctorConsulted': false,
      'requiredSpecialty': 'Cardiology',
      'assignedDoctorUid': 'demo_doctor_vikram',
      'assignedDoctorName': 'Dr. Vikram Deshmukh',
      'assignedDoctorSpecialty': 'Cardiology',
      'assignmentReason': 'Automatically assigned Dr. Vikram Deshmukh — Specialty match (Cardiology), active on-duty status.',
      'destinationFacilityId': 'civil_nashik',
      'destinationFacilityName': 'Nashik Civil Hospital',
      'isFacilityCareReady': true,
      'isRouteConfirmed': false,
      'diagnosticsSummary': ['ECG', 'CBC + Blood Sugar'],
      'medicinesSummary': ['Amlodipine 5mg'],
      'diagnosticsStatus': {'ECG': 'pending', 'CBC + Blood Sugar': 'pending'},
      'medicinesStatus': {'Amlodipine 5mg': 'pending'},
      'status': 'doctorAssigned',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
    }, SetOptions(merge: true));

    // Consult Request 1
    await _db.collection(FirestorePaths.consultRequests).doc('demo_consult_kavita').set({
      'patientId': 'demo_patient_kavita',
      'patientName': 'Kavita Jadhav',
      'chwUid': 'chw_uid',
      'chwName': 'Sunita Kamble (CHW)',
      'doctorUid': 'demo_doctor_vikram',
      'doctorName': 'Dr. Vikram Deshmukh',
      'reason': 'Care Orchestration: Palpitations and dizziness (Cardiology)',
      'urgency': 'urgent',
      'status': 'pending',
      'careCaseId': 'demo_case_kavita',
      'triageResultId': 'demo_triage_kavita',
      'triageRisk': 'medium',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
    }, SetOptions(merge: true));

    // 4. Seed Patient 2: Mahesh Pawar
    await _db.collection(FirestorePaths.patients).doc('demo_patient_mahesh').set({
      'name': 'Mahesh Pawar',
      'age': 61,
      'gender': 'male',
      'village': 'Trimbak',
      'district': 'Nashik',
      'contactNumber': '9812345678',
      'bloodGroup': 'B+',
      'chronicConditions': ['Hypertension', 'Heart disease'],
      'knownAllergies': [],
      'registeredByUid': 'chw_uid',
      'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'lastVisitAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
    }, SetOptions(merge: true));

    // Triage 2
    await _db.collection(FirestorePaths.triageResults).doc('demo_triage_mahesh').set({
      'patientId': 'demo_patient_mahesh',
      'assessedByUid': 'chw_uid',
      'chiefComplaint': 'Chest discomfort and fatigue',
      'symptoms': ['Chest pain', 'Fatigue', 'Shortness of breath'],
      'temperature': 37.4,
      'bpSystolic': 168,
      'bpDiastolic': 104,
      'heartRate': 94,
      'spO2': 95,
      'respiratoryRate': 22,
      'riskLevel': 'high',
      'riskScore': 82,
      'riskFlags': ['Stage 2 Hypertension (168/104 mmHg)', 'Cardiac symptom: chest pain', 'Borderline SpO₂ (95%)'],
      'aiNote': 'High risk: 61-year-old male with history of heart disease presenting with chest discomfort and severe hypertension (168/104 mmHg). Immediate cardiology evaluation required.',
      'aiNoteGenerated': true,
      'assessedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
    }, SetOptions(merge: true));

    // Care Case 2
    await _db.collection(FirestorePaths.careCases).doc('demo_case_mahesh').set({
      'patientId': 'demo_patient_mahesh',
      'patientName': 'Mahesh Pawar',
      'patientAge': 61,
      'patientGender': 'male',
      'village': 'Trimbak',
      'chiefComplaint': 'Chest discomfort and fatigue',
      'symptoms': ['Chest pain', 'Fatigue', 'Shortness of breath'],
      'vitals': {
        'temperature': 37.4,
        'bpSystolic': 168,
        'bpDiastolic': 104,
        'heartRate': 94,
        'spO2': 95,
      },
      'riskLevel': 'high',
      'riskScore': 82,
      'riskFlags': ['Stage 2 Hypertension (168/104 mmHg)', 'Cardiac symptom: chest pain', 'Borderline SpO₂ (95%)'],
      'isEmergency': false,
      'consultRequestId': 'demo_consult_mahesh',
      'isDoctorConsulted': false,
      'requiredSpecialty': 'Cardiology',
      'assignedDoctorUid': 'demo_doctor_vikram',
      'assignedDoctorName': 'Dr. Vikram Deshmukh',
      'assignedDoctorSpecialty': 'Cardiology',
      'assignmentReason': 'Automatically assigned Dr. Vikram Deshmukh — Specialty match (Cardiology), active on-duty status.',
      'destinationFacilityId': 'civil_nashik',
      'destinationFacilityName': 'Nashik Civil Hospital',
      'isFacilityCareReady': true,
      'isRouteConfirmed': false,
      'diagnosticsSummary': ['ECG', 'CBC + Blood Sugar'],
      'medicinesSummary': ['Amlodipine 5mg', 'Salbutamol Inhaler'],
      'diagnosticsStatus': {'ECG': 'pending', 'CBC + Blood Sugar': 'pending'},
      'medicinesStatus': {'Amlodipine 5mg': 'pending', 'Salbutamol Inhaler': 'pending'},
      'status': 'doctorAssigned',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
    }, SetOptions(merge: true));

    // Consult Request 2
    await _db.collection(FirestorePaths.consultRequests).doc('demo_consult_mahesh').set({
      'patientId': 'demo_patient_mahesh',
      'patientName': 'Mahesh Pawar',
      'chwUid': 'chw_uid',
      'chwName': 'Sunita Kamble (CHW)',
      'doctorUid': 'demo_doctor_vikram',
      'doctorName': 'Dr. Vikram Deshmukh',
      'reason': 'Care Orchestration: Chest discomfort and fatigue (Cardiology)',
      'urgency': 'emergency',
      'status': 'pending',
      'careCaseId': 'demo_case_mahesh',
      'triageResultId': 'demo_triage_mahesh',
      'triageRisk': 'high',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
    }, SetOptions(merge: true));
  }
}
