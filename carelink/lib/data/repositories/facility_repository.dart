import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/facility_model.dart';

class FacilityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.facilities);

  Stream<List<FacilityModel>> watchAllFacilities() {
    return _col.snapshots(includeMetadataChanges: true).map((s) {
      return s.docs.map(FacilityModel.fromFirestore).toList();
    });
  }

  Future<List<FacilityModel>> getAllFacilities() async {
    final s = await _col.get();
    return s.docs.map(FacilityModel.fromFirestore).toList();
  }

  Future<FacilityModel?> getFacility(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return FacilityModel.fromFirestore(doc);
  }

  Future<void> saveFacility(FacilityModel facility) async {
    await _col.doc(facility.id).set(facility.toFirestore(), SetOptions(merge: true));
  }
}
