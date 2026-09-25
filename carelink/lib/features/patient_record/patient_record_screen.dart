import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/risk_badge.dart';
import '../../models/consult_request_model.dart';
import '../../models/diagnostic_test_model.dart';
import '../../models/follow_up_task_model.dart';
import '../../models/patient_model.dart';
import '../../models/referral_model.dart';
import '../../models/triage_result_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consult_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/referral_provider.dart';
import '../../providers/triage_provider.dart';
import '../chw_patient/consult_request_screen.dart';
import '../doctor/consult_chat_screen.dart';
import '../doctor/raise_referral_screen.dart';
import '../care_orchestration/care_case_detail_screen.dart';
import '../../providers/care_orchestration_provider.dart';
import '../../data/repositories/patient_repository.dart';
import 'create_follow_up_dialog.dart';
import 'timeline_tile.dart';

enum _TimelineFilter { all, vitals, consults, referrals, followups, diagnostics }

class PatientRecordScreen extends ConsumerStatefulWidget {
  final PatientModel patient;
  const PatientRecordScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientRecordScreen> createState() => _PatientRecordScreenState();
}

class _PatientRecordScreenState extends ConsumerState<PatientRecordScreen> {
  _TimelineFilter _filter = _TimelineFilter.all;

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(activeUserProfileProvider)?.role;
    final triageAsync = ref.watch(triageResultsByPatientProvider(widget.patient.id));
    final consultsAsync = ref.watch(patientConsultsProvider(widget.patient.id));
    final referralsAsync = ref.watch(referralsByPatientProvider(widget.patient.id));
    final followUpsAsync = ref.watch(followUpTasksByPatientProvider(widget.patient.id));
    final diagnosticsAsync = ref.watch(patientDiagnosticTestsProvider(widget.patient.id));

    return AppScaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'Schedule Follow-up',
            onPressed: () => CreateFollowUpDialog.show(context, widget.patient),
          ),
          IconButton(
            icon: const Icon(Icons.local_hospital_outlined),
            tooltip: 'Create Referral',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RaiseReferralScreen(patient: widget.patient)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          _PatientHeaderCard(
            patient: widget.patient,
            userRole: userRole,
          ),

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

          // Timeline List
          Expanded(
            child: _buildTimeline(
              triageAsync: triageAsync,
              consultsAsync: consultsAsync,
              referralsAsync: referralsAsync,
              followUpsAsync: followUpsAsync,
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
    required AsyncValue<List<FollowUpTaskModel>> followUpsAsync,
    required AsyncValue<List<DiagnosticTestModel>> diagnosticsAsync,
  }) {
    final triageItems = triageAsync.valueOrNull ?? [];
    final consultItems = consultsAsync.valueOrNull ?? [];
    final referralItems = referralsAsync.valueOrNull ?? [];
    final followUpItems = followUpsAsync.valueOrNull ?? [];
    final diagnosticItems = diagnosticsAsync.valueOrNull ?? [];

    final isLoading = triageAsync.isLoading ||
        consultsAsync.isLoading ||
        referralsAsync.isLoading ||
        followUpsAsync.isLoading ||
        diagnosticsAsync.isLoading;

    if (isLoading) {
      return ListView(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: LoadingListItem(),
          ),
        ),
      );
    }

    final List<_TimelineEvent> events = [];

    if (_filter == _TimelineFilter.all || _filter == _TimelineFilter.vitals) {
      for (final t in triageItems) {
        events.add(_TimelineEvent(type: 'triage', timestamp: t.assessedAt, data: t));
      }
    }
    if (_filter == _TimelineFilter.all || _filter == _TimelineFilter.consults) {
      for (final c in consultItems) {
        events.add(_TimelineEvent(type: 'consult', timestamp: c.createdAt, data: c));
      }
    }
    if (_filter == _TimelineFilter.all || _filter == _TimelineFilter.referrals) {
      for (final r in referralItems) {
        events.add(_TimelineEvent(type: 'referral', timestamp: r.createdAt, data: r));
      }
    }
    if (_filter == _TimelineFilter.all || _filter == _TimelineFilter.followups) {
      for (final f in followUpItems) {
        events.add(_TimelineEvent(type: 'followup', timestamp: f.dueDate, data: f));
      }
    }
    if (_filter == _TimelineFilter.all || _filter == _TimelineFilter.diagnostics) {
      for (final d in diagnosticItems) {
        events.add(_TimelineEvent(type: 'diagnostic', timestamp: d.orderedAt, data: d));
      }
    }

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
        return _TriageTimelineCard(triage: event.data as TriageResultModel);
      case 'consult':
        return _ConsultTimelineCard(consult: event.data as ConsultRequestModel);
      case 'referral':
        return _ReferralTimelineCard(referral: event.data as ReferralModel);
      case 'followup':
        return _FollowUpTimelineCard(task: event.data as FollowUpTaskModel);
      case 'diagnostic':
        return _DiagnosticTimelineCard(test: event.data as DiagnosticTestModel);
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
      case _TimelineFilter.followups:
        return 'Follow-ups';
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

class _PatientHeaderCard extends ConsumerWidget {
  final PatientModel patient;
  final UserRole? userRole;

  const _PatientHeaderCard({
    required this.patient,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDoctor = userRole == UserRole.doctor;
    final casesAsync = ref.watch(careCasesByPatientProvider(patient.id));

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Info + Risk Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    patient.initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${patient.age}y · ${patient.gender.label} · ${patient.bloodGroup ?? 'Blood group unknown'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${patient.village}, ${patient.district}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (patient.triageRisk != null)
                  RiskBadge(riskLevel: patient.triageRisk!),
              ],
            ),

            if (patient.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: patient.chronicConditions.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const Divider(height: 20),

            // Care Case Journey Primary Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final existingCases = casesAsync.valueOrNull ?? [];
                  if (existingCases.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CareCaseDetailScreen(careCase: existingCases.first)),
                    );
                  } else {
                    // Create default Care Case for patient
                    final triage = await PatientRepository().getLatestTriage(patient.id);
                    if (triage != null) {
                      final newCase = await ref.read(careOrchestrationEngineProvider).orchestrateCareCase(
                            patient: patient,
                            triage: triage,
                            chwUid: 'chw_uid',
                            chwName: 'Sunita Kamble (CHW)',
                          );
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CareCaseDetailScreen(careCase: newCase)),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please perform Digital Triage first to create a Care Case.')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.hub_outlined, size: 18),
                label: const Text('Open Care Case Journey (Smart Engine)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Patient Quick Actions Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => CreateFollowUpDialog.show(context, patient),
                    icon: const Icon(Icons.event_note_outlined, size: 16),
                    label: const Text('+ Follow-up', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RaiseReferralScreen(patient: patient)),
                    ),
                    icon: const Icon(Icons.local_hospital_outlined, size: 16),
                    label: const Text('Referral', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (!isDoctor) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ConsultRequestScreen(patient: patient)),
                      ),
                      icon: const Icon(Icons.video_call_outlined, size: 16),
                      label: const Text('Consult', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timeline Card Components ───────────────────────────────────────────────

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
              child: Text(
                'Triage Assessment',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            RiskBadge(riskLevel: triage.riskLevel, showScore: true, score: triage.riskScore),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Chief Complaint: ${triage.chiefComplaint}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Structured Vitals Grid
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (triage.temperature != null)
              _vitalChip('Temp', '${triage.temperature!.toStringAsFixed(1)} °C', Icons.thermostat_outlined),
            if (triage.bpSystolic != null && triage.bpDiastolic != null)
              _vitalChip('BP', '${triage.bpSystolic}/${triage.bpDiastolic} mmHg', Icons.favorite_outline),
            if (triage.spO2 != null)
              _vitalChip('SpO₂', '${triage.spO2}%', Icons.air_outlined),
            if (triage.heartRate != null)
              _vitalChip('Pulse', '${triage.heartRate} bpm', Icons.monitor_heart_outlined),
            if (triage.respiratoryRate != null)
              _vitalChip('Resp', '${triage.respiratoryRate} /min', Icons.compress_outlined),
          ],
        ),

        if (triage.aiNote != null && triage.aiNote!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    triage.aiNote!,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _vitalChip(String label, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            val,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
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
              child: Text(
                'Teleconsultation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _statusBadge(consult.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(consult.reason, style: const TextStyle(fontSize: 13)),
        if (consult.doctorName != null) ...[
          const SizedBox(height: 4),
          Text(
            'Doctor: ${consult.doctorName}',
            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
        if (consult.prescriptionNote != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Rx: ${consult.prescriptionNote}', style: const TextStyle(fontSize: 12)),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ConsultChatScreen(consult: consult)),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ReferralTimelineCard extends StatelessWidget {
  final ReferralModel referral;
  const _ReferralTimelineCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    final isDoctor = referral.raisedByRole.toLowerCase() == 'doctor';
    final creatorText = isDoctor
        ? 'Created by Doctor — ${referral.raisedByName.isNotEmpty ? referral.raisedByName : 'Doctor'}'
        : 'Created by CHW — ${referral.raisedByName.isNotEmpty ? referral.raisedByName : 'CHW'}';

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
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
        Text(referral.reason, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),

        // Creator Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDoctor
                ? AppColors.primaryContainer.withValues(alpha: 0.5)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDoctor ? Icons.medical_services_outlined : Icons.person_outline,
                size: 11,
                color: isDoctor ? AppColors.primaryDark : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                creatorText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDoctor ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
      child: Text(
        s.label,
        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FollowUpTimelineCard extends StatelessWidget {
  final FollowUpTaskModel task;
  const _FollowUpTimelineCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text('Follow-up Task',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: task.isDone ? AppColors.riskLowLight : AppColors.riskMediumLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                task.isDone ? 'Completed' : 'Pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: task.isDone ? AppColors.riskLow : AppColors.riskMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        if (task.description != null && task.description!.isNotEmpty)
          Text(task.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('Due: ${DateFormatters.formatDate(task.dueDate)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
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
        Text(test.testName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        if (test.labName != null)
          Text('Lab: ${test.labName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (test.result != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Result: ${test.result}', style: const TextStyle(fontSize: 12)),
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
      child: Text(
        s.label,
        style: TextStyle(
          fontSize: 11,
          color: isDone ? AppColors.riskLow : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
