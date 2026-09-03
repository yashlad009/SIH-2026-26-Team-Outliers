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

class ReferralListScreen extends ConsumerWidget {
  final bool embedded;
  const ReferralListScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(allReferralsProvider);

    final body = referralsAsync.when(
      data: (referrals) {
        if (referrals.isEmpty) {
          return const EmptyState(
            message: 'No referrals yet',
            subtitle: 'Referrals raised by doctors will appear here',
            icon: Icons.local_hospital_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allReferralsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: referrals.length,
            itemBuilder: (_, i) => _ReferralCard(referral: referrals[i]),
          ),
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

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: body,
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final ReferralModel referral;
  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    final isTerminal = referral.currentStatus.isTerminal;

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
                      color: AppColors.primary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(referral.reason,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              // Compact stepper
              if (!referral.currentStatus.isTerminal ||
                  referral.currentStatus == ReferralStatus.completed) ...[
                ReferralStatusStepper(
                    currentStatus: referral.currentStatus, compact: true),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dr. ${referral.raisedByName}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text(DateFormatters.timeAgo(referral.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
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
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11, color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
