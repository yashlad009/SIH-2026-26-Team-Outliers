import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/consult_repository.dart';
import '../models/consult_request_model.dart';

final consultRepositoryProvider = Provider<ConsultRepository>((ref) {
  return ConsultRepository();
});

/// All pending consult requests — for doctor's queue
final pendingConsultsProvider = StreamProvider<List<ConsultRequestModel>>((ref) {
  return ref.watch(consultRepositoryProvider).watchPendingConsults();
});

/// All consults for the current CHW (by chwUid)
final chwConsultsProvider = StreamProvider.family<List<ConsultRequestModel>, String>(
  (ref, chwUid) {
    return ref.watch(consultRepositoryProvider).watchConsultsByChw(chwUid);
  },
);

/// Consults for a specific patient
final patientConsultsProvider =
    StreamProvider.family<List<ConsultRequestModel>, String>((ref, patientId) {
  return ref.watch(consultRepositoryProvider).watchConsultsByPatient(patientId);
});

/// Messages for a consult
final consultMessagesProvider =
    StreamProvider.family<List<ConsultMessage>, String>((ref, consultId) {
  return ref.watch(consultRepositoryProvider).watchMessages(consultId);
});
