import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/repositories/referral_repository.dart';
import '../../models/consult_request_model.dart';
import '../../models/referral_model.dart';
import '../../providers/auth_provider.dart';

class RaiseReferralScreen extends ConsumerStatefulWidget {
  final ConsultRequestModel consult;
  const RaiseReferralScreen({super.key, required this.consult});

  @override
  ConsumerState<RaiseReferralScreen> createState() =>
      _RaiseReferralScreenState();
}

class _RaiseReferralScreenState extends ConsumerState<RaiseReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  String _hospital = 'Nashik Civil Hospital';
  UrgencyLevel _urgency = UrgencyLevel.urgent;
  bool _loading = false;

  static const _hospitals = [
    'Nashik Civil Hospital',
    'Nashik District Hospital — Cardiology',
    'Nashik District Hospital — General',
    'Nashik District Hospital — OBG',
    'Nashik District Hospital — Paediatrics',
    'Igatpuri Rural Hospital',
    'Trimbakeshwar PHC',
    'Dindori Sub-District Hospital',
    'Dr. S. Mehta (Cardiology Specialist)',
    'Other (specify in reason)',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _diagnosisCtrl.dispose();
    super.dispose();
  }

  Future<void> _raise() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(userProfileProvider);
      final now = DateTime.now();
      final entry = ReferralStatusEntry(
        status: ReferralStatus.created,
        updatedByUid: user?.uid ?? '',
        updatedByName: user?.displayName ?? '',
        note: 'Referral raised via teleconsultation',
        timestamp: now,
      );
      final referral = ReferralModel(
        id: '',
        patientId: widget.consult.patientId,
        patientName: widget.consult.patientName,
        raisedByUid: user?.uid ?? '',
        raisedByName: user?.displayName ?? '',
        raisedByRole: 'doctor',
        fromFacility: user?.facilityName ?? 'PHC Ward 3',
        referredTo: _hospital,
        reason: _reasonCtrl.text.trim(),
        urgency: _urgency,
        diagnosis: _diagnosisCtrl.text.trim().isEmpty
            ? null
            : _diagnosisCtrl.text.trim(),
        currentStatus: ReferralStatus.created,
        statusHistory: [entry],
        consultRequestId: widget.consult.id,
        createdAt: now,
      );
      await ReferralRepository().createReferral(referral);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Referral raised successfully'),
            backgroundColor: AppColors.riskLow));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'),
                backgroundColor: AppColors.riskHigh));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Raise Referral')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      widget.consult.patientName.split(' ').map((p) => p[0]).take(2).join().toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.consult.patientName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark)),
                    Text('Consult: ${widget.consult.reason}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),

              const Text('REFERRAL DETAILS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1)),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _hospital,
                decoration: const InputDecoration(
                  labelText: 'Refer To *',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
                items: _hospitals
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => setState(() => _hospital = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UrgencyLevel>(
                value: _urgency,
                decoration: const InputDecoration(
                  labelText: 'Urgency Level *',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                items: UrgencyLevel.values
                    .map((u) => DropdownMenuItem(
                        value: u, child: Text(u.label)))
                    .toList(),
                onChanged: (v) => setState(() => _urgency = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diagnosisCtrl,
                decoration: const InputDecoration(
                  labelText: 'Working Diagnosis',
                  prefixIcon: Icon(Icons.biotech_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason for Referral *',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                validator: (v) => Validators.minLength(v, 10, 'Reason'),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _raise,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined),
                  label: Text(_loading ? 'Sending…' : 'Raise Referral'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
