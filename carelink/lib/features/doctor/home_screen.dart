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

import '../../providers/consult_provider.dart';
import '../../providers/referral_provider.dart';
import '../../models/referral_model.dart';

import '../../core/widgets/carelink_logo.dart';
import '../../providers/locale_provider.dart';
import 'high_risk_patients_screen.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final pages = [
      _DoctorOverviewTab(onTabSwitch: (i) => setState(() => _tab = i)),
      const ConsultQueueScreen(embedded: true),
      const ReferralListScreen(embedded: true),
    ];

    return AppScaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CareLinkLogo(width: 32, height: 32),
            const SizedBox(width: 8),
            Text('CareLink — ${strings.roleDoctor}'),
          ],
        ),
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
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              label: strings.isMr ? 'होम' : (strings.isHi ? 'होम' : 'Home')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.queue_outlined), label: strings.consultQueue),
          BottomNavigationBarItem(
              icon: const Icon(Icons.local_hospital_outlined), label: strings.referrals),
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
  final ValueChanged<int> onTabSwitch;
  const _DoctorOverviewTab({required this.onTabSwitch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(activeUserProfileProvider);
    final doctorPatientsAsync = user != null
        ? ref.watch(doctorPatientsProvider(user.uid))
        : const AsyncData<List<PatientModel>>([]);
    final pendingAsync = ref.watch(pendingConsultsProvider);
    final referralsAsync = ref.watch(allReferralsProvider);
    final highRiskAsync = ref.watch(highRiskPatientsProvider);

    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;
    final activeReferralsCount = referralsAsync.valueOrNull
            ?.where((r) =>
                r.currentStatus != ReferralStatus.completed &&
                r.currentStatus != ReferralStatus.dropped)
            .length ??
        0;

    final highRiskCount = highRiskAsync.valueOrNull?.length ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientListProvider);
        ref.invalidate(pendingConsultsProvider);
        ref.invalidate(allReferralsProvider);
        if (user != null) {
          ref.invalidate(doctorConsultsProvider(user.uid));
        }
      },
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

            // Live Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Pending Consults',
                    count: '$pendingCount',
                    icon: Icons.queue_outlined,
                    color: AppColors.riskMedium,
                    onTap: () => onTabSwitch(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    title: 'Active Referrals',
                    count: '$activeReferralsCount',
                    icon: Icons.local_hospital_outlined,
                    color: AppColors.primary,
                    onTap: () => onTabSwitch(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    title: 'High Risk Patients',
                    count: '$highRiskCount',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.riskHigh,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HighRiskPatientsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick action banner — Go to consult queue
            Card(
              color: AppColors.primary,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTabSwitch(1),
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
                            Text('Tap to review pending CHW consultation requests',
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

            Text('Patient Records',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            doctorPatientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const EmptyState(
                    message: 'No accepted patient records yet',
                    subtitle: 'Patients from accepted consultations will appear here',
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
                  message: 'Failed to load patient records',
                  subtitle: e.toString(),
                  icon: Icons.error_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.2),
              ),
            ],
          ),
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
