import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/medicine_stock_model.dart';

class InventoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.medicineStock);

  Stream<List<MedicineStockModel>> watchStock() {
    return _col
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(MedicineStockModel.fromFirestore).toList());
  }

  Future<List<MedicineStockModel>> getStock() async {
    final snap = await _col.orderBy('name').get();
    return snap.docs.map(MedicineStockModel.fromFirestore).toList();
  }
}
