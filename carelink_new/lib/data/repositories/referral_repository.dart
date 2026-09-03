import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/referral_model.dart';

class ReferralRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.referrals);

  Stream<List<ReferralModel>> watchAllReferrals() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReferralModel.fromFirestore).toList());
  }

  Stream<List<ReferralModel>> watchReferralsByPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReferralModel.fromFirestore).toList());
  }

  Stream<List<ReferralModel>> watchActiveReferrals() {
    return _col
        .where('currentStatus', whereNotIn: ['completed', 'dropped'])
        .orderBy('currentStatus')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReferralModel.fromFirestore).toList());
  }

  Future<ReferralModel?> getReferral(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ReferralModel.fromFirestore(doc);
  }

  Future<String> createReferral(ReferralModel referral) async {
    final ref = await _col.add(referral.toFirestore());
    return ref.id;
  }

  Future<void> updateStatus({
    required String referralId,
    required ReferralStatus newStatus,
    required ReferralStatusEntry entry,
    DateTime? scheduledDate,
  }) async {
    final update = <String, dynamic>{
      'currentStatus': newStatus.name,
      'statusHistory': FieldValue.arrayUnion([entry.toMap()]),
    };
    if (scheduledDate != null) {
      update['scheduledDate'] = Timestamp.fromDate(scheduledDate);
    }
    await _col.doc(referralId).update(update);
  }
}
