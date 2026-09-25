import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../models/care_case_model.dart';
import '../../models/facility_model.dart';
import '../../providers/care_orchestration_provider.dart';
import '../care_orchestration/care_case_detail_screen.dart';

class ControlRoomScreen extends ConsumerWidget {
  final bool embedded;
  const ControlRoomScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careCasesAsync = ref.watch(allCareCasesProvider);
    final facilitiesAsync = ref.watch(allFacilitiesProvider);

    final content = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allCareCasesProvider);
        ref.invalidate(allFacilitiesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Room Title & Subtitle
            const Text(
              'District Care Orchestration Control Room',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
            const Text(
              'Real-time care monitoring, facility readiness, and bottleneck management across Nashik District',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Live Metrics Summary
            careCasesAsync.when(
              data: (cases) {
                final activeCount = cases.where((c) => c.status != CareCaseStatus.completed).length;
                final highRiskCount = cases.where((c) => c.riskLevel.name == 'high').length;
                final completedCount = cases.where((c) => c.status == CareCaseStatus.completed).length;

                return Row(
                  children: [
                    _metricTile('Active Cases', '$activeCount', Icons.all_inbox, AppColors.primary),
                    const SizedBox(width: 8),
                    _metricTile('High Risk', '$highRiskCount', Icons.warning_amber, AppColors.riskHigh),
                    const SizedBox(width: 8),
                    _metricTile('Completed', '$completedCount', Icons.check_circle_outline, AppColors.riskLow),
                  ],
                );
              },
              loading: () => const LoadingListItem(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Section 1: Facility Operational Readiness
            const Text(
              'HEALTHCARE FACILITY READINESS AUDIT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            facilitiesAsync.when(
              data: (facilities) {
                if (facilities.isEmpty) {
                  return const EmptyState(
                    message: 'No facilities configured',
                    subtitle: 'Seeded facility network data will load here.',
                    icon: Icons.local_hospital_outlined,
                  );
                }
                return Column(
                  children: facilities.map((f) => _buildFacilityCard(f)).toList(),
                );
              },
              loading: () => const LoadingListItem(),
              error: (e, _) => Text('Error loading facilities: $e'),
            ),
            const SizedBox(height: 24),

            // Section 2: System-wide Care Cases
            const Text(
              'ACTIVE CARE CASES SYSTEM-WIDE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            careCasesAsync.when(
              data: (cases) {
                if (cases.isEmpty) {
                  return const EmptyState(
                    message: 'No active Care Cases',
                    subtitle: 'Care cases created from triage will appear here in real-time.',
                    icon: Icons.folder_open,
                  );
                }
                return Column(
                  children: cases.map((c) => _buildCareCaseTile(context, c)).toList(),
                );
              },
              loading: () => const LoadingListItem(),
              error: (e, _) => Text('Error loading care cases: $e'),
            ),
          ],
        ),
      ),
    );

    if (embedded) return content;
    return AppScaffold(
      appBar: AppBar(title: const Text('District Control Room')),
      body: content,
    );
  }

  Widget _metricTile(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityCard(FacilityModel f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  f.tier == 'Tertiary'
                      ? Icons.local_hospital
                      : f.tier == 'Secondary'
                          ? Icons.local_hospital_outlined
                          : Icons.home_work_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${f.tier} Level · District ${f.district}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: f.isOperational ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    f.isOperational ? 'OPERATIONAL' : 'OFFLINE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: f.isOperational ? Colors.green.shade900 : Colors.red.shade900),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Specialties: ${f.availableSpecialties.join(", ")}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lab & Diagnostics: ${f.availableDiagnostics.join(", ")}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareCaseTile(BuildContext context, CareCaseModel c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.riskLevel.name == 'high'
              ? AppColors.riskHigh.withOpacity(0.2)
              : AppColors.primaryContainer,
          child: Text(
            c.patientName.isNotEmpty ? c.patientName[0] : 'P',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: c.riskLevel.name == 'high' ? AppColors.riskHigh : AppColors.primary,
            ),
          ),
        ),
        title: Text(c.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          'Doctor: ${c.assignedDoctorName ?? "Unassigned"} · Route: ${c.destinationFacilityName ?? "Local PHC"}\nStatus: ${c.status.label}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CareCaseDetailScreen(careCase: c)),
          );
        },
      ),
    );
  }
}
