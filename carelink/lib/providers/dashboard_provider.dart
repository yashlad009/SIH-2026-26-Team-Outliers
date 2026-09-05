import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral_model.dart';
import 'referral_provider.dart';
import 'patient_provider.dart';

/// Dashboard summary data aggregated from Firestore streams.
class DashboardSummary {
  final int totalPatients;
  final int activeReferrals;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final int completedReferrals;
  final int droppedReferrals;
  final List<_DailyCount> last7DaysCases;

  const DashboardSummary({
    required this.totalPatients,
    required this.activeReferrals,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.completedReferrals,
    required this.droppedReferrals,
    required this.last7DaysCases,
  });
}

class _DailyCount {
  final DateTime date;
  final int count;
  const _DailyCount(this.date, this.count);
}

final dashboardProvider = Provider<DashboardSummary>((ref) {
  final patientsAsync = ref.watch(patientListProvider);
  final referralsAsync = ref.watch(allReferralsProvider);

  final totalPatients = patientsAsync.valueOrNull?.length ?? 0;

  final referrals = referralsAsync.valueOrNull ?? [];
  final activeReferrals = referrals
      .where((r) =>
          r.currentStatus != ReferralStatus.completed &&
          r.currentStatus != ReferralStatus.dropped)
      .length;
  final completedReferrals =
      referrals.where((r) => r.currentStatus == ReferralStatus.completed).length;
  final droppedReferrals =
      referrals.where((r) => r.currentStatus == ReferralStatus.dropped).length;

  // Static mock triage distribution for demo (seeded data)
  const highRiskCount = 3;
  const mediumRiskCount = 8;
  const lowRiskCount = 12;

  // Mock 7-day case volume
  final now = DateTime.now();
  final last7 = List.generate(7, (i) {
    final date = now.subtract(Duration(days: 6 - i));
    return _DailyCount(date, 2 + (i * 3 % 7)); // deterministic variation
  });

  return DashboardSummary(
    totalPatients: totalPatients,
    activeReferrals: activeReferrals,
    highRiskCount: highRiskCount,
    mediumRiskCount: mediumRiskCount,
    lowRiskCount: lowRiskCount,
    completedReferrals: completedReferrals,
    droppedReferrals: droppedReferrals,
    last7DaysCases: last7,
  );
});

// Re-export for use in charts
typedef DailyCount = _DailyCount;
