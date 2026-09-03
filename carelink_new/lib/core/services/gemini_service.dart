// ⚠️  DEMO ONLY — API key is passed via --dart-define=GEMINI_API_KEY=...
// Move to a backend Cloud Function or server-side proxy before production.
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/triage_result_model.dart';

class GeminiService {
  // Key injected at build time: flutter run --dart-define=GEMINI_API_KEY=AIza...
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  GenerativeModel? _model;

  bool get isAvailable => _apiKey.isNotEmpty;

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// Generates a one-line clinical note explaining the triage risk score.
  /// Returns null if API key is missing or an error occurs.
  Future<String?> generateTriageNote({
    required int age,
    required RiskLevel riskLevel,
    required int riskScore,
    required List<String> riskFlags,
    required String chiefComplaint,
    double? temperature,
    int? bpSystolic,
    int? bpDiastolic,
    int? spO2,
    int? heartRate,
  }) async {
    if (!isAvailable) return null;

    final vitalsText = [
      if (temperature != null) 'Temp: ${temperature.toStringAsFixed(1)}°C',
      if (bpSystolic != null) 'BP: $bpSystolic/${bpDiastolic ?? '?'} mmHg',
      if (spO2 != null) 'SpO₂: $spO2%',
      if (heartRate != null) 'HR: $heartRate bpm',
    ].join(', ');

    final prompt = '''
You are a clinical decision support AI for a rural healthcare app in Maharashtra, India.
A Community Health Worker has completed a triage assessment. Based on the following data,
write ONE concise clinical note (2–3 sentences max) explaining why the risk level is what it is
and what the CHW should do next. Use simple, clear English.

Patient Age: $age years
Chief Complaint: $chiefComplaint
Vitals: ${vitalsText.isNotEmpty ? vitalsText : 'Not all vitals recorded'}
Risk Flags: ${riskFlags.isEmpty ? 'None' : riskFlags.join('; ')}
Triage Risk Level: ${riskLevel.label} (score $riskScore/100)

Important: End with a clear recommendation (e.g., "Refer to PHC immediately" or "Monitor and reassess in 4 hours").
Do NOT include disclaimers or formatting — just the clinical note text.
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      return null;
    }
  }
}
