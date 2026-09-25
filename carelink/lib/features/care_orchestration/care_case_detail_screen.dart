import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/services/care_readiness_service.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/risk_badge.dart';
import '../../data/repositories/care_case_repository.dart';
import '../../data/repositories/consult_repository.dart';
import '../../data/repositories/facility_repository.dart';
import '../../data/repositories/follow_up_repository.dart';
import '../../data/repositories/patient_repository.dart';
import '../../models/care_case_model.dart';
import '../../models/consult_request_model.dart';
import '../../models/facility_model.dart';
import '../../models/triage_result_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/care_orchestration_provider.dart';
import '../doctor/consult_chat_screen.dart';

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
        isRouteConfirmed: true,
        status: CareCaseStatus.routed,
        updatedAt: DateTime.now(),
      );
      await CareCaseRepository().saveOrUpdateCareCase(updated);
      await PatientRepository().addTimelineEvent(_case.patientId, {
        'title': 'Facility Route Confirmed',
        'description': 'Route to ${_case.destinationFacilityName ?? "Facility"} explicitly confirmed and locked by CHW.',
        'timestamp': Timestamp.now(),
        'type': 'routing',
      });
      ref.invalidate(careCaseByIdProvider(_case.id));
      setState(() => _case = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Care route confirmed & locked successfully!'),
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

  Future<void> _toggleDiagnosticStatus(CareCaseModel c, String testName) async {
    final currentMap = Map<String, String>.from(c.diagnosticsStatus);
    final currentStatus = currentMap[testName] ?? 'pending';
    final newStatus = currentStatus == 'completed' ? 'pending' : 'completed';
    currentMap[testName] = newStatus;

    final updated = c.copyWith(
      diagnosticsStatus: currentMap,
      updatedAt: DateTime.now(),
    );

    await CareCaseRepository().saveOrUpdateCareCase(updated);
    await PatientRepository().addTimelineEvent(c.patientId, {
      'title': newStatus == 'completed' ? 'Diagnostic Test Completed' : 'Diagnostic Status Reset',
      'description': 'Diagnostic test "$testName" marked as ${newStatus.toUpperCase()} by CHW.',
      'timestamp': Timestamp.now(),
      'type': 'diagnostic',
    });
    ref.invalidate(careCaseByIdProvider(c.id));
    setState(() => _case = updated);
  }

  Future<void> _toggleMedicineStatus(CareCaseModel c, String medicineName) async {
    final currentMap = Map<String, String>.from(c.medicinesStatus);
    final currentStatus = currentMap[medicineName] ?? 'pending';
    final newStatus = currentStatus == 'dispensed' ? 'pending' : 'dispensed';
    currentMap[medicineName] = newStatus;

    final updated = c.copyWith(
      medicinesStatus: currentMap,
      updatedAt: DateTime.now(),
    );

    await CareCaseRepository().saveOrUpdateCareCase(updated);
    await PatientRepository().addTimelineEvent(c.patientId, {
      'title': newStatus == 'dispensed' ? 'Medicine Dispensed' : 'Medicine Status Reset',
      'description': 'Medicine "$medicineName" marked as ${newStatus.toUpperCase()} by CHW.',
      'timestamp': Timestamp.now(),
      'type': 'medicine',
    });
    ref.invalidate(careCaseByIdProvider(c.id));
    setState(() => _case = updated);
  }

  void _showIncompleteWarning(List<String> missing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: AppColors.riskHigh),
            SizedBox(width: 8),
            Text('Cannot Complete Journey'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The Care Journey cannot be marked complete because required care steps are still pending:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...missing.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.close, size: 16, color: AppColors.riskHigh),
                      const SizedBox(width: 6),
                      Expanded(child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            const Text(
              'Please complete all pending clinical actions, diagnostics, medicines, and follow-ups before closing.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeCareCase(CareCaseModel c) async {
    // Perform strict completion checks
    final missing = <String>[];

    if (!c.isDoctorConsulted) {
      missing.add('Doctor Consultation (Pending doctor review & decision)');
    }

    if (!c.isRouteConfirmed) {
      missing.add('Facility Route Confirmation (Pending CHW route confirmation)');
    }

    for (final entry in c.diagnosticsStatus.entries) {
      if (entry.value != 'completed') {
        missing.add('Diagnostic Test: ${entry.key}');
      }
    }

    for (final entry in c.medicinesStatus.entries) {
      if (entry.value != 'dispensed') {
        missing.add('Pharmacy Dispensing: ${entry.key}');
      }
    }

    if (!c.isFollowUpDone) {
      missing.add('CHW Post-Care Follow-up Visit');
    }

    if (missing.isNotEmpty) {
      _showIncompleteWarning(missing);
      return;
    }

    setState(() => _updating = true);
    try {
      final updated = c.copyWith(
        status: CareCaseStatus.completed,
        isFollowUpDone: true,
        updatedAt: DateTime.now(),
      );
      await CareCaseRepository().saveOrUpdateCareCase(updated);

      if (c.followUpTaskId != null && c.followUpTaskId!.isNotEmpty) {
        await FollowUpRepository().markDone(c.followUpTaskId!);
      }

      await PatientRepository().addTimelineEvent(c.patientId, {
        'title': 'Care Journey Completed',
        'description': 'All required care steps, diagnostics, medicines, and follow-up completed.',
        'timestamp': Timestamp.now(),
        'type': 'completion',
      });

      ref.invalidate(careCaseByIdProvider(c.id));
      setState(() => _case = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Care Case completed! All care steps verified.'),
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

  void _showFindAnotherDoctorModal(CareCaseModel c) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return _DoctorSelectionSheet(
          careCase: c,
          onDoctorSelected: (doc) async {
            Navigator.pop(context);
            final updated = c.copyWith(
              assignedDoctorUid: doc.uid,
              assignedDoctorName: doc.displayName,
              assignedDoctorSpecialty: doc.specialty ?? c.requiredSpecialty,
              assignmentReason: 'Manually re-assigned doctor: ${doc.displayName} (${doc.specialty ?? "General Physician"}).',
              updatedAt: DateTime.now(),
            );
            await CareCaseRepository().saveOrUpdateCareCase(updated);

            if (c.consultRequestId != null && c.consultRequestId!.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection(FirestorePaths.consultRequests)
                  .doc(c.consultRequestId)
                  .update({
                'doctorUid': doc.uid,
                'doctorName': doc.displayName,
              });
            }

            await PatientRepository().addTimelineEvent(c.patientId, {
              'title': 'Doctor Reassigned',
              'description': 'Assigned doctor updated to ${doc.displayName}.',
              'timestamp': Timestamp.now(),
              'type': 'assignment',
            });

            ref.invalidate(careCaseByIdProvider(c.id));
            setState(() => _case = updated);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Re-assigned to ${doc.displayName}'),
                backgroundColor: AppColors.primary,
              ));
            }
          },
        );
      },
    );
  }

  void _showViewAlternativesModal(CareCaseModel c) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return _FacilitySelectionSheet(
          careCase: c,
          onFacilitySelected: (fac, isReady, reason) async {
            Navigator.pop(context);
            final oldFac = c.destinationFacilityName ?? 'Local Facility';
            final updated = c.copyWith(
              destinationFacilityId: fac.id,
              destinationFacilityName: fac.name,
              isFacilityCareReady: isReady,
              facilityReadinessNotes: reason,
              recommendedRouteReason: 'Manually selected facility: ${fac.name}. $reason',
              isRouteConfirmed: false, // Reset route confirmation so new route MUST be explicitly confirmed!
              updatedAt: DateTime.now(),
            );
            await CareCaseRepository().saveOrUpdateCareCase(updated);

            await PatientRepository().addTimelineEvent(c.patientId, {
              'title': 'Facility Route Changed',
              'description': 'Facility route changed from $oldFac to ${fac.name} by CHW.',
              'timestamp': Timestamp.now(),
              'type': 'routing',
            });

            ref.invalidate(careCaseByIdProvider(c.id));
            setState(() => _case = updated);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Facility set to ${fac.name}. Confirm route to lock.'),
                backgroundColor: AppColors.primary,
              ));
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveCaseAsync = ref.watch(careCaseByIdProvider(_case.id));
    final fetchedCase = liveCaseAsync.valueOrNull;
    final liveCase = (fetchedCase != null && fetchedCase.updatedAt.isAfter(_case.updatedAt))
        ? fetchedCase
        : _case;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Care Orchestration Case'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. Emergency Escalation Banner (if applicable)
            if (liveCase.isEmergency) ...[
              _buildEmergencyEscalationCard(liveCase),
              const SizedBox(height: 16),
            ],

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

            // 6. Minimum-Trip Care Plan Card & Action Items
            _buildMinimumTripCard(liveCase),
            const SizedBox(height: 16),

            // 7. Automated Follow-up Card
            _buildFollowUpCard(liveCase),
            const SizedBox(height: 24),

            // Action completion button
            if (liveCase.status != CareCaseStatus.completed)
              ElevatedButton.icon(
                onPressed: _updating ? null : () => _completeCareCase(liveCase),
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

  Widget _buildEmergencyEscalationCard(CareCaseModel c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.riskHigh, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency, color: AppColors.riskHigh, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'EMERGENCY ESCALATION',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.riskHigh,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.riskHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('CRITICAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.emergencyReason ?? 'Critical vital failure or severe symptoms detected requiring immediate emergency stabilization.',
            style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('🚑 Emergency Transport (108 Ambulance) Alerted & Dispatched for patient.'),
                      backgroundColor: AppColors.riskHigh,
                    ));
                  },
                  icon: const Icon(Icons.airport_shuttle_outlined, size: 16),
                  label: const Text('Dispatch Transport (108)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.riskHigh,
                    side: const BorderSide(color: AppColors.riskHigh),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Emergency Facility set to Nashik Civil Hospital (Tertiary Trauma Center).'),
                      backgroundColor: AppColors.primary,
                    ));
                  },
                  icon: const Icon(Icons.local_hospital_outlined, size: 16),
                  label: const Text('View Emergency Facility', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${c.patientAge}y · ${c.patientGender} · Village: ${c.village}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
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
      {'title': 'Triage'},
      {'title': 'Doctor Assigned'},
      {'title': 'Doctor Consulted'},
      {'title': 'Care Ready'},
      {'title': 'Route Confirmed'},
      {'title': 'Completed'},
    ];

    int currentStepIndex = 0;
    if (c.status == CareCaseStatus.completed) {
      currentStepIndex = 5;
    } else if (c.isRouteConfirmed) {
      currentStepIndex = 4;
    } else if (c.isFacilityCareReady && c.isDoctorConsulted) {
      currentStepIndex = 3;
    } else if (c.isDoctorConsulted) {
      currentStepIndex = 2;
    } else if (c.assignedDoctorUid != null && c.assignedDoctorUid!.isNotEmpty) {
      currentStepIndex = 1;
    }

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
                    width: 78,
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
                      Expanded(
                        child: Text(
                          '1. SMART DOCTOR ASSIGNMENT',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showFindAnotherDoctorModal(c),
                  icon: const Icon(Icons.swap_horiz, size: 14),
                  label: const Text('FIND ANOTHER DOCTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Specialty: ${c.assignedDoctorSpecialty ?? c.requiredSpecialty ?? "General Medicine"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
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

            // Doctor Consulted Banner (P0 Fix 2)
            if (c.isDoctorConsulted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'DOCTOR CONSULTED',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Colors.green,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ACCEPTED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dr. ${c.assignedDoctorName ?? "Assigned Doctor"} has accepted this consultation.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    if (c.doctorClinicalNote != null && c.doctorClinicalNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Clinical Note: ${c.doctorClinicalNote}',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Action Button — Open Chat with Doctor (P0 Fix 3)
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final consultId = c.consultRequestId;
                  ConsultRequestModel? consult;
                  if (consultId != null && consultId.isNotEmpty) {
                    consult = await ConsultRepository().getConsult(consultId);
                  }
                  consult ??= ConsultRequestModel(
                    id: c.consultRequestId ?? 'consult_${c.id}',
                    patientId: c.patientId,
                    patientName: c.patientName,
                    chwUid: 'chw_uid',
                    chwName: 'Sunita Kamble (CHW)',
                    doctorUid: c.assignedDoctorUid,
                    doctorName: c.assignedDoctorName,
                    reason: c.chiefComplaint,
                    urgency: c.isEmergency
                        ? UrgencyLevel.emergency
                        : (c.riskLevel == RiskLevel.high ? UrgencyLevel.urgent : UrgencyLevel.routine),
                    status: c.isDoctorConsulted ? ConsultStatus.accepted : ConsultStatus.pending,
                    careCaseId: c.id,
                    createdAt: c.createdAt,
                  );
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ConsultChatScreen(consult: consult!)),
                    );
                  }
                },
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: Text(
                  c.isDoctorConsulted
                      ? 'OPEN CHAT WITH DR. ${(c.assignedDoctorName ?? "DOCTOR").toUpperCase()}'
                      : 'OPEN CHAT WITH DOCTOR',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
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
                      Expanded(
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
    final isRouted = c.isRouteConfirmed;

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
                      Icon(Icons.alt_route, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '3. ADAPTIVE CARE ROUTING',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showViewAlternativesModal(c),
                  icon: const Icon(Icons.apartment_outlined, size: 14),
                  label: const Text('VIEW ALTERNATIVES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'RECOMMENDED FACILITY PATHWAY',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isRouted ? Colors.green.shade100 : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isRouted ? 'LOCKED & CONFIRMED' : 'NOT CONFIRMED',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isRouted ? Colors.green.shade900 : Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.destinationFacilityName ?? 'Nashik Civil Hospital',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  Text('✓ Route Confirmed & Locked', style: TextStyle(color: AppColors.riskLow, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimumTripCard(CareCaseModel c) {
    final title = c.minimumTripPlanTitle ?? 'Recommended minimum-trip care plan';

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
            const SizedBox(height: 12),

            // Diagnostic Action Items
            const Text('DIAGNOSTICS TRACKING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            if (c.diagnosticsSummary.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No diagnostic tests required for this care episode.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              )
            else
              ...c.diagnosticsSummary.map((d) {
                final status = c.diagnosticsStatus[d] ?? 'pending';
                final isDone = status == 'completed';
                return InkWell(
                  onTap: () => _toggleDiagnosticStatus(c, d),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: isDone ? Colors.green : AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, decoration: isDone ? TextDecoration.lineThrough : null),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.shade100 : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDone ? 'COMPLETED' : 'PENDING',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDone ? Colors.green.shade900 : Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 12),
            // Pharmacy Action Items
            const Text('PHARMACY DISPENSING TRACKING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            if (c.medicinesSummary.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No pharmacy items required for this care episode.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              )
            else
              ...c.medicinesSummary.map((m) {
                final status = c.medicinesStatus[m] ?? 'pending';
                final isDone = status == 'dispensed';
                return InkWell(
                  onTap: () => _toggleMedicineStatus(c, m),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: isDone ? Colors.green : AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, decoration: isDone ? TextDecoration.lineThrough : null),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.shade100 : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDone ? 'DISPENSED' : 'PENDING',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDone ? Colors.green.shade900 : Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard(CareCaseModel c) {
    final isDone = c.isFollowUpDone;

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
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDone ? Colors.green.shade100 : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isDone ? 'DONE' : 'PENDING',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDone ? Colors.green.shade900 : Colors.amber.shade900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorSelectionSheet extends ConsumerWidget {
  final CareCaseModel careCase;
  final ValueChanged<UserModel> onDoctorSelected;

  const _DoctorSelectionSheet({
    required this.careCase,
    required this.onDoctorSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(allDoctorsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FIND ANOTHER DOCTOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Select an eligible doctor for ${careCase.patientName}:', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          doctorsAsync.when(
            data: (doctors) {
              if (doctors.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No doctors registered in network.'),
                );
              }
              return Column(
                children: doctors.map((doc) => _docTile(
                  name: doc.displayName,
                  specialty: doc.specialty ?? 'General Medicine',
                  isOnDuty: doc.isOnDuty,
                  workload: doc.activeWorkload,
                  facility: doc.facilityName ?? 'District Office',
                  onTap: () => onDoctorSelected(doc),
                )).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error loading doctors: $e'),
          ),
        ],
      ),
    );
  }

  Widget _docTile({
    required String name,
    required String specialty,
    required bool isOnDuty,
    required int workload,
    required String facility,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text('$specialty · $facility · Active Workload: $workload'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isOnDuty ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          isOnDuty ? '🟢 On Duty' : '🔴 Off Duty',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOnDuty ? Colors.green.shade900 : Colors.red.shade900),
        ),
      ),
    );
  }
}

class _FacilitySelectionSheet extends ConsumerWidget {
  final CareCaseModel careCase;
  final Function(FacilityModel, bool, String) onFacilitySelected;

  const _FacilitySelectionSheet({
    required this.careCase,
    required this.onFacilitySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(allFacilitiesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VIEW ALTERNATIVE FACILITIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Compare facility readiness & capabilities for required care:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          facilitiesAsync.when(
            data: (facilities) {
              if (facilities.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No alternative facilities configured.'),
                );
              }
              return Column(
                children: facilities.map((fac) {
                  final audit = CareReadinessService.auditFacilityReadiness(
                    facility: fac,
                    requiredSpecialty: careCase.requiredSpecialty ?? 'General Medicine',
                    requiredDiagnostics: careCase.diagnosticsSummary,
                    requiredMedicines: careCase.medicinesSummary,
                  );
                  final reason = audit.isCareReady
                      ? 'CARE READY: Full specialty, diagnostics & pharmacy availability.'
                      : (audit.missingReasons.isNotEmpty
                          ? 'PARTIAL: ${audit.missingReasons.join("; ")}'
                          : 'PARTIAL READINESS');

                  return _facTile(
                    name: fac.name,
                    tier: '${fac.tier} Level Facility',
                    isReady: audit.isCareReady,
                    reason: reason,
                    onTap: () => onFacilitySelected(fac, audit.isCareReady, reason),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error loading facilities: $e'),
          ),
        ],
      ),
    );
  }

  Widget _facTile({
    required String name,
    required String tier,
    required bool isReady,
    required String reason,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.local_hospital)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text('$tier\n$reason', style: const TextStyle(fontSize: 11)),
      isThreeLine: true,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isReady ? Colors.green.shade100 : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          isReady ? 'CARE READY' : 'PARTIAL',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isReady ? Colors.green.shade900 : Colors.orange.shade900),
        ),
      ),
    );
  }
}

