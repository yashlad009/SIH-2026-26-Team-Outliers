import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/status_stepper.dart';
import '../../data/repositories/referral_repository.dart';
import '../../models/referral_model.dart';
import '../../providers/auth_provider.dart';

class ReferralDetailScreen extends ConsumerWidget {
  final ReferralModel referral;
  const ReferralDetailScreen({super.key, required this.referral});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final isDoctor = user?.role.name == 'doctor';

    return AppScaffold(
      appBar: AppBar(
        title: Text('Referral — ${referral.patientName}'),
        actions: [
          if (isDoctor && !referral.currentStatus.isTerminal)
            PopupMenuButton<ReferralStatus>(
              icon: const Icon(Icons.update),
              tooltip: 'Update Status',
              itemBuilder: (_) => ReferralStatus.values
                  .where((s) =>
                      s.index > referral.currentStatus.index)
                  .map((s) => PopupMenuItem(
                      value: s, child: Text(s.label)))
                  .toList(),
              onSelected: (s) =>
                  _updateStatus(context, ref, s, user!),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status stepper
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        _statusBadge(referral.currentStatus),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ReferralStatusStepper(
                        currentStatus: referral.currentStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Referral Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 12),
                    _row('Patient', referral.patientName),
                    _row('Referred To', referral.referredTo),
                    _row('Raised By', referral.raisedByName),
                    _row('Created', DateFormatters.formatDateTime(referral.createdAt)),
                    if (referral.scheduledDate != null)
                      _row('Scheduled',
                          DateFormatters.formatDateTime(referral.scheduledDate)),
                    if (referral.diagnosis != null)
                      _row('Diagnosis', referral.diagnosis!),
                    _divider(),
                    const SizedBox(height: 4),
                    const Text('Reason',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(referral.reason,
                        style: const TextStyle(fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status history
            if (referral.statusHistory.isNotEmpty) ...[
              const Text('Status History',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              ...referral.statusHistory.reversed.map((e) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _statusColor(e.status).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline,
                          size: 18,
                          color: _statusColor(e.status)),
                    ),
                    title: Text(e.status.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.updatedByName,
                            style: const TextStyle(fontSize: 12)),
                        if (e.note != null)
                          Text(e.note!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                    trailing: Text(
                      DateFormatters.formatRelative(e.timestamp),
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary),
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    ReferralStatus newStatus,
    dynamic user,
  ) async {
    String? note;
    DateTime? scheduledDate;

    if (newStatus == ReferralStatus.scheduled) {
      // Ask for scheduled date
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      scheduledDate = picked;
    }

    if (newStatus == ReferralStatus.dropped) {
      final noteCtrl = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Drop Reason'),
          content: TextField(
              controller: noteCtrl,
              decoration:
                  const InputDecoration(hintText: 'Reason for dropping')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, noteCtrl.text),
                child: const Text('Confirm')),
          ],
        ),
      );
      if (note == null) return;
    }

    try {
      final entry = ReferralStatusEntry(
        status: newStatus,
        updatedByUid: user.uid,
        updatedByName: user.displayName,
        note: note,
        timestamp: DateTime.now(),
      );
      await ReferralRepository().updateStatus(
        referralId: referral.id,
        newStatus: newStatus,
        entry: entry,
        scheduledDate: scheduledDate,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Status updated to ${newStatus.label}'),
            backgroundColor: AppColors.riskLow));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(),
      );

  Widget _statusBadge(ReferralStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(s).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: _statusColor(s).withOpacity(0.4)),
      ),
      child: Text(s.label,
          style: TextStyle(
              fontSize: 12,
              color: _statusColor(s),
              fontWeight: FontWeight.w600)),
    );
  }

  Color _statusColor(ReferralStatus s) {
    switch (s) {
      case ReferralStatus.created:
        return AppColors.statusCreated;
      case ReferralStatus.accepted:
        return AppColors.statusAccepted;
      case ReferralStatus.scheduled:
        return AppColors.statusScheduled;
      case ReferralStatus.completed:
        return AppColors.statusCompleted;
      case ReferralStatus.dropped:
        return AppColors.statusDropped;
    }
  }
}
