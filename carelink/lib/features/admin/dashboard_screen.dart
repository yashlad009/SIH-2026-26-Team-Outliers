import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/carelink_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/risk_badge.dart';
import '../../models/medicine_stock_model.dart';
import '../../models/patient_model.dart';
import '../../models/referral_model.dart';
import '../../models/triage_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/referral_provider.dart';
import '../chw_patient/follow_up_task_screen.dart';
import '../diagnostics/pending_tests_screen.dart';
import '../inventory/medicine_stock_screen.dart';
import '../patient_record/patient_record_screen.dart';
import '../settings/settings_screen.dart';
import 'charts/case_volume_chart.dart';
import 'charts/triage_distribution_chart.dart';
import 'control_room_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentTab = 0;
  String _patientRiskFilter = 'all';
  String _referralStatusFilter = 'all';

  void _switchToTab(int tabIndex, {String? patientFilter, String? referralFilter}) {
    setState(() {
      _currentTab = tabIndex;
      if (patientFilter != null) _patientRiskFilter = patientFilter;
      if (referralFilter != null) _referralStatusFilter = referralFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final pages = [
      _AdminHomeTab(onNavigate: _switchToTab),
      _AdminPatientsTab(
        initialRiskFilter: _patientRiskFilter,
        onFilterChanged: (f) => setState(() => _patientRiskFilter = f),
      ),
      _AdminReferralsTab(
        initialStatusFilter: _referralStatusFilter,
        onFilterChanged: (f) => setState(() => _referralStatusFilter = f),
      ),
      const _AdminFacilitiesTab(),
      _AdminMoreTab(onNavigate: _switchToTab),
    ];

    return AppScaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CareLinkLogo(width: 32, height: 32),
            const SizedBox(width: 8),
            Text('CareLink — ${strings.roleAdmin}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: strings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: strings.patients,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_hospital_outlined),
            activeIcon: const Icon(Icons.local_hospital),
            label: strings.referrals,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.business_outlined),
            activeIcon: const Icon(Icons.business),
            label: strings.facility,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz),
            activeIcon: const Icon(Icons.more_horiz),
            label: strings.viewAll,
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    ref.read(authServiceProvider).signOut();
    ref.read(userProfileProvider.notifier).clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0: ADMIN HOME (DISTRICT OVERVIEW)
// ─────────────────────────────────────────────────────────────────────────────
class _AdminHomeTab extends ConsumerWidget {
  final Function(int tab, {String? patientFilter, String? referralFilter}) onNavigate;
  const _AdminHomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(activeUserProfileProvider);
    final summary = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientListProvider);
        ref.invalidate(allReferralsProvider);
        ref.invalidate(allFollowUpTasksProvider);
        ref.invalidate(medicineStockProvider);
        ref.invalidate(allDiagnosticTestsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Banner ──────────────────────────────────────────────
            Card(
              elevation: 2,
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName.substring(0, 1).toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning, ${user?.displayName ?? 'Admin'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user?.facilityName ?? 'Pune Rural District Office',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                              SizedBox(width: 6),
                              Text(
                                'Online',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'District Overview — All Facilities',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          DateFormatters.formatDate(DateTime.now()),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Key Metrics Grid ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    title: 'Total Cases',
                    count: '${summary.totalPatients}',
                    icon: Icons.people_alt_outlined,
                    color: AppColors.primary,
                    onTap: () => onNavigate(1, patientFilter: 'all'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminMetricCard(
                    title: 'High-Risk',
                    count: '${summary.highRiskCount}',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.riskHigh,
                    onTap: () => onNavigate(1, patientFilter: 'high'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    title: 'Active Referrals',
                    count: '${summary.activeReferrals}',
                    icon: Icons.local_hospital_outlined,
                    color: AppColors.statusAccepted,
                    onTap: () => onNavigate(2, referralFilter: 'active'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminMetricCard(
                    title: 'Follow-ups Due',
                    count: '${summary.pendingFollowUps}',
                    subtitle: summary.overdueFollowUps > 0
                        ? '${summary.overdueFollowUps} overdue'
                        : null,
                    icon: Icons.task_alt_outlined,
                    color: AppColors.statusScheduled,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FollowUpTaskScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Needs Attention Section ─────────────────────────────────────────
            Text('Needs Attention', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildNeedsAttentionSection(context, summary, onNavigate),
            const SizedBox(height: 24),

            // ── Healthcare Activity Chart ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Healthcare Trends', style: Theme.of(context).textTheme.titleLarge),
                const Text('Last 7 Days',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _chartLegendDot(AppColors.primary, 'Cases Registered'),
                        const SizedBox(width: 16),
                        _chartLegendDot(AppColors.riskMedium, 'Referrals Created'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CaseVolumeChart(
                      data: summary.last7DaysCases
                          .map((e) => MapEntry(e.date, e.count))
                          .toList(),
                      referralData: summary.last7DaysReferrals
                          .map((e) => MapEntry(e.date, e.count))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Patient Risk Distribution ───────────────────────────────────────
            Text('Patient Risk Distribution',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TriageDistributionChart(
                  high: summary.highRiskCount,
                  medium: summary.mediumRiskCount,
                  low: summary.lowRiskCount,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNeedsAttentionSection(
    BuildContext context,
    DashboardSummary summary,
    Function(int tab, {String? patientFilter, String? referralFilter}) onNavigate,
  ) {
    final alerts = <Widget>[];

    if (summary.droppedReferrals > 0) {
      alerts.add(
        _AttentionTile(
          title: '${summary.droppedReferrals} Referral Drop-off${summary.droppedReferrals > 1 ? 's' : ''}',
          subtitle: 'Patients have not completed their referral.',
          icon: Icons.cancel_outlined,
          color: AppColors.riskHigh,
          onReview: () => onNavigate(2, referralFilter: 'dropped'),
        ),
      );
    }

    if (summary.highRiskCount > 0) {
      alerts.add(
        _AttentionTile(
          title: '${summary.highRiskCount} High-risk Patient${summary.highRiskCount > 1 ? 's' : ''}',
          subtitle: 'Patients requiring immediate operational / clinical tracking.',
          icon: Icons.warning_amber_rounded,
          color: AppColors.riskHigh,
          onReview: () => onNavigate(1, patientFilter: 'high'),
        ),
      );
    }

    if (summary.overdueFollowUps > 0) {
      alerts.add(
        _AttentionTile(
          title: '${summary.overdueFollowUps} Overdue Follow-up Task${summary.overdueFollowUps > 1 ? 's' : ''}',
          subtitle: 'Tasks past due date requiring CHW action.',
          icon: Icons.access_time_filled_outlined,
          color: AppColors.riskMedium,
          onReview: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FollowUpTaskScreen()),
          ),
        ),
      );
    }

    if (summary.lowStockCount > 0) {
      alerts.add(
        _AttentionTile(
          title: '${summary.lowStockCount} Medicine Item${summary.lowStockCount > 1 ? 's' : ''} Low in Stock',
          subtitle: 'Essential inventory below minimum threshold.',
          icon: Icons.inventory_2_outlined,
          color: AppColors.riskMedium,
          onReview: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MedicineStockScreen()),
          ),
        ),
      );
    }

    if (summary.pendingTestsCount > 0) {
      alerts.add(
        _AttentionTile(
          title: '${summary.pendingTestsCount} Pending Diagnostic Test${summary.pendingTestsCount > 1 ? 's' : ''}',
          subtitle: 'Tests awaiting sample processing or laboratory results.',
          icon: Icons.science_outlined,
          color: AppColors.primary,
          onReview: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PendingTestsScreen()),
          ),
        ),
      );
    }

    if (alerts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.riskLow, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('All Systems Operating Smoothly',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('No operational drop-offs or urgent alerts detected.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: alerts);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: ADMIN PATIENTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AdminPatientsTab extends ConsumerStatefulWidget {
  final String initialRiskFilter;
  final ValueChanged<String> onFilterChanged;

  const _AdminPatientsTab({
    required this.initialRiskFilter,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<_AdminPatientsTab> createState() => _AdminPatientsTabState();
}

class _AdminPatientsTabState extends ConsumerState<_AdminPatientsTab> {
  final _searchCtrl = TextEditingController();
  late String _currentRiskFilter;

  @override
  void initState() {
    super.initState();
    _currentRiskFilter = widget.initialRiskFilter;
  }

  @override
  void didUpdateWidget(covariant _AdminPatientsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRiskFilter != widget.initialRiskFilter) {
      setState(() {
        _currentRiskFilter = widget.initialRiskFilter;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientListProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search patients by name or village...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Risk Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('all', 'All Patients'),
                const SizedBox(width: 8),
                _filterChip('high', 'High Risk', color: AppColors.riskHigh),
                const SizedBox(width: 8),
                _filterChip('medium', 'Medium Risk', color: AppColors.riskMedium),
                const SizedBox(width: 8),
                _filterChip('low', 'Low Risk', color: AppColors.riskLow),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Patients List
          Expanded(
            child: patientsAsync.when(
              data: (allPatients) {
                final query = _searchCtrl.text.trim().toLowerCase();
                var filtered = allPatients.where((p) {
                  final matchQuery = query.isEmpty ||
                      p.name.toLowerCase().contains(query) ||
                      p.village.toLowerCase().contains(query);
                  final matchRisk = _currentRiskFilter == 'all' ||
                      (_currentRiskFilter == 'high' && p.triageRisk == RiskLevel.high) ||
                      (_currentRiskFilter == 'medium' && p.triageRisk == RiskLevel.medium) ||
                      (_currentRiskFilter == 'low' && p.triageRisk == RiskLevel.low);
                  return matchQuery && matchRisk;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    message: 'No patients found',
                    subtitle: 'Try adjusting your search or risk filter',
                    icon: Icons.people_outline,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final patient = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            patient.initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                patient.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (patient.triageRisk != null)
                              RiskBadge(riskLevel: patient.triageRisk!),
                          ],
                        ),
                        subtitle: Text(
                          '${patient.age}y · ${patient.gender.label} · ${patient.village}',
                        ),
                        trailing:
                            const Icon(Icons.chevron_right, color: AppColors.textHint),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientRecordScreen(patient: patient),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LoadingListItem(),
                ),
              ),
              error: (e, _) => EmptyState(
                message: 'Failed to load patients',
                subtitle: e.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, {Color? color}) {
    final isSelected = _currentRiskFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? AppColors.textPrimary),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      selectedColor: color ?? AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      onSelected: (_) {
        setState(() => _currentRiskFilter = value);
        widget.onFilterChanged(value);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: ADMIN REFERRALS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AdminReferralsTab extends ConsumerStatefulWidget {
  final String initialStatusFilter;
  final ValueChanged<String> onFilterChanged;

  const _AdminReferralsTab({
    required this.initialStatusFilter,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<_AdminReferralsTab> createState() => _AdminReferralsTabState();
}

class _AdminReferralsTabState extends ConsumerState<_AdminReferralsTab> {
  late String _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialStatusFilter;
  }

  @override
  void didUpdateWidget(covariant _AdminReferralsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatusFilter != widget.initialStatusFilter) {
      setState(() {
        _currentFilter = widget.initialStatusFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final referralsAsync = ref.watch(allReferralsProvider);

    return Scaffold(
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _filterChip('all', 'All Referrals'),
                const SizedBox(width: 8),
                _filterChip('active', 'Active'),
                const SizedBox(width: 8),
                _filterChip('completed', 'Completed', color: AppColors.statusCompleted),
                const SizedBox(width: 8),
                _filterChip('dropped', 'Dropped', color: AppColors.riskHigh),
              ],
            ),
          ),

          Expanded(
            child: referralsAsync.when(
              data: (allReferrals) {
                final filtered = allReferrals.where((r) {
                  if (_currentFilter == 'active') {
                    return r.currentStatus != ReferralStatus.completed &&
                        r.currentStatus != ReferralStatus.dropped;
                  }
                  if (_currentFilter == 'completed') {
                    return r.currentStatus == ReferralStatus.completed;
                  }
                  if (_currentFilter == 'dropped') {
                    return r.currentStatus == ReferralStatus.dropped;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    message: 'No referrals found',
                    subtitle: 'No referrals match the selected filter',
                    icon: Icons.local_hospital_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final refModel = filtered[index];
                    final isDoctor = refModel.raisedByRole.toLowerCase() == 'doctor' ||
                        refModel.raisedByName.toLowerCase().startsWith('dr') == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    refModel.patientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                _statusBadge(refModel.currentStatus),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Target Facility: ${refModel.referredTo}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDoctor
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : AppColors.secondary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isDoctor
                                        ? 'Created by Doctor — ${refModel.raisedByName.isNotEmpty ? refModel.raisedByName : 'Doctor'}'
                                        : 'Created by CHW — ${refModel.raisedByName.isNotEmpty ? refModel.raisedByName : 'CHW'}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDoctor
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormatters.formatDate(refModel.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LoadingListItem(),
                ),
              ),
              error: (e, _) => EmptyState(
                message: 'Failed to load referrals',
                subtitle: e.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, {Color? color}) {
    final isSelected = _currentFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? AppColors.textPrimary),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      selectedColor: color ?? AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      onSelected: (_) {
        setState(() => _currentFilter = value);
        widget.onFilterChanged(value);
      },
    );
  }

  Widget _statusBadge(ReferralStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case ReferralStatus.created:
        bg = AppColors.statusCreated.withValues(alpha: 0.12);
        fg = AppColors.statusCreated;
        break;
      case ReferralStatus.accepted:
        bg = AppColors.statusAccepted.withValues(alpha: 0.12);
        fg = AppColors.statusAccepted;
        break;
      case ReferralStatus.scheduled:
        bg = AppColors.statusScheduled.withValues(alpha: 0.12);
        fg = AppColors.statusScheduled;
        break;
      case ReferralStatus.completed:
        bg = AppColors.statusCompleted.withValues(alpha: 0.12);
        fg = AppColors.statusCompleted;
        break;
      case ReferralStatus.dropped:
        bg = AppColors.riskHigh.withValues(alpha: 0.12);
        fg = AppColors.riskHigh;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: ADMIN FACILITIES TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AdminFacilitiesTab extends ConsumerWidget {
  const _AdminFacilitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ControlRoomScreen(embedded: true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: ADMIN MORE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AdminMoreTab extends ConsumerWidget {
  final Function(int tab) onNavigate;
  const _AdminMoreTab({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(activeUserProfileProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                user?.displayName.isNotEmpty == true
                    ? user!.displayName.substring(0, 1).toUpperCase()
                    : 'A',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user?.displayName ?? 'District Administrator',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user?.email ?? 'admin@carelink.org'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Operational Modules',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary),
                title: const Text('Medicine Stock & Inventory'),
                subtitle: const Text('View and manage essential drug stocks'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicineStockScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.science_outlined,
                    color: AppColors.primary),
                title: const Text('Diagnostic Tests'),
                subtitle: const Text('View pending lab & diagnostic requests'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingTestsScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.task_alt_outlined,
                    color: AppColors.primary),
                title: const Text('Follow-up Tasks Overview'),
                subtitle: const Text('View CHW follow-up schedules'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FollowUpTaskScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('System', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.settings_outlined, color: AppColors.primary),
                title: const Text('Settings & Language'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.riskHigh),
                title: const Text('Sign Out',
                    style: TextStyle(color: AppColors.riskHigh)),
                onTap: () {
                  ref.read(authServiceProvider).signOut();
                  ref.read(userProfileProvider.notifier).clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _AdminMetricCard extends StatelessWidget {
  final String title;
  final String count;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminMetricCard({
    required this.title,
    required this.count,
    this.subtitle,
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 22),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textHint),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 10, color: AppColors.riskHigh),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onReview;

  const _AttentionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onReview,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
