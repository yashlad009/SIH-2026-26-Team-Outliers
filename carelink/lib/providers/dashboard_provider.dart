import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_stock_model.dart';
import '../models/referral_model.dart';
import '../models/triage_result_model.dart';
import 'referral_provider.dart';
import 'patient_provider.dart';
import 'inventory_provider.dart';

class DailyCount {
  final DateTime date;
  final int count;
  const DailyCount(this.date, this.count);
}

/// Real aggregated dashboard metrics derived directly from Firestore data
class DashboardSummary {
  final int totalPatients;
  final int activeReferrals;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final int completedReferrals;
  final int droppedReferrals;
  final int pendingFollowUps;
  final int overdueFollowUps;
  final int lowStockCount;
  final int pendingTestsCount;
  final List<DailyCount> last7DaysCases;
  final List<DailyCount> last7DaysReferrals;

  const DashboardSummary({
    required this.totalPatients,
    required this.activeReferrals,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.completedReferrals,
    required this.droppedReferrals,
    required this.pendingFollowUps,
    required this.overdueFollowUps,
    required this.lowStockCount,
    required this.pendingTestsCount,
    required this.last7DaysCases,
    required this.last7DaysReferrals,
  });
}

final dashboardProvider = Provider<DashboardSummary>((ref) {
  final patientsAsync = ref.watch(patientListProvider);
  final referralsAsync = ref.watch(allReferralsProvider);
  final followUpsAsync = ref.watch(allFollowUpTasksProvider);
  final stockAsync = ref.watch(medicineStockProvider);
  final testsAsync = ref.watch(allDiagnosticTestsProvider);

  final patients = patientsAsync.valueOrNull ?? [];
  final referrals = referralsAsync.valueOrNull ?? [];
  final followUps = followUpsAsync.valueOrNull ?? [];
  final stock = stockAsync.valueOrNull ?? [];
  final tests = testsAsync.valueOrNull ?? [];

  final totalPatients = patients.length;
  final highRiskCount =
      patients.where((p) => p.triageRisk == RiskLevel.high).length;
  final mediumRiskCount =
      patients.where((p) => p.triageRisk == RiskLevel.medium).length;
  final lowRiskCount =
      patients.where((p) => p.triageRisk == RiskLevel.low).length;

  final activeReferrals = referrals
      .where((r) =>
          r.currentStatus != ReferralStatus.completed &&
          r.currentStatus != ReferralStatus.dropped)
      .length;
  final completedReferrals =
      referrals.where((r) => r.currentStatus == ReferralStatus.completed).length;
  final droppedReferrals =
      referrals.where((r) => r.currentStatus == ReferralStatus.dropped).length;

  final pendingFollowUps = followUps.where((f) => !f.isDone).length;
  final overdueFollowUps =
      followUps.where((f) => !f.isDone && f.isOverdue).length;

  final lowStockCount = stock
      .where((m) =>
          m.currentQuantity <= m.minimumQuantity ||
          m.status == StockStatus.low ||
          m.status == StockStatus.outOfStock)
      .length;
  final pendingTestsCount = tests
      .where((t) => t.status.name == 'pending' || t.status.name == 'sampleCollected')
      .length;

  // Real 7-day registration counts
  final now = DateTime.now();
  final last7Cases = List.generate(7, (i) {
    final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
    final count = patients.where((p) {
      final reg = DateTime(p.registeredAt.year, p.registeredAt.month, p.registeredAt.day);
      return reg.isAtSameMomentAs(date);
    }).length;
    return DailyCount(date, count);
  });

  // Real 7-day referral counts
  final last7Referrals = List.generate(7, (i) {
    final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
    final count = referrals.where((r) {
      final created = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      return created.isAtSameMomentAs(date);
    }).length;
    return DailyCount(date, count);
  });

  return DashboardSummary(
    totalPatients: totalPatients,
    activeReferrals: activeReferrals,
    highRiskCount: highRiskCount,
    mediumRiskCount: mediumRiskCount,
    lowRiskCount: lowRiskCount,
    completedReferrals: completedReferrals,
    droppedReferrals: droppedReferrals,
    pendingFollowUps: pendingFollowUps,
    overdueFollowUps: overdueFollowUps,
    lowStockCount: lowStockCount,
    pendingTestsCount: pendingTestsCount,
    last7DaysCases: last7Cases,
    last7DaysReferrals: last7Referrals,
  );
});
