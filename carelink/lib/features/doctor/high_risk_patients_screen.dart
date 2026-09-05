import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/risk_badge.dart';
import '../../models/patient_model.dart';
import '../../models/triage_result_model.dart';
import '../../providers/patient_provider.dart';
import '../patient_record/patient_record_screen.dart';

class HighRiskPatientsScreen extends ConsumerWidget {
  const HighRiskPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highRiskAsync = ref.watch(highRiskPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlighted / High-Risk Patients'),
      ),
      body: highRiskAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return const EmptyState(
              message: 'No high-risk patients',
              subtitle: 'Patients identified as high risk will appear here',
              icon: Icons.shield_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.riskHighLight,
                    child: Text(
                      patient.initials,
                      style: const TextStyle(
                        color: AppColors.riskHigh,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const RiskBadge(riskLevel: RiskLevel.high),
                    ],
                  ),
                  subtitle: Text(
                    '${patient.age}y · ${patient.gender.label} · ${patient.village}',
                  ),
                  trailing:
                      const Icon(Icons.chevron_right, color: AppColors.textHint),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientRecordScreen(patient: patient),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LoadingListItem(),
          ),
        ),
        error: (e, _) => EmptyState(
          message: 'Failed to load high-risk patients',
          subtitle: e.toString(),
          icon: Icons.error_outline,
        ),
      ),
    );
  }
}
