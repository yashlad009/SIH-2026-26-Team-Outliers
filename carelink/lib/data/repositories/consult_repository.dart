import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/consult_request_model.dart';

class ConsultRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.consultRequests);

  Stream<List<ConsultRequestModel>> watchPendingConsults() {
    return _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ConsultRequestModel.fromFirestore).toList());
  }

  Stream<List<ConsultRequestModel>> watchConsultsByChw(String chwUid) {
    return _col
        .where('chwUid', isEqualTo: chwUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ConsultRequestModel.fromFirestore).toList());
  }

  Stream<List<ConsultRequestModel>> watchConsultsByPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ConsultRequestModel.fromFirestore).toList());
  }

  Future<ConsultRequestModel?> getConsult(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ConsultRequestModel.fromFirestore(doc);
  }

  Future<String> createConsult(ConsultRequestModel consult) async {
    final ref = await _col.add(consult.toFirestore());
    return ref.id;
  }

  Future<void> acceptConsult({
    required String consultId,
    required String doctorUid,
    required String doctorName,
  }) async {
    await _col.doc(consultId).update({
      'status': ConsultStatus.accepted.name,
      'doctorUid': doctorUid,
      'doctorName': doctorName,
      'acceptedAt': Timestamp.now(),
    });
  }

  Future<void> closeConsult({
    required String consultId,
    String? prescriptionNote,
  }) async {
    await _col.doc(consultId).update({
      'status': ConsultStatus.closed.name,
      'prescriptionNote': prescriptionNote,
      'closedAt': Timestamp.now(),
    });
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Stream<List<ConsultMessage>> watchMessages(String consultId) {
    return _db
        .collection(FirestorePaths.consultMessages(consultId))
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ConsultMessage.fromFirestore).toList());
  }

  Future<void> sendMessage(String consultId, ConsultMessage message) async {
    await _db
        .collection(FirestorePaths.consultMessages(consultId))
        .add(message.toFirestore());
  }
}
