import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/risk_badge.dart';
import '../../data/repositories/consult_repository.dart';
import '../../models/consult_request_model.dart';
import '../../models/patient_model.dart';
import '../../models/triage_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consult_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/triage_provider.dart';
import '../patient_record/patient_record_screen.dart';
import 'consult_chat_screen.dart';
import 'dummy_video_call_screen.dart';
import 'raise_referral_screen.dart';

class ConsultDetailScreen extends ConsumerStatefulWidget {
  final ConsultRequestModel consult;
  const ConsultDetailScreen({super.key, required this.consult});

  @override
  ConsumerState<ConsultDetailScreen> createState() => _ConsultDetailScreenState();
}

class _ConsultDetailScreenState extends ConsumerState<ConsultDetailScreen> {
  bool _accepting = false;

  Future<void> _acceptConsultation() async {
    final user = ref.read(activeUserProfileProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No active doctor profile found'),
            backgroundColor: AppColors.riskHigh,
          ),
        );
      }
      return;
    }

    setState(() => _accepting = true);
    try {
      await ConsultRepository().acceptConsult(
        consultId: widget.consult.id,
        doctorUid: user.uid,
        doctorName: user.displayName,
      );
      ref.invalidate(pendingConsultsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation accepted successfully'),
            backgroundColor: AppColors.riskLow,
          ),
        );
        // Refresh & open chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultChatScreen(
              consult: widget.consult.copyWith(
                doctorUid: user.uid,
                doctorName: user.displayName,
                status: ConsultStatus.accepted,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: AppColors.riskHigh,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientByIdProvider(widget.consult.patientId));
    final latestTriageAsync = ref.watch(latestTriageProvider(widget.consult.patientId));

    return AppScaffold(
      appBar: AppBar(
        title: Text('Consult — ${widget.consult.patientName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Full Patient History',
            onPressed: () {
              final patient = patientAsync.valueOrNull;
              if (patient != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientRecordScreen(patient: patient),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Urgency Banner
            _HeaderBanner(consult: widget.consult),
            const SizedBox(height: 16),

            // Patient Overview
            patientAsync.when(
              data: (patient) => patient == null
                  ? const SizedBox.shrink()
                  : _PatientSummaryCard(patient: patient),
              loading: () => const LoadingListItem(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Latest Triage & Vitals
            latestTriageAsync.when(
              data: (triage) => triage == null
                  ? _NoTriageCard(consult: widget.consult)
                  : _TriageDetailsCard(triage: triage),
              loading: () => const LoadingListItem(),
              error: (e, _) => Text('Error loading triage: $e'),
            ),
            const SizedBox(height: 24),

            // Quick Actions Bar
            const Text(
              'ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            if (widget.consult.status == ConsultStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _accepting ? null : _acceptConsultation,
                  icon: _accepting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_accepting ? 'Accepting…' : 'Accept Consultation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultChatScreen(consult: widget.consult),
                      ),
                    ),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Open Chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DummyVideoCallScreen(
                          patientName: widget.consult.patientName,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.video_call_outlined),
                    label: const Text('Video Call'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RaiseReferralScreen(consult: widget.consult),
                  ),
                ),
                icon: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                label: const Text('Create Referral'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final ConsultRequestModel consult;
  const _HeaderBanner({required this.consult});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Status: ${consult.status.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const Spacer(),
                if (consult.triageRisk != null)
                  RiskBadge(riskLevel: consult.triageRisk!),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${consult.reason}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Requested by CHW: ${consult.chwName}  ·  ${DateFormatters.timeAgo(consult.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientSummaryCard extends StatelessWidget {
  final PatientModel patient;
  const _PatientSummaryCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Information',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    patient.initials,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(
                        '${patient.age}y · ${patient.gender.label} · ${patient.village}, ${patient.district}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Blood Group: ${patient.bloodGroup ?? 'Unknown'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TriageDetailsCard extends StatelessWidget {
  final TriageResultModel triage;
  const _TriageDetailsCard({required this.triage});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Latest Triage & Vitals',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Spacer(),
                RiskBadge(
                  riskLevel: triage.riskLevel,
                  showScore: true,
                  score: triage.riskScore,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Chief Complaint: ${triage.chiefComplaint}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Vitals Grid
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (triage.temperature != null)
                  _VitalPill(
                      label: 'Temperature',
                      value: '${triage.temperature!.toStringAsFixed(1)} °C',
                      icon: Icons.thermostat_outlined),
                if (triage.bpSystolic != null && triage.bpDiastolic != null)
                  _VitalPill(
                      label: 'Blood Pressure',
                      value: '${triage.bpSystolic}/${triage.bpDiastolic} mmHg',
                      icon: Icons.favorite_outline),
                if (triage.heartRate != null)
                  _VitalPill(
                      label: 'Pulse',
                      value: '${triage.heartRate} bpm',
                      icon: Icons.monitor_heart_outlined),
                if (triage.spO2 != null)
                  _VitalPill(
                      label: 'SpO₂',
                      value: '${triage.spO2}%',
                      icon: Icons.air_outlined),
                if (triage.respiratoryRate != null)
                  _VitalPill(
                      label: 'Resp Rate',
                      value: '${triage.respiratoryRate} /min',
                      icon: Icons.compress_outlined),
              ],
            ),

            if (triage.aiNote != null && triage.aiNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
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
        ),
      ),
    );
  }
}

class _VitalPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _VitalPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoTriageCard extends StatelessWidget {
  final ConsultRequestModel consult;
  const _NoTriageCard({required this.consult});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No recent triage recorded for this patient.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
