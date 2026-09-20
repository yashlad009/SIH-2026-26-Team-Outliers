import '../../models/user_model.dart';
import '../../models/triage_result_model.dart';
import '../../models/consult_request_model.dart';

class SmartAssignmentResult {
  final UserModel? assignedDoctor;
  final String requiredSpecialty;
  final String assignmentReason;
  final bool isEscalated;

  const SmartAssignmentResult({
    this.assignedDoctor,
    required this.requiredSpecialty,
    required this.assignmentReason,
    this.isEscalated = false,
  });
}

class SmartAssignmentService {
  /// Identifies the clinical specialty required based on triage data
  static String identifyRequiredSpecialty({
    required String chiefComplaint,
    required List<String> symptoms,
    required int age,
    double? temperature,
    int? bpSystolic,
    int? bpDiastolic,
    int? spO2,
    List<String>? chronicConditions,
  }) {
    final complaintLower = chiefComplaint.toLowerCase();
    final symptomsLower = symptoms.map((s) => s.toLowerCase()).toList();
    final chronicLower = (chronicConditions ?? []).map((c) => c.toLowerCase()).toList();

    // 1. Obstetrics & Gynecology (Maternal / Pregnancy)
    if (complaintLower.contains('pregnant') ||
        complaintLower.contains('pregnancy') ||
        complaintLower.contains('maternal') ||
        complaintLower.contains('obstetric') ||
        symptomsLower.contains('pregnancy complication') ||
        chronicLower.contains('gestational diabetes')) {
      return 'Obstetrics & Gynecology';
    }

    // 2. Cardiology (Hypertension / Cardiac)
    if (complaintLower.contains('chest pain') ||
        complaintLower.contains('heart') ||
        complaintLower.contains('hypertension') ||
        complaintLower.contains('cardiac') ||
        symptomsLower.contains('chest pain') ||
        (bpSystolic != null && bpSystolic >= 160) ||
        (bpDiastolic != null && bpDiastolic >= 100) ||
        chronicLower.contains('heart disease')) {
      return 'Cardiology';
    }

    // 3. Pulmonology (Respiratory / COPD / Low SpO2)
    if (complaintLower.contains('copd') ||
        complaintLower.contains('asthma') ||
        complaintLower.contains('breathing') ||
        complaintLower.contains('shortness of breath') ||
        symptomsLower.contains('difficulty breathing') ||
        symptomsLower.contains('wheezing') ||
        (spO2 != null && spO2 <= 92) ||
        chronicLower.contains('copd')) {
      return 'Pulmonology';
    }

    // 4. Pediatrics (Children under 12)
    if (age < 12) {
      return 'Pediatrics';
    }

    // 5. Default General Medicine
    return 'General Medicine';
  }

  /// Automatically selects and assigns the best available doctor based on provider data
  static SmartAssignmentResult selectBestDoctor({
    required List<UserModel> availableDoctors,
    required String requiredSpecialty,
    required UrgencyLevel urgency,
  }) {
    final doctorsOnly = availableDoctors.where((u) => u.role == UserRole.doctor).toList();

    if (doctorsOnly.isEmpty) {
      return SmartAssignmentResult(
        assignedDoctor: null,
        requiredSpecialty: requiredSpecialty,
        assignmentReason:
            '⚠️ No on-duty doctors available in network. Escalated to District Control Room for urgent assignment.',
        isEscalated: true,
      );
    }

    // Filter on-duty doctors first
    final onDuty = doctorsOnly.where((d) => d.isOnDuty).toList();
    final pool = onDuty.isNotEmpty ? onDuty : doctorsOnly;

    UserModel? bestDoctor;
    double highestScore = -9999.0;
    String bestReason = '';

    for (final doc in pool) {
      double score = 100.0;
      final docSpec = doc.specialty ?? 'General Medicine';

      // Specialty match bonus
      final isExactMatch = docSpec.toLowerCase() == requiredSpecialty.toLowerCase();
      if (isExactMatch) {
        score += 80.0;
      } else if (docSpec.toLowerCase() == 'general medicine') {
        score += 30.0;
      } else {
        score += 10.0;
      }

      // Workload penalty (fewer active cases = higher score)
      score -= (doc.activeWorkload * 15.0);

      // Facility proximity / match bonus if applicable
      if (doc.facilityName != null) {
        score += 10.0;
      }

      if (score > highestScore) {
        highestScore = score;
        bestDoctor = doc;

        final matchNote = isExactMatch
            ? 'Specialty match ($requiredSpecialty)'
            : 'General Physician coverage ($docSpec)';
        bestReason =
            'Automatically assigned ${doc.displayName} — $matchNote, active on-duty status, current workload: ${doc.activeWorkload} case(s).';
      }
    }

    if (bestDoctor == null) {
      return SmartAssignmentResult(
        assignedDoctor: null,
        requiredSpecialty: requiredSpecialty,
        assignmentReason:
            '⚠️ All doctors currently overloaded. Escalated to District Duty Officer.',
        isEscalated: true,
      );
    }

    return SmartAssignmentResult(
      assignedDoctor: bestDoctor,
      requiredSpecialty: requiredSpecialty,
      assignmentReason: bestReason,
      isEscalated: false,
    );
  }
}
