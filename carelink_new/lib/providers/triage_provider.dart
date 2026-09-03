import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/patient_repository.dart';
import '../models/triage_result_model.dart';
import '../core/services/gemini_service.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

final triageResultsByPatientProvider =
    StreamProvider.family<List<TriageResultModel>, String>((ref, patientId) {
  return ref.watch(patientRepositoryProvider).watchTriageResults(patientId);
});

final latestTriageProvider =
    FutureProvider.family<TriageResultModel?, String>((ref, patientId) async {
  return ref.watch(patientRepositoryProvider).getLatestTriage(patientId);
});
