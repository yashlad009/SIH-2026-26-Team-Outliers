import '../../models/triage_result_model.dart';

/// Rule-based triage scoring engine.
///
/// Scoring is additive — each abnormal vitals threshold adds to the score.
/// Score → Risk Level:
///   0–29  → Low
///   30–59 → Medium
///   60+   → High
///
/// This is for demo/clinical decision support only, not a medical diagnostic tool.
class RiskScoring {
  RiskScoring._();

  static const int _highThreshold = 60;
  static const int _mediumThreshold = 30;

  /// Compute risk from raw vitals + demographics.
  /// Returns a [TriageScore] with score, level, and human-readable flags.
  static TriageScore compute({
    required int age,
    double? temperature, // °C
    int? bpSystolic, // mmHg
    int? bpDiastolic, // mmHg
    int? heartRate, // bpm
    int? spO2, // %
    int? respiratoryRate, // /min
    List<String> symptoms = const [],
    List<String> chronicConditions = const [],
  }) {
    int score = 0;
    final flags = <String>[];

    // ── Temperature ─────────────────────────────────────────────────────────
    if (temperature != null) {
      if (temperature >= 40.0) {
        score += 25;
        flags.add('High fever (${temperature.toStringAsFixed(1)} °C)');
      } else if (temperature >= 38.5) {
        score += 15;
        flags.add('Fever (${temperature.toStringAsFixed(1)} °C)');
      } else if (temperature < 36.0) {
        score += 20;
        flags.add('Hypothermia (${temperature.toStringAsFixed(1)} °C)');
      }
    }

    // ── Blood Pressure ───────────────────────────────────────────────────────
    if (bpSystolic != null) {
      if (bpSystolic >= 180 || (bpDiastolic != null && bpDiastolic >= 120)) {
        score += 30;
        flags.add('Hypertensive crisis (BP $bpSystolic/${bpDiastolic ?? '?'} mmHg)');
      } else if (bpSystolic >= 140 || (bpDiastolic != null && bpDiastolic >= 90)) {
        score += 15;
        flags.add('Hypertension (BP $bpSystolic/${bpDiastolic ?? '?'} mmHg)');
      } else if (bpSystolic < 90) {
        score += 25;
        flags.add('Hypotension (BP $bpSystolic mmHg)');
      }
    }

    // ── Heart Rate ───────────────────────────────────────────────────────────
    if (heartRate != null) {
      if (heartRate >= 130 || heartRate < 40) {
        score += 25;
        flags.add('Critical heart rate ($heartRate bpm)');
      } else if (heartRate >= 100 || heartRate < 55) {
        score += 10;
        flags.add('Abnormal heart rate ($heartRate bpm)');
      }
    }

    // ── SpO2 ─────────────────────────────────────────────────────────────────
    if (spO2 != null) {
      if (spO2 < 88) {
        score += 35;
        flags.add('Critical SpO₂ ($spO2%)');
      } else if (spO2 < 92) {
        score += 20;
        flags.add('Low SpO₂ ($spO2%)');
      } else if (spO2 < 95) {
        score += 10;
        flags.add('Borderline SpO₂ ($spO2%)');
      }
    }

    // ── Respiratory Rate ─────────────────────────────────────────────────────
    if (respiratoryRate != null) {
      if (respiratoryRate >= 30 || respiratoryRate < 8) {
        score += 25;
        flags.add('Abnormal respiratory rate ($respiratoryRate/min)');
      } else if (respiratoryRate >= 24) {
        score += 12;
        flags.add('Elevated respiratory rate ($respiratoryRate/min)');
      }
    }

    // ── Age risk ─────────────────────────────────────────────────────────────
    if (age < 2 || age > 70) {
      score += 10;
      flags.add('High-risk age group ($age years)');
    } else if (age < 5 || age > 60) {
      score += 5;
    }

    // ── Symptom keywords that raise score ────────────────────────────────────
    final highRiskKeywords = [
      'chest pain',
      'unconscious',
      'seizure',
      'difficulty breathing',
      'severe bleeding',
      'stroke',
      'pregnancy complication',
    ];
    final medRiskKeywords = [
      'headache',
      'vomiting',
      'diarrhea',
      'abdominal pain',
      'dizziness',
      'weakness',
      'rash',
    ];

    for (final s in symptoms.map((e) => e.toLowerCase())) {
      for (final k in highRiskKeywords) {
        if (s.contains(k)) {
          score += 20;
          flags.add('High-risk symptom: $k');
          break;
        }
      }
      for (final k in medRiskKeywords) {
        if (s.contains(k)) {
          score += 8;
          break;
        }
      }
    }

    // ── Chronic conditions ───────────────────────────────────────────────────
    final highRiskConditions = ['diabetes', 'heart disease', 'copd', 'kidney disease', 'hiv'];
    for (final c in chronicConditions.map((e) => e.toLowerCase())) {
      for (final k in highRiskConditions) {
        if (c.contains(k)) {
          score += 10;
          flags.add('Chronic condition: $c');
          break;
        }
      }
    }

    // Clamp to 100
    score = score.clamp(0, 100);

    final level = score >= _highThreshold
        ? RiskLevel.high
        : score >= _mediumThreshold
            ? RiskLevel.medium
            : RiskLevel.low;

    return TriageScore(
      score: score,
      level: level,
      flags: flags.toSet().toList(), // deduplicate
    );
  }
}

class TriageScore {
  final int score;
  final RiskLevel level;
  final List<String> flags;

  const TriageScore({
    required this.score,
    required this.level,
    required this.flags,
  });
}
