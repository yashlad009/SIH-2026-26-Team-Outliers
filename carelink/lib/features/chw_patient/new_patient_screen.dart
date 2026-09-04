import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/repositories/patient_repository.dart';
import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';

class NewPatientScreen extends ConsumerStatefulWidget {
  const NewPatientScreen({super.key});

  @override
  ConsumerState<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends ConsumerState<NewPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _abhaCtrl = TextEditingController();
  Gender _gender = Gender.female;
  String _district = 'Nashik';
  bool _loading = false;

  static const _districts = [
    'Nashik',
    'Pune',
    'Aurangabad',
    'Nagpur',
    'Amravati',
    'Kolhapur',
    'Solapur',
    'Nanded',
    'Other'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _villageCtrl.dispose();
    _contactCtrl.dispose();
    _abhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(userProfileProvider);
      final patient = PatientModel(
        id: '', // will be set by Firestore
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        gender: _gender,
        village: _villageCtrl.text.trim(),
        district: _district,
        contactNumber: _contactCtrl.text.trim().isEmpty
            ? null
            : _contactCtrl.text.trim(),
        abhaId: _abhaCtrl.text.trim().isEmpty ? null : _abhaCtrl.text.trim(),
        registeredByUid: user?.uid ?? 'unknown',
        registeredAt: DateTime.now(),
      );
      await PatientRepository().createPatient(patient);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient registered successfully'),
            backgroundColor: AppColors.riskLow,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.riskHigh),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('New Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section('Personal Details'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Patient Name *',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => Validators.required(v, 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      decoration: const InputDecoration(labelText: 'Age *'),
                      keyboardType: TextInputType.number,
                      validator: Validators.age,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Gender>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: Gender.values
                          .map((g) => DropdownMenuItem(
                              value: g, child: Text(g.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _villageCtrl,
                decoration: const InputDecoration(
                    labelText: 'Village *',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => Validators.required(v, 'Village'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _district,
                decoration: const InputDecoration(labelText: 'District'),
                items: _districts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _district = v!),
              ),
              const SizedBox(height: 24),
              _section('Contact & ID'),
              TextFormField(
                controller: _contactCtrl,
                decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _abhaCtrl,
                decoration: const InputDecoration(
                    labelText: 'ABHA ID (optional)',
                    prefixIcon: Icon(Icons.credit_card_outlined)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Patient'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5)),
    );
  }
}
