import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../models/diagnostic_test_model.dart';
import '../../providers/inventory_provider.dart';

class PendingTestsScreen extends ConsumerWidget {
  /// If patientId is provided, shows only that patient's tests
  final String? patientId;
  const PendingTestsScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = patientId != null
        ? ref.watch(patientDiagnosticTestsProvider(patientId!))
        : ref.watch(allDiagnosticTestsProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Diagnostic Tests')),
      body: testsAsync.when(
        data: (tests) {
          if (tests.isEmpty) {
            return const EmptyState(
              message: 'No tests ordered',
              subtitle: 'Diagnostic tests ordered by doctors will appear here',
              icon: Icons.biotech_outlined,
            );
          }

          final pending = tests.where((t) =>
              t.status == TestStatus.pending ||
              t.status == TestStatus.ordered).toList();
          final inProgress = tests.where((t) =>
              t.status == TestStatus.sampleCollected).toList();
          final done = tests.where((t) =>
              t.status == TestStatus.completed ||
              t.status == TestStatus.cancelled).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              if (pending.isNotEmpty) ...[
                _groupHeader('Pending / Ordered', pending.length, AppColors.riskMedium),
                ...pending.map((t) => _TestCard(test: t)),
                const SizedBox(height: 12),
              ],
              if (inProgress.isNotEmpty) ...[
                _groupHeader('Sample Collected', inProgress.length, AppColors.secondary),
                ...inProgress.map((t) => _TestCard(test: t)),
                const SizedBox(height: 12),
              ],
              if (done.isNotEmpty) ...[
                _groupHeader('Completed / Cancelled', done.length, AppColors.statusDropped),
                ...done.map((t) => _TestCard(test: t)),
              ],
            ],
          );
        },
        loading: () => ListView(
          children: List.generate(4, (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: LoadingListItem())),
        ),
        error: (e, _) => EmptyState(
            message: 'Failed to load tests',
            subtitle: e.toString(),
            icon: Icons.error_outline),
      ),
    );
  }

  Widget _groupHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 4,
          height: 16,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        Text('$label ($count)',
            style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
      ]),
    );
  }
}

class _TestCard extends StatelessWidget {
  final DiagnosticTestModel test;
  const _TestCard({required this.test});

  Color get _statusColor {
    switch (test.status) {
      case TestStatus.pending: return AppColors.riskMedium;
      case TestStatus.ordered: return AppColors.statusCreated;
      case TestStatus.sampleCollected: return AppColors.secondary;
      case TestStatus.completed: return AppColors.riskLow;
      case TestStatus.cancelled: return AppColors.statusDropped;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(test.testName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.4)),
                ),
                child: Text(test.status.label,
                    style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Patient: ${test.patientName}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (test.testType != null)
              Text('Type: ${test.testType}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (test.labName != null)
              Text('Lab: ${test.labName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Ordered: ${DateFormatters.formatRelative(test.orderedAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            if (test.result != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.riskLowLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.article_outlined, size: 14, color: AppColors.riskLow),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Result: ${test.result}',
                          style: const TextStyle(fontSize: 12, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
