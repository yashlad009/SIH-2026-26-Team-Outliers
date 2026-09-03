import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/patient_repository.dart';
import '../models/patient_model.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});

final patientListProvider = StreamProvider<List<PatientModel>>((ref) {
  return ref.watch(patientRepositoryProvider).watchAllPatients();
});

final patientByIdProvider = FutureProvider.family<PatientModel?, String>((ref, id) {
  return ref.watch(patientRepositoryProvider).getPatient(id);
});

final patientSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredPatientListProvider = Provider<AsyncValue<List<PatientModel>>>((ref) {
  final query = ref.watch(patientSearchQueryProvider).toLowerCase().trim();
  final patientsAsync = ref.watch(patientListProvider);

  return patientsAsync.whenData((patients) {
    if (query.isEmpty) return patients;
    return patients.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.village.toLowerCase().contains(query) ||
          (p.contactNumber?.contains(query) ?? false);
    }).toList();
  });
});
