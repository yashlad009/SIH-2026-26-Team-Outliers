import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/utils/date_formatters.dart';
import '../../providers/patient_provider.dart';
import '../../models/patient_model.dart';
import '../patient_record/patient_record_screen.dart';
import 'new_patient_screen.dart';

class PatientListScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const PatientListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(filteredPatientListProvider);

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, village…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref
                            .read(patientSearchQueryProvider.notifier)
                            .state = '';
                      },
                    )
                  : null,
            ),
            onChanged: (v) =>
                ref.read(patientSearchQueryProvider.notifier).state = v,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: patientsAsync.when(
            data: (patients) {
              if (patients.isEmpty) {
                return EmptyState(
                  message: _searchCtrl.text.isEmpty
                      ? 'No patients registered'
                      : 'No results for "${_searchCtrl.text}"',
                  subtitle: _searchCtrl.text.isEmpty
                      ? 'Tap + to register a new patient'
                      : 'Try a different search',
                  icon: Icons.people_outline,
                  onAction: _searchCtrl.text.isEmpty
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NewPatientScreen()))
                      : null,
                  actionLabel:
                      _searchCtrl.text.isEmpty ? 'New Patient' : null,
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(patientListProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: patients.length,
                  itemBuilder: (_, i) => _PatientCard(patient: patients[i]),
                ),
              );
            },
            loading: () => ListView(
              children: List.generate(
                  5, (_) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: LoadingListItem())),
            ),
            error: (e, _) => EmptyState(
              message: 'Failed to load patients',
              subtitle: e.toString(),
              icon: Icons.error_outline,
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Patients')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NewPatientScreen())),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PatientRecordScreen(patient: patient)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.age}y · ${patient.gender.label} · ${patient.village}, ${patient.district}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (patient.chronicConditions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: patient.chronicConditions.take(2).map((c) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(c,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primaryDark)),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.chevron_right, color: AppColors.textHint),
                  const SizedBox(height: 4),
                  if (patient.lastVisitAt != null)
                    Text(
                      DateFormatters.timeAgo(patient.lastVisitAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
