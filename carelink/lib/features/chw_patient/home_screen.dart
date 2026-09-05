import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/utils/date_formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/consult_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/patient_model.dart';
import '../../models/consult_request_model.dart';
import '../../models/follow_up_task_model.dart';
import '../patient_record/patient_record_screen.dart';
import 'patient_list_screen.dart';
import 'new_patient_screen.dart';
import 'triage_form_screen.dart';
import 'consult_request_screen.dart';
import 'chw_consult_list_screen.dart';
import 'follow_up_task_screen.dart';
import '../referral/referral_list_screen.dart';
import '../inventory/medicine_stock_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/widgets/risk_badge.dart';

class ChwHomeScreen extends ConsumerStatefulWidget {
  const ChwHomeScreen({super.key});

  @override
  ConsumerState<ChwHomeScreen> createState() => _ChwHomeScreenState();
}

class _ChwHomeScreenState extends ConsumerState<ChwHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(activeUserProfileProvider);
    final pages = [
      _OverviewTab(user: user),
      const PatientListScreen(embedded: true),
      FollowUpTaskScreen(embedded: true, chwUid: user?.uid),
      const ReferralListScreen(embedded: true),
    ];

    return AppScaffold(
      appBar: AppBar(
        title: const Text('CareLink'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: _tab == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewPatientScreen())),
              child: const Icon(Icons.person_add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Patients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.task_outlined), label: 'Follow-ups'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined), label: 'Referrals'),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authServiceProvider).signOut();
              ref.read(userProfileProvider.notifier).clear();
            },
            child: const Text('Logout',
                style: TextStyle(color: AppColors.riskHigh)),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final dynamic user;
  const _OverviewTab({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientListProvider);
    final consultsAsync = user != null
        ? ref.watch(chwConsultsProvider(user!.uid))
        : const AsyncData<List<ConsultRequestModel>>([]);
    final tasksAsync = user != null
        ? ref.watch(followUpTasksByChwProvider(user!.uid))
        : const AsyncData<List<FollowUpTaskModel>>([]);

    final activeConsults = consultsAsync.valueOrNull
            ?.where((c) =>
                c.status.name == 'pending' || c.status.name == 'accepted')
            .length ??
        0;
    final pendingTasks =
        tasksAsync.valueOrNull?.where((t) => !t.isDone).length ?? 0;
    final totalPatients = patientsAsync.valueOrNull?.length ?? 0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(patientListProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Good ${_greeting()}, ${user?.displayName?.split(' ').first ?? 'CHW'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(DateFormatters.formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            // Stats
            Row(children: [
              Expanded(
                  child: _StatCard(
                      label: 'Patients',
                      value: '$totalPatients',
                      icon: Icons.people_alt_outlined,
                      color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'Consults',
                      value: '$activeConsults',
                      icon: Icons.chat_outlined,
                      color: AppColors.secondary,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChwConsultListScreen())))),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'Tasks Due',
                      value: '$pendingTasks',
                      icon: Icons.task_alt_outlined,
                      color: AppColors.statusScheduled,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => FollowUpTaskScreen(chwUid: user?.uid))))),
            ]),
            const SizedBox(height: 24),
            Text('Quick Actions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _QuickAction(
                  icon: Icons.person_add_outlined,
                  label: 'New Patient',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NewPatientScreen())),
                ),
                _QuickAction(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Run Triage',
                  color: AppColors.riskMedium,
                  onTap: () => _pickPatientFor(context, ref, 'triage'),
                ),
                _QuickAction(
                  icon: Icons.video_call_outlined,
                  label: 'Request Consult',
                  color: AppColors.secondary,
                  onTap: () => _pickPatientFor(context, ref, 'consult'),
                ),
                _QuickAction(
                  icon: Icons.inventory_2_outlined,
                  label: 'Medicine Stock',
                  color: AppColors.statusCreated,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MedicineStockScreen())),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _PendingSyncSection(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Patients',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            patientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const EmptyState(
                    message: 'No patients yet',
                    subtitle: 'Tap + to register a patient',
                    icon: Icons.people_outline,
                  );
                }
                return Column(
                  children: patients
                      .take(5)
                      .map((p) => _PatientTile(patient: p))
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  Future<void> _pickPatientFor(
      BuildContext context, WidgetRef ref, String action) async {
    final patients = ref.read(patientListProvider).valueOrNull ?? [];
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a patient first.')));
      return;
    }
    final selected = await showDialog<PatientModel>(
      context: context,
      builder: (_) => _PatientPickerDialog(patients: patients),
    );
    if (selected == null || !context.mounted) return;
    if (action == 'triage') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TriageFormScreen(patient: selected)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ConsultRequestScreen(patient: selected)));
    }
  }
}

class _PatientPickerDialog extends StatelessWidget {
  final List<PatientModel> patients;
  const _PatientPickerDialog({required this.patients});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Patient'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: patients.length,
          itemBuilder: (_, i) {
            final p = patients[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryContainer,
                child: Text(p.initials,
                    style: const TextStyle(color: AppColors.primary)),
              ),
              title: Text(p.name),
              subtitle: Text('${p.age}y · ${p.village}'),
              onTap: () => Navigator.pop(context, p),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final PatientModel patient;
  const _PatientTile({required this.patient});

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
        trailing: Text(
          DateFormatters.timeAgo(patient.lastVisitAt),
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PatientRecordScreen(patient: patient)),
        ),
      ),
    );
  }
}

class _PendingSyncSection extends ConsumerWidget {
  const _PendingSyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSyncPatientsProvider);

    return pendingAsync.when(
      data: (pendingPatients) {
        final count = pendingPatients.length;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: count > 0 ? AppColors.offlineBanner : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      count > 0 ? Icons.cloud_off : Icons.cloud_done_outlined,
                      size: 18,
                      color: count > 0 ? AppColors.offlineBanner : AppColors.riskLow,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Sync — $count Record${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (count == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'All records are synced.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Column(
                    children: pendingPatients.map((p) {
                      final risk = p.triageRisk;
                      return Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_problem_outlined,
                                size: 16, color: AppColors.offlineBanner),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${p.age}y · ${p.village}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (risk != null) ...[
                              RiskBadge(riskLevel: risk),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.offlineBanner.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Waiting for sync',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.offlineBanner,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

