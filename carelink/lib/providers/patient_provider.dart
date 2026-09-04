import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/patient_repository.dart';
import '../models/patient_model.dart';
import '../models/triage_result_model.dart';

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

final pendingSyncPatientsProvider = Provider<AsyncValue<List<PatientModel>>>((ref) {
  final patientsAsync = ref.watch(patientListProvider);
  return patientsAsync.whenData((patients) {
    final pending = patients.where((p) => p.isPendingSync).toList();
    pending.sort((a, b) {
      final aPriority = _riskPriority(a.triageRisk);
      final bPriority = _riskPriority(b.triageRisk);
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority); // Higher risk first
      }
      return b.registeredAt.compareTo(a.registeredAt); // Newest first
    });
    return pending;
  });
});

int _riskPriority(RiskLevel? level) {
  switch (level) {
    case RiskLevel.high:
      return 3;
    case RiskLevel.medium:
      return 2;
    case RiskLevel.low:
      return 1;
    case null:
      return 0;
  }
}

