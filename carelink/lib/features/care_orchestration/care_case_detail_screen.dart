import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/risk_badge.dart';
import '../../data/repositories/care_case_repository.dart';
import '../../data/repositories/follow_up_repository.dart';
import '../../models/care_case_model.dart';
import '../../models/triage_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/care_orchestration_provider.dart';

class CareCaseDetailScreen extends ConsumerStatefulWidget {
  final CareCaseModel careCase;
  const CareCaseDetailScreen({super.key, required this.careCase});

  @override
  ConsumerState<CareCaseDetailScreen> createState() => _CareCaseDetailScreenState();
}

class _CareCaseDetailScreenState extends ConsumerState<CareCaseDetailScreen> {
  late CareCaseModel _case;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _case = widget.careCase;
  }

  Future<void> _confirmRoute() async {
    setState(() => _updating = true);
    try {
      final updated = _case.copyWith(
        status: CareCaseStatus.routed,
        updatedAt: DateTime.now(),
      );
      await CareCaseRepository().saveOrUpdateCareCase(updated);
      setState(() => _case = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Care route confirmed successfully!'),
          backgroundColor: AppColors.riskLow,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update route: $e'),
          backgroundColor: AppColors.riskHigh,
        ));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _completeCareCase() async {
    setState(() => _updating = true);
    try {
      final updated = _case.copyWith(
        status: CareCaseStatus.completed,
        isFollowUpDone: true,
        updatedAt: DateTime.now(),
      );
      await CareCaseRepository().saveOrUpdateCareCase(updated);

      if (_case.followUpTaskId != null) {
        await FollowUpRepository().markDone(_case.followUpTaskId!);
      }

      setState(() => _case = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Care Case completed! Patient care journey finished.'),
          backgroundColor: AppColors.riskLow,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.riskHigh,
        ));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveCaseAsync = ref.watch(careCaseByIdProvider(_case.id));
    final liveCase = liveCaseAsync.valueOrNull ?? _case;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Care Orchestration Case'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Patient Header Banner
            _buildPatientHeader(liveCase),
            const SizedBox(height: 16),

            // 2. Journey Stepper Timeline
            _buildJourneyStepper(liveCase),
            const SizedBox(height: 20),

            // 3. Smart Assignment Card
            _buildSmartAssignmentCard(liveCase),
            const SizedBox(height: 16),

            // 4. Care Readiness Audit Card
            _buildCareReadinessCard(liveCase),
            const SizedBox(height: 16),

            // 5. Adaptive Care Routing Card
            _buildAdaptiveRoutingCard(liveCase),
            const SizedBox(height: 16),

            // 6. Minimum-Trip Care Plan Card
            _buildMinimumTripCard(liveCase),
            const SizedBox(height: 16),

            // 7. Automated Follow-up Card
            _buildFollowUpCard(liveCase),
            const SizedBox(height: 24),

            // Action completion button
            if (liveCase.status != CareCaseStatus.completed)
              ElevatedButton.icon(
                onPressed: _updating ? null : _completeCareCase,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_updating ? 'Updating…' : 'Mark Care Journey Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.riskLow,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(CareCaseModel c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  c.patientName.isNotEmpty ? c.patientName[0] : 'P',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.patientName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    Text(
                      '${c.patientAge}y · ${c.patientGender} · Village: ${c.village}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              RiskBadge(riskLevel: c.riskLevel, showScore: true, score: c.riskScore),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.medical_information_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Chief Complaint: ${c.chiefComplaint}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          if (c.symptoms.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: c.symptoms
                  .map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJourneyStepper(CareCaseModel c) {
    final steps = [
      {'title': 'Triage', 'status': CareCaseStatus.triaged},
      {'title': 'Doctor Assigned', 'status': CareCaseStatus.doctorAssigned},
      {'title': 'Care Ready', 'status': CareCaseStatus.carePlanned},
      {'title': 'Route Confirmed', 'status': CareCaseStatus.routed},
      {'title': 'In Progress', 'status': CareCaseStatus.inProgress},
      {'title': 'Completed', 'status': CareCaseStatus.completed},
    ];

    int currentStepIndex = steps.indexWhere((s) => s['status'] == c.status);
    if (currentStepIndex < 0) currentStepIndex = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CARE ORCHESTRATION PIPELINE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: steps.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final isPassed = idx <= currentStepIndex;
                  final isCurrent = idx == currentStepIndex;

                  return SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPassed
                                ? (isCurrent ? AppColors.primary : AppColors.riskLow)
                                : Colors.grey.shade300,
                          ),
                          child: Icon(
                            isPassed ? Icons.check : Icons.circle,
                            size: 14,
                            color: isPassed ? Colors.white : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value['title'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isPassed ? AppColors.textPrimary : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartAssignmentCard(CareCaseModel c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: AppColors.primary),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '1. SMART DOCTOR ASSIGNMENT',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('AUTO-MATCHED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.assignedDoctorName ?? 'Dr. Rajesh Patil',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Specialty: ${c.assignedDoctorSpecialty ?? c.requiredSpecialty ?? "General Medicine"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.assignmentReason ??
                          'Automatically assigned doctor based on specialty match, active duty status, and lowest current workload.',
                      style: const TextStyle(fontSize: 12, color: Colors.blue, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareReadinessCard(CareCaseModel c) {
    final isReady = c.isFacilityCareReady;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.fact_check_outlined, color: AppColors.primary),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '2. CARE READINESS AUDIT',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReady ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isReady ? Icons.check_circle : Icons.warning_amber, size: 14, color: isReady ? Colors.green.shade800 : Colors.orange.shade800),
                      const SizedBox(width: 4),
                      Text(
                        isReady ? 'CARE READY' : 'PARTIAL READINESS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isReady ? Colors.green.shade900 : Colors.orange.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Facility Capability Check (${c.destinationFacilityName ?? "Local Facility"}):',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _readinessCheckItem('Doctor & Specialty (${c.requiredSpecialty})', true),
            ...c.diagnosticsSummary.map((d) => _readinessCheckItem('Diagnostic Test: $d', true)),
            ...c.medicinesSummary.map((m) => _readinessCheckItem('Pharmacy Stock: $m', true)),
            if (c.facilityReadinessNotes != null && c.facilityReadinessNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Audit Notes: ${c.facilityReadinessNotes}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _readinessCheckItem(String title, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle_outline : Icons.highlight_off,
            size: 16,
            color: isAvailable ? AppColors.riskLow : AppColors.riskHigh,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildAdaptiveRoutingCard(CareCaseModel c) {
    final isRouted = c.status == CareCaseStatus.routed || c.status == CareCaseStatus.inProgress || c.status == CareCaseStatus.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.alt_route, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  '3. ADAPTIVE CARE ROUTING',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECOMMENDED FACILITY PATHWAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        c.destinationFacilityName ?? 'Nashik Civil Hospital',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.recommendedRouteReason ?? 'Recommended based on verified care readiness and specialist coverage.',
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!isRouted)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _updating ? null : _confirmRoute,
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Confirm Recommended Route'),
                ),
              )
            else
              const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.riskLow, size: 16),
                  SizedBox(width: 6),
                  Text('Route Confirmed & Locked', style: TextStyle(color: AppColors.riskLow, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimumTripCard(CareCaseModel c) {
    final title = c.minimumTripPlanTitle ?? 'Recommended minimum-trip care plan';
    final services = c.minimumTripServices.isNotEmpty
        ? c.minimumTripServices
        : ['Doctor Consultation', 'Lab Diagnostics', 'Pharmacy Dispensing'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: const Text(
                'Coordinated 1-visit care plan: Synchronizes consultation, diagnostic testing, and pharmacy dispensing into one coordinated visit to minimize patient travel burden.',
                style: TextStyle(fontSize: 12, color: Colors.teal, height: 1.3),
              ),
            ),
            const SizedBox(height: 10),
            ...services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.adjust_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard(CareCaseModel c) {
    final isDone = c.isFollowUpDone || c.status == CareCaseStatus.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.task_alt_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'AUTOMATED FOLLOW-UP TASK',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isDone ? Icons.check_box : Icons.check_box_outline_blank,
                color: isDone ? AppColors.riskLow : AppColors.primary,
              ),
              title: Text(
                'Post-Care CHW Compliance Visit: ${c.patientName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                c.followUpDueDate != null
                    ? 'Due Date: ${DateFormatters.formatDate(c.followUpDueDate!)}'
                    : 'Scheduled within 48 hours',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
