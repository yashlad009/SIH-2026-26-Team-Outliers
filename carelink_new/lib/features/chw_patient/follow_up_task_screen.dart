import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../data/repositories/follow_up_repository.dart';
import '../../models/follow_up_task_model.dart';
import '../../providers/inventory_provider.dart';

class FollowUpTaskScreen extends ConsumerWidget {
  final bool embedded;
  final String? chwUid;

  const FollowUpTaskScreen({super.key, this.embedded = false, this.chwUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = chwUid != null
        ? ref.watch(followUpTasksByChwProvider(chwUid!))
        : ref.watch(allFollowUpTasksProvider);

    final body = tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const EmptyState(
            message: 'No follow-up tasks',
            subtitle: 'Tasks assigned by doctors will appear here',
            icon: Icons.task_outlined,
          );
        }
        final overdue = tasks.where((t) => t.isOverdue).toList();
        final pending =
            tasks.where((t) => !t.isDone && !t.isOverdue).toList();
        final done = tasks.where((t) => t.isDone).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allFollowUpTasksProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              if (overdue.isNotEmpty) ...[
                _groupHeader('Overdue', overdue.length, AppColors.riskHigh),
                ...overdue.map((t) => _TaskCard(task: t)),
                const SizedBox(height: 16),
              ],
              if (pending.isNotEmpty) ...[
                _groupHeader(
                    'Pending', pending.length, AppColors.riskMedium),
                ...pending.map((t) => _TaskCard(task: t)),
                const SizedBox(height: 16),
              ],
              if (done.isNotEmpty) ...[
                _groupHeader('Completed', done.length, AppColors.riskLow),
                ...done.map((t) => _TaskCard(task: t)),
              ],
            ],
          ),
        );
      },
      loading: () => ListView(
        children: List.generate(
            4,
            (_) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: LoadingListItem())),
      ),
      error: (e, _) => EmptyState(
          message: 'Failed to load tasks',
          subtitle: e.toString(),
          icon: Icons.error_outline),
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Follow-up Tasks')),
      body: body,
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
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        Text('$label ($count)',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 13)),
      ]),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final FollowUpTaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catColor = _catColor(task.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          activeColor: AppColors.riskLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (v) async {
            try {
              final repo = FollowUpRepository();
              if (v == true) {
                await repo.markDone(task.id);
              } else {
                await repo.markUndone(task.id);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')));
              }
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? AppColors.textHint : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.patientName,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(task.category.label,
                    style: TextStyle(fontSize: 10, color: catColor,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Icon(
                task.isOverdue ? Icons.warning_amber_outlined : Icons.event_outlined,
                size: 12,
                color: task.isOverdue ? AppColors.riskHigh : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                task.isDone
                    ? 'Completed ${DateFormatters.timeAgo(task.completedAt)}'
                    : 'Due ${DateFormatters.formatDate(task.dueDate)}',
                style: TextStyle(
                    fontSize: 11,
                    color: task.isOverdue
                        ? AppColors.riskHigh
                        : AppColors.textSecondary),
              ),
            ]),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _catColor(FollowUpCategory cat) {
    switch (cat) {
      case FollowUpCategory.maternal:
        return const Color(0xFF7B1FA2);
      case FollowUpCategory.child:
        return const Color(0xFF1565C0);
      case FollowUpCategory.ncd:
        return const Color(0xFF2E7D32);
      case FollowUpCategory.general:
        return AppColors.primary;
    }
  }
}
