import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/referral_provider.dart';
import '../../providers/inventory_provider.dart';
import '../settings/settings_screen.dart';
import 'charts/case_volume_chart.dart';
import 'charts/triage_distribution_chart.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final summary = ref.watch(dashboardProvider);
    final patientsAsync = ref.watch(patientListProvider);
    ref.watch(allReferralsProvider);
    ref.watch(medicineStockProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(patientListProvider);
          ref.invalidate(allReferralsProvider);
          ref.invalidate(medicineStockProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName.substring(0, 1).toUpperCase()
                              : 'A',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Admin User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.facilityName ?? 'PHC Monitoring Office',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary Stats Row
              Row(
                children: [
                  _StatTile(
                    title: 'Total Patients',
                    value: '${summary.totalPatients}',
                    icon: Icons.people_outline,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    title: 'Active Referrals',
                    value: '${summary.activeReferrals}',
                    icon: Icons.alt_route_outlined,
                    color: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatTile(
                    title: 'High Risk',
                    value: '${summary.highRiskCount}',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.riskHigh,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    title: 'Medium Risk',
                    value: '${summary.mediumRiskCount}',
                    icon: Icons.info_outline,
                    color: AppColors.riskMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Triage Risk Distribution Chart
              Text(
                'Triage Risk Distribution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TriageDistributionChart(
                    high: summary.highRiskCount,
                    medium: summary.mediumRiskCount,
                    low: summary.lowRiskCount,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Case Volume Chart
              Text(
                'Recent Patient Registration Volume',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CaseVolumeChart(
                    data: _buildChartData(patientsAsync.valueOrNull ?? []),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MapEntry<DateTime, int>> _buildChartData(List<dynamic> patients) {
    if (patients.isEmpty) {
      final now = DateTime.now();
      return List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return MapEntry(date, (i * 2) + 1);
      });
    }
    final counts = <DateTime, int>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      counts[d] = 0;
    }
    for (final p in patients) {
      if (p.registeredAt != null) {
        final reg = DateTime(p.registeredAt.year, p.registeredAt.month, p.registeredAt.day);
        if (counts.containsKey(reg)) {
          counts[reg] = (counts[reg] ?? 0) + 1;
        }
      }
    }
    return counts.entries.toList();
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
