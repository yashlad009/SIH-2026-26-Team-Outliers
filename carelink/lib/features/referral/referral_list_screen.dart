import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_stepper.dart';
import '../../models/referral_model.dart';
import '../../providers/referral_provider.dart';
import 'referral_detail_screen.dart';

import '../../providers/patient_provider.dart';
import '../doctor/raise_referral_screen.dart';

class ReferralListScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const ReferralListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ReferralListScreen> createState() => _ReferralListScreenState();
}

class _ReferralListScreenState extends ConsumerState<ReferralListScreen> {
  ReferralStatus? _selectedStatus; // null means All

  Future<void> _openCreateReferral() async {
    final patients = ref.read(patientListProvider).valueOrNull ?? [];
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patients available to create a referral.')),
      );
      return;
    }
    final patient = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Patient for Referral'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: patients.length,
            itemBuilder: (_, i) {
              final p = patients[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(p.initials, style: const TextStyle(color: AppColors.primary)),
                ),
                title: Text(p.name),
                subtitle: Text('${p.age}y · ${p.village}'),
                onTap: () => Navigator.pop(ctx, p),
              );
            },
          ),
        ),
      ),
    );
    if (patient != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RaiseReferralScreen(patient: patient)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final referralsAsync = ref.watch(allReferralsProvider);

    final body = referralsAsync.when(
      data: (referrals) {
        final filtered = _selectedStatus == null
            ? referrals
            : referrals
                .where((r) => r.currentStatus == _selectedStatus)
                .toList();

        return Column(
          children: [
            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (_) => setState(() => _selectedStatus = null),
                      selectedColor: AppColors.primaryContainer,
                      checkmarkColor: AppColors.primary,
                    ),
                  ),
                  ...ReferralStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status.label),
                        selected: _selectedStatus == status,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = status),
                        selectedColor: AppColors.primaryContainer,
                        checkmarkColor: AppColors.primary,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      message: _selectedStatus == null
                          ? 'No referrals yet'
                          : 'No ${_selectedStatus!.label.toLowerCase()} referrals',
                      subtitle:
                          'Referrals created by CHWs or Doctors will appear here',
                      icon: Icons.local_hospital_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(allReferralsProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ReferralCard(referral: filtered[i]),
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => ListView(
        children: List.generate(
            3,
            (_) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: LoadingListItem())),
      ),
      error: (e, _) => EmptyState(
          message: 'Failed to load referrals',
          subtitle: e.toString(),
          icon: Icons.error_outline),
    );

    if (widget.embedded) {
      return Scaffold(
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateReferral,
          icon: const Icon(Icons.add),
          label: const Text('Create Referral'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateReferral,
        icon: const Icon(Icons.add),
        label: const Text('Create Referral'),
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final ReferralModel referral;
  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    final isDoctor = referral.raisedByRole.toLowerCase() == 'doctor';
    final creatorText = isDoctor
        ? 'Created by Doctor — ${referral.raisedByName.isNotEmpty ? referral.raisedByName : 'Doctor'}'
        : 'Created by CHW — ${referral.raisedByName.isNotEmpty ? referral.raisedByName : 'CHW'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ReferralDetailScreen(referral: referral)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(referral.patientName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  _StatusChip(status: referral.currentStatus),
                ],
              ),
              const SizedBox(height: 4),
              Text('→ ${referral.referredTo}',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(referral.reason,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),

              // Creator Identification Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDoctor
                      ? AppColors.primaryContainer.withValues(alpha: 0.5)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDoctor
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDoctor ? Icons.medical_services_outlined : Icons.person_outline,
                      size: 13,
                      color: isDoctor ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      creatorText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDoctor ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Compact stepper
              if (!referral.currentStatus.isTerminal ||
                  referral.currentStatus == ReferralStatus.completed) ...[
                ReferralStatusStepper(
                    currentStatus: referral.currentStatus, compact: true),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: Text(DateFormatters.timeAgo(referral.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReferralStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11, color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
