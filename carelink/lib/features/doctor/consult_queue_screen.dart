import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/risk_badge.dart';
import '../../data/repositories/consult_repository.dart';
import '../../models/consult_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consult_provider.dart';
import 'consult_chat_screen.dart';

class ConsultQueueScreen extends ConsumerWidget {
  final bool embedded;
  const ConsultQueueScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingConsultsProvider);

    final body = pendingAsync.when(
      data: (consults) {
        if (consults.isEmpty) {
          return const EmptyState(
            message: 'No pending consultations',
            subtitle: 'Consultation requests from CHWs will appear here',
            icon: Icons.queue_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingConsultsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: consults.length,
            itemBuilder: (_, i) => _ConsultCard(consult: consults[i]),
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
          message: 'Failed to load queue',
          subtitle: e.toString(),
          icon: Icons.error_outline),
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Consultation Queue')),
      body: body,
    );
  }
}

class _ConsultCard extends ConsumerWidget {
  final ConsultRequestModel consult;
  const _ConsultCard({required this.consult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgencyColor = _urgencyColor(consult.urgency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgency banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: urgencyColor.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Icon(_urgencyIcon(consult.urgency),
                    size: 14, color: urgencyColor),
                const SizedBox(width: 6),
                Text(consult.urgency.label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: urgencyColor,
                        letterSpacing: 0.5)),
                const Spacer(),
                Text(DateFormatters.timeAgo(consult.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        _initials(consult.patientName),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(consult.patientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('CHW: ${consult.chwName}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (consult.triageRisk != null)
                      RiskBadge(riskLevel: consult.triageRisk!),
                  ],
                ),
                const SizedBox(height: 10),
                Text(consult.reason,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _accept(context, ref),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Accept'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.riskLow,
                          side: BorderSide(
                              color: AppColors.riskLow.withOpacity(0.6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openChat(context),
                        icon: const Icon(Icons.chat_outlined, size: 16),
                        label: const Text('View / Chat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final user = ref.read(userProfileProvider);
    if (user == null) return;
    try {
      await ConsultRepository().acceptConsult(
        consultId: consult.id,
        doctorUid: user.uid,
        doctorName: user.displayName,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Consultation accepted'),
            backgroundColor: AppColors.riskLow));
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ConsultChatScreen(consult: consult.copyWith(
                      doctorUid: user.uid,
                      doctorName: user.displayName,
                      status: ConsultStatus.accepted,
                    ))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _openChat(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ConsultChatScreen(consult: consult)));
  }

  Color _urgencyColor(UrgencyLevel u) {
    switch (u) {
      case UrgencyLevel.emergency: return AppColors.riskHigh;
      case UrgencyLevel.urgent: return AppColors.riskMedium;
      case UrgencyLevel.routine: return AppColors.primary;
    }
  }

  IconData _urgencyIcon(UrgencyLevel u) {
    switch (u) {
      case UrgencyLevel.emergency: return Icons.emergency_outlined;
      case UrgencyLevel.urgent: return Icons.priority_high;
      case UrgencyLevel.routine: return Icons.schedule_outlined;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }
}
