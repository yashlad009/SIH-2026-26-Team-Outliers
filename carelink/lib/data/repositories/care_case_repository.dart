import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/care_case_model.dart';

class CareCaseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.careCases);

  Stream<List<CareCaseModel>> watchAllCareCases() {
    return _col.snapshots(includeMetadataChanges: true).map((s) {
      final list = s.docs.map(CareCaseModel.fromFirestore).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Stream<List<CareCaseModel>> watchCareCasesByPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
      final list = s.docs.map(CareCaseModel.fromFirestore).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Stream<List<CareCaseModel>> watchCareCasesByDoctor(String doctorUid) {
    return _col
        .where('assignedDoctorUid', isEqualTo: doctorUid)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
      final list = s.docs.map(CareCaseModel.fromFirestore).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Future<CareCaseModel?> getCareCase(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CareCaseModel.fromFirestore(doc);
  }

  Future<CareCaseModel?> getCareCaseByPatient(String patientId) async {
    final s = await _col
        .where('patientId', isEqualTo: patientId)
        .limit(1)
        .get();
    if (s.docs.isEmpty) return null;
    return CareCaseModel.fromFirestore(s.docs.first);
  }

  Future<String> createCareCase(CareCaseModel careCase) async {
    final ref = await _col.add(careCase.toFirestore());
    return ref.id;
  }

  Future<void> saveOrUpdateCareCase(CareCaseModel careCase) async {
    if (careCase.id.isNotEmpty) {
      await _col.doc(careCase.id).set(careCase.toFirestore(), SetOptions(merge: true));
    } else {
      await _col.add(careCase.toFirestore());
    }
  }

  Future<void> updateCareCaseStatus(String id, CareCaseStatus status) async {
    await _col.doc(id).update({
      'status': status.name,
      'updatedAt': Timestamp.now(),
    });
  }
}
