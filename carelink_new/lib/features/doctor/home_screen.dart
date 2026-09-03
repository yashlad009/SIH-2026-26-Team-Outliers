import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../providers/auth_provider.dart';
import '../referral/referral_list_screen.dart';
import '../settings/settings_screen.dart';
import 'consult_queue_screen.dart';
import '../patient_record/patient_record_screen.dart';
import '../../providers/patient_provider.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/patient_model.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DoctorOverviewTab(),
      const ConsultQueueScreen(embedded: true),
      const ReferralListScreen(embedded: true),
    ];

    return AppScaffold(
      appBar: AppBar(
        title: const Text('CareLink — Doctor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.queue_outlined), label: 'Consults'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined), label: 'Referrals'),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    ref.read(authServiceProvider).signOut();
    ref.read(userProfileProvider.notifier).clear();
  }
}

class _DoctorOverviewTab extends ConsumerWidget {
  const _DoctorOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final patientsAsync = ref.watch(patientListProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(patientListProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.displayName ?? 'Doctor'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(DateFormatters.formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),

            // Quick action — go to consult queue
            Card(
              color: AppColors.primary,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.queue_outlined,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Consultation Queue',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            Text('Tap "Consults" tab to view pending requests',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Patient List',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            patientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const EmptyState(
                    message: 'No patients yet',
                    icon: Icons.people_outline,
                  );
                }
                return Column(
                  children: patients
                      .take(10)
                      .map((p) => _DoctorPatientTile(patient: p))
                      .toList(),
                );
              },
              loading: () => const LoadingListItem(),
              error: (e, _) => EmptyState(
                  message: 'Failed to load patients',
                  subtitle: e.toString(),
                  icon: Icons.error_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorPatientTile extends StatelessWidget {
  final PatientModel patient;
  const _DoctorPatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(patient.initials,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        title: Text(patient.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${patient.age}y · ${patient.gender.label} · ${patient.village}'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PatientRecordScreen(patient: patient)),
        ),
      ),
    );
  }
}
