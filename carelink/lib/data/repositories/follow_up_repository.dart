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
    return _col
        .where('assignedToUid', isEqualTo: chwUid)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
      final list = s.docs.map(FollowUpTaskModel.fromFirestore).toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    });
  }

  Future<void> markDone(String taskId) async {
    await _col.doc(taskId).update({
      'isDone': true,
      'completedAt': Timestamp.now(),
    });
  }

  Future<void> markUndone(String taskId) async {
    await _col.doc(taskId).update({
      'isDone': false,
      'completedAt': null,
    });
  }
}
