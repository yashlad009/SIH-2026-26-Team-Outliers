import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/risk_badge.dart';
import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/triage_provider.dart';
import '../../providers/consult_provider.dart';
import '../../providers/referral_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/triage_result_model.dart';
import '../../models/consult_request_model.dart';
import '../../models/referral_model.dart';
import '../../models/diagnostic_test_model.dart';
import '../chw_patient/triage_form_screen.dart';
import '../chw_patient/consult_request_screen.dart';
import '../doctor/consult_chat_screen.dart';
import 'timeline_tile.dart';

enum _TimelineFilter { all, vitals, consults, referrals, diagnostics }

class PatientRecordScreen extends ConsumerStatefulWidget {
  final PatientModel patient;
  const PatientRecordScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientRecordScreen> createState() =>
      _PatientRecordScreenState();
}

class _PatientRecordScreenState
    extends ConsumerState<PatientRecordScreen> {
  _TimelineFilter _filter = _TimelineFilter.all;

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(activeUserProfileProvider)?.role;
    final triageAsync =
        ref.watch(triageResultsByPatientProvider(widget.patient.id));
    final consultsAsync =
        ref.watch(patientConsultsProvider(widget.patient.id));
    final referralsAsync =
        ref.watch(referralsByPatientProvider(widget.patient.id));
    final diagnosticsAsync =
        ref.watch(patientDiagnosticTestsProvider(widget.patient.id));

    return AppScaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        actions: [
          if (userRole?.name == 'chw') ...[
            IconButton(
              icon: const Icon(Icons.monitor_heart_outlined),
              tooltip: 'Triage',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          TriageFormScreen(patient: widget.patient))),
            ),
            IconButton(
              icon: const Icon(Icons.video_call_outlined),
              tooltip: 'Request Consult',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ConsultRequestScreen(patient: widget.patient))),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Patient header card
          _PatientHeaderCard(patient: widget.patient),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _TimelineFilter.values.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(f)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Timeline
          Expanded(
            child: _buildTimeline(
              triageAsync: triageAsync,
              consultsAsync: consultsAsync,
              referralsAsync: referralsAsync,
              diagnosticsAsync: diagnosticsAsync,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline({
    required AsyncValue<List<TriageResultModel>> triageAsync,
    required AsyncValue<List<ConsultRequestModel>> consultsAsync,
    required AsyncValue<List<ReferralModel>> referralsAsync,
    required AsyncValue<List<DiagnosticTestModel>> diagnosticsAsync,
  }) {
    // Combine all into timeline events
    final triageItems = triageAsync.valueOrNull ?? [];
    final consultItems = consultsAsync.valueOrNull ?? [];
    final referralItems = referralsAsync.valueOrNull ?? [];
    final diagnosticItems = diagnosticsAsync.valueOrNull ?? [];

    final isLoading = triageAsync.isLoading ||
        consultsAsync.isLoading ||
        referralsAsync.isLoading ||
        diagnosticsAsync.isLoading;

    if (isLoading) {
      return ListView(
        children: List.generate(3, (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: LoadingListItem())),
      );
    }

    // Build unified event list
    final List<_TimelineEvent> events = [];

    if (_filter == _TimelineFilter.all ||
        _filter == _TimelineFilter.vitals) {
      for (final t in triageItems) {
        events.add(_TimelineEvent(
          type: 'triage',
          timestamp: t.assessedAt,
          data: t,
        ));
      }
    }
    if (_filter == _TimelineFilter.all ||
        _filter == _TimelineFilter.consults) {
      for (final c in consultItems) {
        events.add(_TimelineEvent(
          type: 'consult',
          timestamp: c.createdAt,
          data: c,
        ));
      }
    }
    if (_filter == _TimelineFilter.all ||
        _filter == _TimelineFilter.referrals) {
      for (final r in referralItems) {
        events.add(_TimelineEvent(
          type: 'referral',
          timestamp: r.createdAt,
          data: r,
        ));
      }
    }
    if (_filter == _TimelineFilter.all ||
        _filter == _TimelineFilter.diagnostics) {
      for (final d in diagnosticItems) {
        events.add(_TimelineEvent(
          type: 'diagnostic',
          timestamp: d.orderedAt,
          data: d,
        ));
      }
    }

    // Sort newest first
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (events.isEmpty) {
      return EmptyState(
        message: _filter == _TimelineFilter.all
            ? 'No records yet'
            : 'No ${_filterLabel(_filter).toLowerCase()} records',
        subtitle: 'Records will appear here as care is provided',
        icon: Icons.timeline_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i];
        final isLast = i == events.length - 1;
        return TimelineTile(
          event: e.type,
          timestamp: e.timestamp,
          isLast: isLast,
          child: _buildEventCard(e),
        );
      },
    );
  }

  Widget _buildEventCard(_TimelineEvent event) {
    switch (event.type) {
      case 'triage':
        final t = event.data as TriageResultModel;
        return _TriageTimelineCard(triage: t);
      case 'consult':
        final c = event.data as ConsultRequestModel;
        return _ConsultTimelineCard(consult: c);
      case 'referral':
        final r = event.data as ReferralModel;
        return _ReferralTimelineCard(referral: r);
      case 'diagnostic':
        final d = event.data as DiagnosticTestModel;
        return _DiagnosticTimelineCard(test: d);
      default:
        return const SizedBox.shrink();
    }
  }

  String _filterLabel(_TimelineFilter f) {
    switch (f) {
      case _TimelineFilter.all:
        return 'All';
      case _TimelineFilter.vitals:
        return 'Triage';
      case _TimelineFilter.consults:
        return 'Consults';
      case _TimelineFilter.referrals:
        return 'Referrals';
      case _TimelineFilter.diagnostics:
        return 'Tests';
    }
  }
}

class _TimelineEvent {
  final String type;
  final DateTime timestamp;
  final dynamic data;
  const _TimelineEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class _PatientHeaderCard extends StatelessWidget {
  final PatientModel patient;
  const _PatientHeaderCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primaryContainer,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(patient.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.primaryDark)),
                Text(
                    '${patient.age}y · ${patient.gender.label} · ${patient.bloodGroup ?? 'Blood group unknown'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                Text('${patient.village}, ${patient.district}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                if (patient.chronicConditions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: patient.chronicConditions.map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline event cards ───────────────────────────────────────────────────

class _TriageTimelineCard extends StatelessWidget {
  final TriageResultModel triage;
  const _TriageTimelineCard({required this.triage});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text('Triage Assessment',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            RiskBadge(riskLevel: triage.riskLevel, showScore: true, score: triage.riskScore),
          ],
        ),
        const SizedBox(height: 6),
        Text(triage.chiefComplaint,
            style: const TextStyle(fontSize: 13)),
        if (triage.bpSystolic != null || triage.spO2 != null) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              if (triage.temperature != null)
                _vitalChip('🌡 ${triage.temperature!.toStringAsFixed(1)}°C'),
              if (triage.bpSystolic != null)
                _vitalChip('💉 ${triage.bpSystolic}/${triage.bpDiastolic}'),
              if (triage.spO2 != null) _vitalChip('🫁 SpO₂ ${triage.spO2}%'),
              if (triage.heartRate != null)
                _vitalChip('❤️ ${triage.heartRate} bpm'),
            ],
          ),
        ],
        if (triage.aiNote != null && triage.aiNoteGenerated) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(triage.aiNote!,
                      style: const TextStyle(fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _vitalChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _ConsultTimelineCard extends StatelessWidget {
  final ConsultRequestModel consult;
  const _ConsultTimelineCard({required this.consult});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text('Teleconsultation',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            _statusBadge(consult.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(consult.reason,
            style: const TextStyle(fontSize: 13)),
        if (consult.doctorName != null) ...[
          const SizedBox(height: 4),
          Text('Doctor: ${consult.doctorName}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
        if (consult.prescriptionNote != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Rx: ${consult.prescriptionNote}',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConsultChatScreen(consult: consult),
              ),
            ),
            icon: const Icon(Icons.chat_outlined, size: 16),
            label: const Text('Open Chat', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(ConsultStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case ConsultStatus.pending:
        bg = AppColors.riskMediumLight;
        fg = AppColors.riskMedium;
        break;
      case ConsultStatus.accepted:
      case ConsultStatus.inProgress:
        bg = AppColors.primaryContainer;
        fg = AppColors.primary;
        break;
      case ConsultStatus.closed:
        bg = AppColors.riskLowLight;
        fg = AppColors.riskLow;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class _ReferralTimelineCard extends StatelessWidget {
  final ReferralModel referral;
  const _ReferralTimelineCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text('Referral',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            _statusChip(referral.currentStatus),
          ],
        ),
        const SizedBox(height: 4),
        Text('→ ${referral.referredTo}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.primary)),
        Text(referral.reason,
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _statusChip(ReferralStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(s.label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _DiagnosticTimelineCard extends StatelessWidget {
  final DiagnosticTestModel test;
  const _DiagnosticTimelineCard({required this.test});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text('Diagnostic Test',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            _statusChip(test.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(test.testName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        if (test.labName != null)
          Text('Lab: ${test.labName}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (test.result != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Result: ${test.result}',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ],
    );
  }

  Widget _statusChip(TestStatus s) {
    final isDone = s == TestStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDone ? AppColors.riskLowLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(s.label,
          style: TextStyle(
              fontSize: 11,
              color: isDone ? AppColors.riskLow : AppColors.textSecondary,
              fontWeight: FontWeight.w600)),
    );
  }
}
