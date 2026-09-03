// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/patient_model.dart';
import '../../models/triage_result_model.dart';
import '../../models/consult_request_model.dart';
import '../../models/referral_model.dart';
import '../../models/medicine_stock_model.dart';
import '../../models/diagnostic_test_model.dart';
import '../../models/follow_up_task_model.dart';
import '../../models/user_model.dart';
import '../../core/constants/firestore_paths.dart';

/// Run this once to populate demo Firestore data.
/// Called from a special seed button in settings or from main() with a flag.
class SeedData {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ── Demo Accounts ──────────────────────────────────────────────────────────
  static const _demoAccounts = [
    {
      'email': 'chw@carelink.demo',
      'password': 'demo1234',
      'displayName': 'Sunita Kamble (CHW)',
      'role': 'chw',
      'facilityName': 'Nashik PHC Ward 3',
    },
    {
      'email': 'doctor@carelink.demo',
      'password': 'demo1234',
      'displayName': 'Dr. Rajesh Patil',
      'role': 'doctor',
      'facilityName': 'Nashik PHC Ward 3',
    },
    {
      'email': 'admin@carelink.demo',
      'password': 'demo1234',
      'displayName': 'Priya Deshmukh (Admin)',
      'role': 'admin',
      'facilityName': 'Nashik District Health Office',
    },
  ];

  static Future<void> runSeed() async {
    print('🌱 Starting CareLink seed...');

    final uids = <String, String>{}; // role → uid

    // 1. Create auth users + Firestore profiles
    for (final acc in _demoAccounts) {
      try {
        UserCredential cred;
        try {
          cred = await _auth.createUserWithEmailAndPassword(
            email: acc['email']!,
            password: acc['password']!,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            cred = await _auth.signInWithEmailAndPassword(
              email: acc['email']!,
              password: acc['password']!,
            );
          } else {
            rethrow;
          }
        }
        final uid = cred.user!.uid;
        uids[acc['role']!] = uid;

        await _db.doc(FirestorePaths.userDoc(uid)).set({
          'email': acc['email'],
          'displayName': acc['displayName'],
          'role': acc['role'],
          'facilityName': acc['facilityName'],
          'createdAt': Timestamp.now(),
        }, SetOptions(merge: true));

        print('✅ User: ${acc['email']}');
      } catch (e) {
        print('⚠️  User ${acc['email']}: $e');
      }
    }

    final chwUid = uids['chw'] ?? 'chw_uid';
    final doctorUid = uids['doctor'] ?? 'doctor_uid';

    // 2. Seed patients
    final patients = _buildPatients(chwUid);
    final patientIds = <String>[];
    for (final p in patients) {
      try {
        final ref = await _db.collection(FirestorePaths.patients).add(p);
        patientIds.add(ref.id);
        print('✅ Patient: ${p['name']}');
      } catch (e) {
        print('⚠️  Patient ${p['name']}: $e');
      }
    }

    if (patientIds.length < 6) {
      print('⚠️  Not enough patient IDs for seeding. Aborting.');
      return;
    }

    // 3. Seed triage results
    await _seedTriage(patientIds, chwUid);

    // 4. Seed consult requests
    await _seedConsults(patientIds, chwUid, doctorUid);

    // 5. Seed referrals
    await _seedReferrals(patientIds, doctorUid);

    // 6. Seed medicine stock
    await _seedMedicineStock();

    // 7. Seed diagnostic tests
    await _seedDiagnosticTests(patientIds, doctorUid);

    // 8. Seed follow-up tasks
    await _seedFollowUpTasks(patientIds, chwUid);

    print('🎉 Seed complete!');
  }

  // ── Patients ───────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _buildPatients(String chwUid) {
    final now = DateTime.now();
    return [
      {
        'name': 'Anita Bhalerao',
        'age': 28,
        'gender': 'female',
        'village': 'Dindori',
        'district': 'Nashik',
        'contactNumber': '9876543210',
        'bloodGroup': 'B+',
        'chronicConditions': ['Gestational diabetes'],
        'knownAllergies': [],
        'registeredByUid': chwUid,
        'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 45))),
        'lastVisitAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'name': 'Ramesh Shinde',
        'age': 62,
        'gender': 'male',
        'village': 'Igatpuri',
        'district': 'Nashik',
        'contactNumber': '9765432109',
        'bloodGroup': 'O+',
        'chronicConditions': ['Hypertension', 'Type 2 Diabetes'],
        'knownAllergies': ['Penicillin'],
        'registeredByUid': chwUid,
        'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 90))),
        'lastVisitAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'name': 'Kavita Jadhav',
        'age': 8,
        'gender': 'female',
        'village': 'Trimbakeshwar',
        'district': 'Nashik',
        'contactNumber': '9654321098',
        'bloodGroup': 'A+',
        'chronicConditions': [],
        'knownAllergies': [],
        'registeredByUid': chwUid,
        'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
        'lastVisitAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
      {
        'name': 'Suresh Mane',
        'age': 45,
        'gender': 'male',
        'village': 'Niphad',
        'district': 'Nashik',
        'contactNumber': '9543210987',
        'bloodGroup': 'AB+',
        'chronicConditions': ['COPD'],
        'knownAllergies': [],
        'registeredByUid': chwUid,
        'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
        'lastVisitAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'name': 'Lata Pawar',
        'age': 35,
        'gender': 'female',
        'village': 'Yeola',
        'district': 'Nashik',
        'contactNumber': '9432109876',
        'bloodGroup': 'O-',
        'chronicConditions': [],
        'knownAllergies': [],
        'registeredByUid': chwUid,
        'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        'lastVisitAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
      },
      {
        'name': 'Vitthal Gaikwad',
        'age': 75,
        'gender': 'male',
        'village': 'Sinnar',
        'district': 'Nashik',
        'contactNumber': '9321098765',
        'bloodGroup': 'B-',
        'chronicConditions': ['Heart disease', 'Hypertension'],
        'knownAllergies': ['Aspirin'],
        'registeredByUid': chwUid,
        'registeredAt': Timestamp.fromDate(now.subtract(const Duration(days: 120))),
        'lastVisitAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      },
    ];
  }

  // ── Triage ─────────────────────────────────────────────────────────────────
  static Future<void> _seedTriage(List<String> pids, String chwUid) async {
    final now = DateTime.now();
    final triages = [
      {
        'patientId': pids[0],
        'assessedByUid': chwUid,
        'chiefComplaint': 'Swelling in feet, elevated BP',
        'symptoms': ['swelling', 'headache', 'blurred vision'],
        'temperature': 37.2,
        'bpSystolic': 158,
        'bpDiastolic': 102,
        'heartRate': 88,
        'spO2': 97,
        'respiratoryRate': 18,
        'riskLevel': 'medium',
        'riskScore': 42,
        'riskFlags': ['Hypertension (BP 158/102 mmHg)', 'High-risk age group: pregnant'],
        'aiNote': 'Patient presents with gestational hypertension. BP 158/102 mmHg is concerning in a 28-year-old pregnant patient. Immediate PHC referral recommended for obstetric evaluation.',
        'aiNoteGenerated': true,
        'assessedAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'patientId': pids[1],
        'assessedByUid': chwUid,
        'chiefComplaint': 'Chest tightness, shortness of breath',
        'symptoms': ['chest pain', 'difficulty breathing', 'dizziness'],
        'temperature': 37.8,
        'bpSystolic': 182,
        'bpDiastolic': 118,
        'heartRate': 112,
        'spO2': 91,
        'respiratoryRate': 26,
        'riskLevel': 'high',
        'riskScore': 85,
        'riskFlags': [
          'Hypertensive crisis (BP 182/118 mmHg)',
          'Low SpO₂ (91%)',
          'Elevated respiratory rate (26/min)',
          'High-risk symptom: chest pain',
          'High-risk symptom: difficulty breathing',
          'Chronic condition: hypertension',
        ],
        'aiNote': 'High-risk: Patient shows signs of hypertensive emergency with concurrent respiratory distress. SpO₂ at 91% suggests pulmonary involvement. Emergency referral to district hospital required immediately.',
        'aiNoteGenerated': true,
        'assessedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'patientId': pids[2],
        'assessedByUid': chwUid,
        'chiefComplaint': 'Fever and cough for 3 days',
        'symptoms': ['fever', 'cough', 'runny nose'],
        'temperature': 38.9,
        'bpSystolic': 96,
        'bpDiastolic': 64,
        'heartRate': 102,
        'spO2': 96,
        'respiratoryRate': 22,
        'riskLevel': 'medium',
        'riskScore': 38,
        'riskFlags': ['Fever (38.9 °C)', 'High-risk age group (8 years)', 'Abnormal heart rate (102 bpm)'],
        'aiNote': 'Pediatric patient with fever and URTI symptoms. Elevated heart rate likely secondary to fever. Monitor SpO₂ closely; reassess in 12 hours or sooner if SpO₂ drops below 94%.',
        'aiNoteGenerated': true,
        'assessedAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
      {
        'patientId': pids[3],
        'assessedByUid': chwUid,
        'chiefComplaint': 'Increasing shortness of breath',
        'symptoms': ['difficulty breathing', 'wheezing', 'chest tightness'],
        'temperature': 37.0,
        'bpSystolic': 128,
        'bpDiastolic': 82,
        'heartRate': 96,
        'spO2': 89,
        'respiratoryRate': 28,
        'riskLevel': 'high',
        'riskScore': 72,
        'riskFlags': ['Critical SpO₂ (89%)', 'Abnormal respiratory rate (28/min)', 'Chronic condition: copd'],
        'aiNote': null,
        'aiNoteGenerated': false,
        'assessedAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'patientId': pids[4],
        'assessedByUid': chwUid,
        'chiefComplaint': 'Abdominal pain',
        'symptoms': ['abdominal pain', 'nausea'],
        'temperature': 37.5,
        'bpSystolic': 118,
        'bpDiastolic': 76,
        'heartRate': 80,
        'spO2': 98,
        'respiratoryRate': 16,
        'riskLevel': 'low',
        'riskScore': 14,
        'riskFlags': [],
        'aiNote': null,
        'aiNoteGenerated': false,
        'assessedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
      },
    ];

    for (final t in triages) {
      try {
        await _db.collection(FirestorePaths.triageResults).add(t);
        print('✅ Triage for patient ${t['patientId']}');
      } catch (e) {
        print('⚠️  Triage: $e');
      }
    }
  }

  // ── Consult Requests ───────────────────────────────────────────────────────
  static Future<void> _seedConsults(
      List<String> pids, String chwUid, String doctorUid) async {
    final now = DateTime.now();
    final consults = [
      {
        'patientId': pids[1],
        'patientName': 'Ramesh Shinde',
        'chwUid': chwUid,
        'chwName': 'Sunita Kamble (CHW)',
        'doctorUid': doctorUid,
        'doctorName': 'Dr. Rajesh Patil',
        'reason': 'Hypertensive emergency with chest pain',
        'urgency': 'emergency',
        'status': 'accepted',
        'triageRisk': 'high',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'acceptedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 23))),
      },
      {
        'patientId': pids[0],
        'patientName': 'Anita Bhalerao',
        'chwUid': chwUid,
        'chwName': 'Sunita Kamble (CHW)',
        'doctorUid': null,
        'doctorName': null,
        'reason': 'Elevated BP in pregnancy — needs obstetric review',
        'urgency': 'urgent',
        'status': 'pending',
        'triageRisk': 'medium',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
        'acceptedAt': null,
      },
      {
        'patientId': pids[3],
        'patientName': 'Suresh Mane',
        'chwUid': chwUid,
        'chwName': 'Sunita Kamble (CHW)',
        'doctorUid': null,
        'doctorName': null,
        'reason': 'COPD exacerbation with SpO₂ 89%',
        'urgency': 'urgent',
        'status': 'pending',
        'triageRisk': 'high',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'acceptedAt': null,
      },
    ];

    for (final c in consults) {
      try {
        final ref = await _db.collection(FirestorePaths.consultRequests).add(c);
        // Add a seed chat message for the accepted consult
        if (c['status'] == 'accepted') {
          await _db.collection(FirestorePaths.consultMessages(ref.id)).add({
            'senderUid': doctorUid,
            'senderName': 'Dr. Rajesh Patil',
            'senderRole': 'doctor',
            'text': 'I have reviewed the triage report. Please confirm current BP reading and administer Amlodipine 5mg immediately. I will arrange emergency referral.',
            'sentAt': Timestamp.fromDate(now.subtract(const Duration(hours: 22))),
          });
          await _db.collection(FirestorePaths.consultMessages(ref.id)).add({
            'senderUid': chwUid,
            'senderName': 'Sunita Kamble (CHW)',
            'senderRole': 'chw',
            'text': 'Understood Doctor. Current BP is 180/116 mmHg. Administering medication now. Patient is conscious but distressed.',
            'sentAt': Timestamp.fromDate(now.subtract(const Duration(hours: 21, minutes: 30))),
          });
        }
        print('✅ Consult for patient ${c['patientName']}');
      } catch (e) {
        print('⚠️  Consult: $e');
      }
    }
  }

  // ── Referrals ──────────────────────────────────────────────────────────────
  static Future<void> _seedReferrals(List<String> pids, String doctorUid) async {
    final now = DateTime.now();
    final referrals = [
      {
        'patientId': pids[1],
        'patientName': 'Ramesh Shinde',
        'raisedByUid': doctorUid,
        'raisedByName': 'Dr. Rajesh Patil',
        'referredTo': 'Nashik Civil Hospital',
        'reason': 'Hypertensive emergency, possible cardiac event',
        'diagnosis': 'Hypertensive crisis with suspected ACS',
        'currentStatus': 'scheduled',
        'statusHistory': [
          {
            'status': 'created',
            'updatedByUid': doctorUid,
            'updatedByName': 'Dr. Rajesh Patil',
            'note': 'Emergency referral raised',
            'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 23))),
          },
          {
            'status': 'accepted',
            'updatedByUid': doctorUid,
            'updatedByName': 'Dr. Rajesh Patil',
            'note': 'Nashik Civil confirmed bed availability',
            'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 20))),
          },
          {
            'status': 'scheduled',
            'updatedByUid': doctorUid,
            'updatedByName': 'Dr. Rajesh Patil',
            'note': 'Ambulance arranged for tomorrow 9 AM',
            'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 18))),
          },
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 23))),
        'scheduledDate': Timestamp.fromDate(now.add(const Duration(hours: 6))),
      },
      {
        'patientId': pids[3],
        'patientName': 'Suresh Mane',
        'raisedByUid': doctorUid,
        'raisedByName': 'Dr. Rajesh Patil',
        'referredTo': 'Nashik District Hospital',
        'reason': 'COPD exacerbation with respiratory failure',
        'diagnosis': 'Acute-on-chronic COPD exacerbation',
        'currentStatus': 'created',
        'statusHistory': [
          {
            'status': 'created',
            'updatedByUid': doctorUid,
            'updatedByName': 'Dr. Rajesh Patil',
            'note': 'Urgent referral — SpO₂ 89%',
            'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
          },
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        'scheduledDate': null,
      },
      {
        'patientId': pids[5],
        'patientName': 'Vitthal Gaikwad',
        'raisedByUid': doctorUid,
        'raisedByName': 'Dr. Rajesh Patil',
        'referredTo': 'Nashik Civil Hospital — Cardiology',
        'reason': 'Routine cardiac follow-up for known heart disease',
        'diagnosis': 'Ischemic heart disease',
        'currentStatus': 'completed',
        'statusHistory': [
          {
            'status': 'created',
            'updatedByUid': doctorUid,
            'updatedByName': 'Dr. Rajesh Patil',
            'note': null,
            'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
          },
          {
            'status': 'accepted',
            'updatedByUid': doctorUid,
            'updatedByName': 'Dr. Rajesh Patil',
            'note': null,
            'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 28))),
          },
          {
            'status': 'scheduled',
            'updatedByUid': doctorUid,
            'updatedByName': 'Dr. Rajesh Patil',
            'note': null,
            'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 25))),
          },
          {
            'status': 'completed',
            'updatedByUid': doctorUid,
            'updatedByName': 'Dr. Rajesh Patil',
            'note': 'Patient seen. Echo ordered. Follow-up in 3 months.',
            'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
          },
        ],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
        'scheduledDate': Timestamp.fromDate(now.subtract(const Duration(days: 22))),
      },
    ];

    for (final r in referrals) {
      try {
        await _db.collection(FirestorePaths.referrals).add(r);
        print('✅ Referral for ${r['patientName']}');
      } catch (e) {
        print('⚠️  Referral: $e');
      }
    }
  }

  // ── Medicine Stock ─────────────────────────────────────────────────────────
  static Future<void> _seedMedicineStock() async {
    final now = DateTime.now();
    final medicines = [
      {
        'name': 'Amlodipine 5mg',
        'category': 'Antihypertensive',
        'status': 'inStock',
        'currentQuantity': 150,
        'minimumQuantity': 30,
        'unit': 'tablets',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'name': 'Metformin 500mg',
        'category': 'Antidiabetic',
        'status': 'low',
        'currentQuantity': 28,
        'minimumQuantity': 50,
        'unit': 'tablets',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      },
      {
        'name': 'Salbutamol Inhaler',
        'category': 'Bronchodilator',
        'status': 'low',
        'currentQuantity': 5,
        'minimumQuantity': 10,
        'unit': 'inhalers',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'name': 'Paracetamol 500mg',
        'category': 'Analgesic/Antipyretic',
        'status': 'inStock',
        'currentQuantity': 500,
        'minimumQuantity': 100,
        'unit': 'tablets',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
      {
        'name': 'ORS Sachets',
        'category': 'Rehydration',
        'status': 'inStock',
        'currentQuantity': 200,
        'minimumQuantity': 50,
        'unit': 'sachets',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'name': 'Iron + Folic Acid',
        'category': 'Maternal',
        'status': 'inStock',
        'currentQuantity': 180,
        'minimumQuantity': 60,
        'unit': 'tablets',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
      },
      {
        'name': 'Amoxicillin 250mg',
        'category': 'Antibiotic',
        'status': 'outOfStock',
        'currentQuantity': 0,
        'minimumQuantity': 50,
        'unit': 'capsules',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      },
      {
        'name': 'Atenolol 50mg',
        'category': 'Antihypertensive',
        'status': 'inStock',
        'currentQuantity': 90,
        'minimumQuantity': 30,
        'unit': 'tablets',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 6))),
      },
      {
        'name': 'Insulin Regular (Vials)',
        'category': 'Antidiabetic',
        'status': 'low',
        'currentQuantity': 3,
        'minimumQuantity': 10,
        'unit': 'vials',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'name': 'Zinc Syrup 20ml',
        'category': 'Pediatric',
        'status': 'inStock',
        'currentQuantity': 40,
        'minimumQuantity': 20,
        'unit': 'bottles',
        'lastUpdated': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
    ];

    for (final m in medicines) {
      try {
        await _db.collection(FirestorePaths.medicineStock).add(m);
      } catch (e) {
        print('⚠️  Medicine: $e');
      }
    }
    print('✅ Medicine stock seeded (${medicines.length} items)');
  }

  // ── Diagnostic Tests ───────────────────────────────────────────────────────
  static Future<void> _seedDiagnosticTests(
      List<String> pids, String doctorUid) async {
    final now = DateTime.now();
    final tests = [
      {
        'patientId': pids[1],
        'patientName': 'Ramesh Shinde',
        'testName': 'ECG',
        'testType': 'Cardiac',
        'status': 'ordered',
        'orderedByUid': doctorUid,
        'labName': 'Nashik Civil Hospital',
        'orderedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 22))),
      },
      {
        'patientId': pids[1],
        'patientName': 'Ramesh Shinde',
        'testName': 'CBC + Blood Sugar',
        'testType': 'Blood',
        'status': 'pending',
        'orderedByUid': doctorUid,
        'labName': 'PHC Lab',
        'orderedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 22))),
      },
      {
        'patientId': pids[0],
        'patientName': 'Anita Bhalerao',
        'testName': 'Urine Protein + Sugar',
        'testType': 'Urine',
        'status': 'pending',
        'orderedByUid': doctorUid,
        'labName': 'PHC Lab',
        'orderedAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'patientId': pids[3],
        'patientName': 'Suresh Mane',
        'testName': 'Chest X-Ray',
        'testType': 'Radiology',
        'status': 'sampleCollected',
        'orderedByUid': doctorUid,
        'labName': 'Nashik District Hospital',
        'orderedAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'patientId': pids[5],
        'patientName': 'Vitthal Gaikwad',
        'testName': 'Echocardiogram',
        'testType': 'Cardiac',
        'status': 'completed',
        'orderedByUid': doctorUid,
        'labName': 'Nashik Civil Hospital — Cardiology',
        'result': 'Mild LV dysfunction. EF 48%. Recommend cardiology follow-up.',
        'orderedAt': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
        'completedAt': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
      },
    ];

    for (final t in tests) {
      try {
        await _db.collection(FirestorePaths.diagnosticTests).add(t);
      } catch (e) {
        print('⚠️  Diagnostic test: $e');
      }
    }
    print('✅ Diagnostic tests seeded (${tests.length} items)');
  }

  // ── Follow-up Tasks ────────────────────────────────────────────────────────
  static Future<void> _seedFollowUpTasks(
      List<String> pids, String chwUid) async {
    final now = DateTime.now();
    final tasks = [
      {
        'patientId': pids[0],
        'patientName': 'Anita Bhalerao',
        'assignedToUid': chwUid,
        'title': 'Antenatal check-up visit',
        'description': 'Check BP, weight, fundal height. Ensure IFA tablets taken.',
        'category': 'maternal',
        'dueDate': Timestamp.fromDate(now.add(const Duration(days: 2))),
        'isDone': false,
        'createdByUid': chwUid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'patientId': pids[2],
        'patientName': 'Kavita Jadhav',
        'assignedToUid': chwUid,
        'title': 'Post-illness follow-up',
        'description': 'Check temperature, ensure full recovery from URTI.',
        'category': 'child',
        'dueDate': Timestamp.fromDate(now.subtract(const Duration(days: 1))), // overdue
        'isDone': false,
        'createdByUid': chwUid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
      {
        'patientId': pids[1],
        'patientName': 'Ramesh Shinde',
        'assignedToUid': chwUid,
        'title': 'Diabetes medication compliance check',
        'description': 'Verify Metformin usage. Check blood sugar if glucometer available.',
        'category': 'ncd',
        'dueDate': Timestamp.fromDate(now.add(const Duration(days: 7))),
        'isDone': false,
        'createdByUid': chwUid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'patientId': pids[4],
        'patientName': 'Lata Pawar',
        'assignedToUid': chwUid,
        'title': 'Abdominal pain follow-up',
        'description': 'Assess if abdominal pain resolved. Refer to PHC if persists.',
        'category': 'general',
        'dueDate': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'isDone': false,
        'createdByUid': chwUid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
      },
      {
        'patientId': pids[5],
        'patientName': 'Vitthal Gaikwad',
        'assignedToUid': chwUid,
        'title': 'Medication refill reminder',
        'description': 'Ensure Atenolol and Aspirin supply. Discuss cardiac diet.',
        'category': 'ncd',
        'dueDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))), // overdue
        'isDone': true,
        'completedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'createdByUid': chwUid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      },
    ];

    for (final t in tasks) {
      try {
        await _db.collection(FirestorePaths.followUpTasks).add(t);
      } catch (e) {
        print('⚠️  Follow-up task: $e');
      }
    }
    print('✅ Follow-up tasks seeded (${tasks.length} items)');
  }
}
