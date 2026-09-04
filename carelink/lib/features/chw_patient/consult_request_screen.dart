import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/repositories/consult_repository.dart';
import '../../data/repositories/patient_repository.dart';
import '../../models/consult_request_model.dart';
import '../../models/patient_model.dart';
import '../../models/triage_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/triage_provider.dart';

class ConsultRequestScreen extends ConsumerStatefulWidget {
  final PatientModel patient;
  const ConsultRequestScreen({super.key, required this.patient});

  @override
  ConsumerState<ConsultRequestScreen> createState() =>
      _ConsultRequestScreenState();
}

class _ConsultRequestScreenState extends ConsumerState<ConsultRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  UrgencyLevel _urgency = UrgencyLevel.routine;
  bool _loading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(userProfileProvider);
      final latestTriage =
          await PatientRepository().getLatestTriage(widget.patient.id);

      final consult = ConsultRequestModel(
        id: '',
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        chwUid: user?.uid ?? '',
        chwName: user?.displayName ?? '',
        reason: _reasonCtrl.text.trim(),
        urgency: _urgency,
        status: ConsultStatus.pending,
        triageResultId: latestTriage?.id,
        triageRisk: latestTriage?.riskLevel,
        createdAt: DateTime.now(),
      );
      await ConsultRepository().createConsult(consult);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Consultation request sent to doctor'),
            backgroundColor: AppColors.riskLow));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.riskHigh));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestTriageAsync =
        ref.watch(latestTriageProvider(widget.patient.id));

    return AppScaffold(
      appBar: AppBar(title: const Text('Request Teleconsult')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _patientCard(),
              const SizedBox(height: 16),
              latestTriageAsync.when(
                data: (triage) {
                  if (triage == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.monitor_heart_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('Latest triage: ',
                          style: TextStyle(fontSize: 13)),
                      Text(triage.riskLevel.label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _riskColor(triage.riskLevel))),
                      Text('  (${triage.riskScore}/100)',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ]),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Text('CONSULTATION DETAILS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason for Consultation *',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                validator: (v) => Validators.minLength(v, 10, 'Reason'),
              ),
              const SizedBox(height: 16),
              const Text('Urgency Level',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ...UrgencyLevel.values.map((u) => RadioListTile<UrgencyLevel>(
                    value: u,
                    groupValue: _urgency,
                    onChanged: (v) => setState(() => _urgency = v!),
                    title: Text(u.label),
                    subtitle: Text(_urgencySubtitle(u)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined),
                  label: Text(_loading ? 'Sending…' : 'Send to Doctor'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _patientCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(widget.patient.initials,
              style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.patient.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
            Text(
                '${widget.patient.age}y · ${widget.patient.gender.label} · ${widget.patient.village}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.low:
        return AppColors.riskLow;
    }
  }

  String _urgencySubtitle(UrgencyLevel u) {
    switch (u) {
      case UrgencyLevel.routine:
        return 'Non-urgent, can wait 24–48 hours';
      case UrgencyLevel.urgent:
        return 'Needs attention within a few hours';
      case UrgencyLevel.emergency:
        return 'Life-threatening — immediate attention required';
    }
  }
}
