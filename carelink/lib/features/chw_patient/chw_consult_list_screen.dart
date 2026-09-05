import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/risk_badge.dart';
import '../../models/consult_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consult_provider.dart';
import '../doctor/consult_chat_screen.dart';

class ChwConsultListScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const ChwConsultListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ChwConsultListScreen> createState() => _ChwConsultListScreenState();
}

class _ChwConsultListScreenState extends ConsumerState<ChwConsultListScreen> {
  ConsultStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(activeUserProfileProvider);
    final consultsAsync = user != null
        ? ref.watch(chwConsultsProvider(user.uid))
        : const AsyncData<List<ConsultRequestModel>>([]);

    final body = consultsAsync.when(
      data: (consults) {
        final filtered = _selectedStatus == null
            ? consults
            : consults.where((c) => c.status == _selectedStatus).toList();

        return Column(
          children: [
            // Status filter bar
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
                  ...ConsultStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status.label),
                        selected: _selectedStatus == status,
                        onSelected: (_) => setState(() => _selectedStatus = status),
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
                          ? 'No teleconsultations'
                          : 'No ${_selectedStatus!.label.toLowerCase()} teleconsultations',
                      subtitle: 'Requested consultations with doctors will appear here',
                      icon: Icons.video_call_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (user != null) {
                          ref.invalidate(chwConsultsProvider(user.uid));
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ChwConsultCard(consult: filtered[i]),
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
        message: 'Failed to load consultations',
        subtitle: e.toString(),
        icon: Icons.error_outline,
      ),
    );

    if (widget.embedded) return body;
    return AppScaffold(
      appBar: AppBar(title: const Text('Teleconsultations')),
      body: body,
    );
  }
}

class _ChwConsultCard extends StatelessWidget {
  final ConsultRequestModel consult;
  const _ChwConsultCard({required this.consult});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(consult.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Urgency Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    consult.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (consult.triageRisk != null) RiskBadge(riskLevel: consult.triageRisk!),
              ],
            ),
            const SizedBox(height: 10),

            // Patient Name & Doctor Info
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consult.patientName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        consult.doctorName != null
                            ? 'Doctor: ${consult.doctorName}'
                            : 'Awaiting doctor assignment',
                        style: TextStyle(
                          fontSize: 12,
                          color: consult.doctorName != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: consult.doctorName != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormatters.timeAgo(consult.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Reason: ${consult.reason}',
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Action Bar — Chat & Details
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConsultChatScreen(consult: consult),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text('Open Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ConsultStatus status) {
    switch (status) {
      case ConsultStatus.pending:
        return AppColors.riskMedium;
      case ConsultStatus.accepted:
      case ConsultStatus.inProgress:
        return AppColors.primary;
      case ConsultStatus.closed:
        return AppColors.riskLow;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }
}
