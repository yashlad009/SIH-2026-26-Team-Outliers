import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/patient_model.dart';
import '../../models/triage_result_model.dart';

class PatientRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.patients);

  // ── Patients ──────────────────────────────────────────────────────────────

  Stream<List<PatientModel>> watchAllPatients() {
    return _col
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PatientModel.fromFirestore).toList());
  }

  Future<PatientModel?> getPatient(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return PatientModel.fromFirestore(doc);
  }

  Future<String> createPatient(PatientModel patient) async {
    final ref = await _col.add(patient.toFirestore());
    return ref.id;
  }

  Future<void> updatePatient(PatientModel patient) async {
    await _col.doc(patient.id).update(patient.toFirestore());
  }

  // ── Triage ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _triageCol =>
      _db.collection(FirestorePaths.triageResults);

  Stream<List<TriageResultModel>> watchTriageResults(String patientId) {
    return _triageCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('assessedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TriageResultModel.fromFirestore).toList());
  }

  Future<TriageResultModel?> getLatestTriage(String patientId) async {
    final snap = await _triageCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('assessedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return TriageResultModel.fromFirestore(snap.docs.first);
  }

  Future<String> saveTriage(TriageResultModel triage) async {
    final ref = await _triageCol.add(triage.toFirestore());
    // Update patient lastVisitAt
    await _col.doc(triage.patientId).update({
      'lastVisitAt': Timestamp.fromDate(triage.assessedAt),
    });
    return ref.id;
  }

  Future<void> updateTriageAiNote(
      String triageId, String aiNote) async {
    await _triageCol.doc(triageId).update({
      'aiNote': aiNote,
      'aiNoteGenerated': true,
    });
  }

  // ── Timeline (sub-collection) ────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchTimeline(String patientId) {
    return _db
        .collection(FirestorePaths.patientTimeline(patientId))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addTimelineEvent(
      String patientId, Map<String, dynamic> event) async {
    await _db.collection(FirestorePaths.patientTimeline(patientId)).add(event);
  }
}
