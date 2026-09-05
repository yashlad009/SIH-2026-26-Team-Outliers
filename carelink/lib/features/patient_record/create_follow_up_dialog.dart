import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/follow_up_repository.dart';
import '../../models/follow_up_task_model.dart';
import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';

class CreateFollowUpDialog extends ConsumerStatefulWidget {
  final PatientModel patient;
  const CreateFollowUpDialog({super.key, required this.patient});

  static Future<bool?> show(BuildContext context, PatientModel patient) {
    return showDialog<bool>(
      context: context,
      builder: (_) => CreateFollowUpDialog(patient: patient),
    );
  }

  @override
  ConsumerState<CreateFollowUpDialog> createState() => _CreateFollowUpDialogState();
}

class _CreateFollowUpDialogState extends ConsumerState<CreateFollowUpDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  FollowUpCategory _category = FollowUpCategory.general;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 2));
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dueDate.hour,
          _dueDate.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(activeUserProfileProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not available')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final task = FollowUpTaskModel(
        id: '',
        patientId: widget.patient.id,
        patientName: widget.patient.name,
        assignedToUid: user.role.name == 'chw' ? user.uid : 'assigned-chw-uid',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _category,
        dueDate: _dueDate,
        isDone: false,
        createdByUid: user.uid,
        createdAt: DateTime.now(),
      );

      await FollowUpRepository().createTask(task);
      ref.invalidate(allFollowUpTasksProvider);
      ref.invalidate(followUpTasksByPatientProvider(widget.patient.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-up task created successfully'),
            backgroundColor: AppColors.riskLow,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating follow-up task: $e'),
            backgroundColor: AppColors.riskHigh,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.event_note, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Schedule Follow-up Task',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Summary Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.patient.name} (${widget.patient.age}y · ${widget.patient.village})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Check blood pressure, Check vitals',
                  isDense: true,
                ),
                validator: (v) => Validators.required(v, 'Task title'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<FollowUpCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  isDense: true,
                ),
                items: FollowUpCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.label),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              // Due Date Picker Button
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textSecondary)),
                          Text(DateFormatters.formatDate(_dueDate),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Instructions / Notes',
                  hintText: 'Add clinical notes or guidance for CHW',
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(_submitting ? 'Saving…' : 'Save Task'),
        ),
      ],
    );
  }
}
