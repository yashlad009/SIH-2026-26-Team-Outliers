import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/triage_result_model.dart';
import '../core/services/gemini_service.dart';
import 'patient_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

final triageResultsByPatientProvider =
    StreamProvider.family<List<TriageResultModel>, String>((ref, patientId) {
  return ref.watch(patientRepositoryProvider).watchTriageResults(patientId);
});

final latestTriageProvider =
    FutureProvider.family<TriageResultModel?, String>((ref, patientId) async {
  return ref.watch(patientRepositoryProvider).getLatestTriage(patientId);
});
