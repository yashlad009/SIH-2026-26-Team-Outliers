import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/diagnostic_test_model.dart';

class DiagnosticRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.diagnosticTests);

  Stream<List<DiagnosticTestModel>> watchAllTests() {
    return _col
        .orderBy('orderedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DiagnosticTestModel.fromFirestore).toList());
  }

  Stream<List<DiagnosticTestModel>> watchTestsByPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('orderedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DiagnosticTestModel.fromFirestore).toList());
  }
}
