import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/follow_up_task_model.dart';

class FollowUpRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.followUpTasks);

  Stream<List<FollowUpTaskModel>> watchAllTasks() {
    return _col
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map(FollowUpTaskModel.fromFirestore).toList());
  }

  Stream<List<FollowUpTaskModel>> watchTasksByChw(String chwUid) {
    return _col.snapshots(includeMetadataChanges: true).map((s) {
      final list = s.docs.map(FollowUpTaskModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<FollowUpTaskModel>> watchTasksByPatient(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
      final list = s.docs.map(FollowUpTaskModel.fromFirestore).toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    });
  }

  Future<String> createTask(FollowUpTaskModel task) async {
    final ref = await _col.add(task.toFirestore());
    return ref.id;
  }

  Future<void> markDone(String taskId) async {
    await _col.doc(taskId).update({
      'isDone': true,
      'completedAt': Timestamp.now(),
    });

    final doc = await _col.doc(taskId).get();
    if (!doc.exists) return;
    final task = FollowUpTaskModel.fromFirestore(doc);

    if (task.careCaseId != null && task.careCaseId!.isNotEmpty) {
      final careCaseDoc = await _db.collection(FirestorePaths.careCases).doc(task.careCaseId).get();
      if (careCaseDoc.exists) {
        final data = careCaseDoc.data()!;
        final diagStatus = (data['diagnosticsStatus'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {};
        final medStatus = (data['medicinesStatus'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {};
        final isDoctorConsulted = data['isDoctorConsulted'] as bool? ?? false;

        final allDiagDone = diagStatus.values.every((v) => v == 'completed');
        final allMedsDispensed = medStatus.values.every((v) => v == 'dispensed');

        final updates = <String, dynamic>{
          'isFollowUpDone': true,
          'updatedAt': Timestamp.now(),
        };

        // ONLY auto-complete if ALL required steps (doctor consult, diagnostics, medicines, follow-up) are complete
        if (isDoctorConsulted && allDiagDone && allMedsDispensed) {
          updates['status'] = 'completed';
        }

        await _db.collection(FirestorePaths.careCases).doc(task.careCaseId).update(updates);
      }
    }
  }

  Future<void> markUndone(String taskId) async {
    await _col.doc(taskId).update({
      'isDone': false,
      'completedAt': null,
    });

    final doc = await _col.doc(taskId).get();
    if (!doc.exists) return;
    final task = FollowUpTaskModel.fromFirestore(doc);

    if (task.careCaseId != null && task.careCaseId!.isNotEmpty) {
      await _db.collection(FirestorePaths.careCases).doc(task.careCaseId).update({
        'isFollowUpDone': false,
        'status': 'inProgress',
        'updatedAt': Timestamp.now(),
      });
    }
  }
}
