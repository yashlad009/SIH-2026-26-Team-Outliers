import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/risk_scoring.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/risk_badge.dart';
import '../../data/repositories/patient_repository.dart';
import '../../models/patient_model.dart';
import '../../models/triage_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/triage_provider.dart';
import '../../providers/care_orchestration_provider.dart';
import '../care_orchestration/care_case_detail_screen.dart';

class TriageFormScreen extends ConsumerStatefulWidget {
  final PatientModel patient;
  const TriageFormScreen({super.key, required this.patient});

  @override
  ConsumerState<TriageFormScreen> createState() => _TriageFormScreenState();
}

class _TriageFormScreenState extends ConsumerState<TriageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _bpSysCtrl = TextEditingController();
  final _bpDiaCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();
  final _spO2Ctrl = TextEditingController();
  final _rrCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<String> _selectedSymptoms = [];
  bool _saving = false;
  bool _aiLoading = false;
  TriageScore? _score;
  String? _savedTriageId;
  String? _aiNote;

  static const _commonSymptoms = [
    'Fever', 'Headache', 'Cough', 'Chest pain', 'Difficulty breathing',
    'Abdominal pain', 'Vomiting', 'Diarrhea', 'Dizziness', 'Weakness',
    'Swelling', 'Blurred vision', 'Seizure', 'Unconscious', 'Rash',
    'Bleeding', 'Pregnancy complication', 'Wheezing',
  ];

  @override
  void dispose() {
    for (final c in [_complaintCtrl, _tempCtrl, _bpSysCtrl, _bpDiaCtrl,
        _hrCtrl, _spO2Ctrl, _rrCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _runTriage() {
    if (!_formKey.currentState!.validate()) return;
    final score = RiskScoring.compute(
      age: widget.patient.age,
      temperature: double.tryParse(_tempCtrl.text),
      bpSystolic: int.tryParse(_bpSysCtrl.text),
      bpDiastolic: int.tryParse(_bpDiaCtrl.text),
      heartRate: int.tryParse(_hrCtrl.text),
      spO2: int.tryParse(_spO2Ctrl.text),
      respiratoryRate: int.tryParse(_rrCtrl.text),
      symptoms: _selectedSymptoms,
      chronicConditions: widget.patient.chronicConditions,
    );
    setState(() { _score = score; _aiNote = null; });
  }

  Future<void> _saveTriage() async {
    if (_score == null) return;
    setState(() => _saving = true);
    try {
      final user = ref.read(userProfileProvider);
      final triage = TriageResultModel(
        id: '',
        patientId: widget.patient.id,
        assessedByUid: user?.uid ?? '',
        chiefComplaint: _complaintCtrl.text.trim(),
        symptoms: List.from(_selectedSymptoms),
        temperature: double.tryParse(_tempCtrl.text),
        bpSystolic: int.tryParse(_bpSysCtrl.text),
        bpDiastolic: int.tryParse(_bpDiaCtrl.text),
        heartRate: int.tryParse(_hrCtrl.text),
        spO2: int.tryParse(_spO2Ctrl.text),
        respiratoryRate: int.tryParse(_rrCtrl.text),
        riskLevel: _score!.level,
        riskScore: _score!.score,
        riskFlags: _score!.flags,
        additionalNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        assessedAt: DateTime.now(),
      );
      final id = await PatientRepository().saveTriage(triage);
      setState(() => _savedTriageId = id);

      // Trigger Care Orchestration Engine (Smart Assignment, Readiness, Adaptive Route, Min-Trip, Auto Follow-up)
      final careCase = await ref.read(careOrchestrationEngineProvider).orchestrateCareCase(
            patient: widget.patient,
            triage: triage.copyWith(id: id),
            chwUid: user?.uid ?? 'chw_uid',
            chwName: user?.displayName ?? 'CHW',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Triage saved & Smart Doctor Assigned: ${careCase.assignedDoctorName ?? "Assigned"}'),
          backgroundColor: AppColors.riskLow,
          action: SnackBarAction(
            label: 'VIEW CASE',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CareCaseDetailScreen(careCase: careCase)),
              );
            },
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.riskHigh));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generateAiNote() async {
    if (_score == null) return;
    setState(() => _aiLoading = true);
    try {
      final note = await ref.read(geminiServiceProvider).generateTriageNote(
        age: widget.patient.age,
        riskLevel: _score!.level,
        riskScore: _score!.score,
        riskFlags: _score!.flags,
        chiefComplaint: _complaintCtrl.text,
        temperature: double.tryParse(_tempCtrl.text),
        bpSystolic: int.tryParse(_bpSysCtrl.text),
        bpDiastolic: int.tryParse(_bpDiaCtrl.text),
        spO2: int.tryParse(_spO2Ctrl.text),
        heartRate: int.tryParse(_hrCtrl.text),
      );
      setState(() => _aiNote = note ?? 'AI unavailable. Pass --dart-define=GEMINI_API_KEY=...');
      if (_savedTriageId != null && note != null) {
        await PatientRepository().updateTriageAiNote(_savedTriageId!, note);
      }
    } catch (e) {
      setState(() => _aiNote = 'Error: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Triage Form'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.patient.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient banner
              _buildPatientBanner(),
              const SizedBox(height: 20),

              _sectionLabel('CHIEF COMPLAINT & SYMPTOMS'),
              TextFormField(
                controller: _complaintCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chief Complaint *',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (v) => Validators.required(v, 'Chief complaint'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              const Text('Select Symptoms',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _commonSymptoms.map((s) {
                  final sel = _selectedSymptoms.contains(s);
                  return FilterChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    onSelected: (v) => setState(() {
                      v ? _selectedSymptoms.add(s) : _selectedSymptoms.remove(s);
                    }),
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              _sectionLabel('VITALS'),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _tempCtrl,
                    decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.temperature,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _spO2Ctrl,
                    decoration: const InputDecoration(labelText: 'SpO₂ (%)'),
                    keyboardType: TextInputType.number,
                    validator: Validators.spO2,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _bpSysCtrl,
                    decoration: const InputDecoration(labelText: 'BP Systolic'),
                    keyboardType: TextInputType.number,
                    validator: Validators.bpSystolic,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bpDiaCtrl,
                    decoration: const InputDecoration(labelText: 'BP Diastolic'),
                    keyboardType: TextInputType.number,
                    validator: Validators.bpDiastolic,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _hrCtrl,
                    decoration: const InputDecoration(labelText: 'Heart Rate (bpm)'),
                    keyboardType: TextInputType.number,
                    validator: Validators.heartRate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _rrCtrl,
                    decoration: const InputDecoration(labelText: 'Resp. Rate (/min)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _runTriage,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Run Triage'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),

              if (_score != null) ...[
                const SizedBox(height: 24),
                _buildResultCard(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(widget.patient.initials,
                style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.patient.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              Text(
                  '${widget.patient.age}y · ${widget.patient.gender.label} · ${widget.patient.village}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1)),
    );
  }

  Widget _buildResultCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Triage Result',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 6),
                      RiskBadge(
                          riskLevel: _score!.level,
                          showScore: true,
                          score: _score!.score,
                          large: true),
                    ],
                  ),
                ),
                if (_savedTriageId != null)
                  const Icon(Icons.cloud_done, color: AppColors.riskLow, size: 28),
              ],
            ),
          ),
          // Risk flags
          if (_score!.flags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Risk Factors',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  ..._score!.flags.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.warning_amber_outlined,
                              size: 14, color: AppColors.riskMedium),
                          const SizedBox(width: 6),
                          Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                        ]),
                      )),
                ],
              ),
            ),
          // AI note
          if (_aiNote != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('AI Clinical Note',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_aiNote!, style: const TextStyle(fontSize: 13, height: 1.5)),
                  const SizedBox(height: 6),
                  const Text('⚠️  AI-assisted — not a clinical diagnosis',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_savedTriageId == null)
                ElevatedButton.icon(
                  onPressed: _saving ? null : _saveTriage,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save Triage'),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _aiLoading ? null : _generateAiNote,
                icon: _aiLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(_aiLoading ? 'Generating…' : 'Generate AI Note (Demo)'),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
