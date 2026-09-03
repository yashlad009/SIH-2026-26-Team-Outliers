import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/diagnostic_repository.dart';
import '../data/repositories/follow_up_repository.dart';
import '../models/medicine_stock_model.dart';
import '../models/diagnostic_test_model.dart';
import '../models/follow_up_task_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

final medicineStockProvider = StreamProvider<List<MedicineStockModel>>((ref) {
  return ref.watch(inventoryRepositoryProvider).watchStock();
});

// ── Diagnostics ────────────────────────────────────────────────────────────
final diagnosticRepositoryProvider = Provider<DiagnosticRepository>((ref) {
  return DiagnosticRepository();
});

final allDiagnosticTestsProvider = StreamProvider<List<DiagnosticTestModel>>((ref) {
  return ref.watch(diagnosticRepositoryProvider).watchAllTests();
});

final patientDiagnosticTestsProvider =
    StreamProvider.family<List<DiagnosticTestModel>, String>((ref, patientId) {
  return ref.watch(diagnosticRepositoryProvider).watchTestsByPatient(patientId);
});

// ── Follow-up ──────────────────────────────────────────────────────────────
final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  return FollowUpRepository();
});

final allFollowUpTasksProvider = StreamProvider<List<FollowUpTaskModel>>((ref) {
  return ref.watch(followUpRepositoryProvider).watchAllTasks();
});

final followUpTasksByChwProvider =
    StreamProvider.family<List<FollowUpTaskModel>, String>((ref, chwUid) {
  return ref.watch(followUpRepositoryProvider).watchTasksByChw(chwUid);
});
