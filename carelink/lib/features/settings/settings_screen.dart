import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/carelink_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';
import '../../data/seed/seed_data.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final strings = ref.watch(stringsProvider);
    final user = ref.watch(activeUserProfileProvider);

    return AppScaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CareLink Header Banner
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CareLinkLogo(
                width: 44,
                height: 44,
                showText: true,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Profile section / card
          _sectionHeader(strings.profile),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      _initials(user?.displayName ?? 'User'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName
                              : (user?.role == UserRole.doctor
                                  ? 'Dr. Anita Rao'
                                  : user?.role == UserRole.admin
                                      ? 'District Admin'
                                      : 'Priya Shinde'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email.isNotEmpty == true
                              ? user!.email
                              : 'user@carelink.org',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            strings.roleLabel(user?.role ?? UserRole.chw),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user?.facilityName ??
                                    (user?.role == UserRole.doctor
                                        ? 'Wada PHC'
                                        : user?.role == UserRole.admin
                                            ? 'Palghar District HQ'
                                            : 'Palghar Sub-Center'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Language selection
          _sectionHeader(strings.language),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                RadioListTile<AppLocale>(
                  value: AppLocale.en,
                  groupValue: locale,
                  onChanged: (v) =>
                      ref.read(localeProvider.notifier).setLocale(v!),
                  title: const Text(
                    'English',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  activeColor: AppColors.primary,
                  dense: true,
                ),
                const Divider(height: 1, indent: 56),
                RadioListTile<AppLocale>(
                  value: AppLocale.mr,
                  groupValue: locale,
                  onChanged: (v) =>
                      ref.read(localeProvider.notifier).setLocale(v!),
                  title: const Text(
                    'मराठी',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  activeColor: AppColors.primary,
                  dense: true,
                ),
                const Divider(height: 1, indent: 56),
                RadioListTile<AppLocale>(
                  value: AppLocale.hi,
                  groupValue: locale,
                  onChanged: (v) =>
                      ref.read(localeProvider.notifier).setLocale(v!),
                  title: const Text(
                    'हिन्दी',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  activeColor: AppColors.primary,
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Demo Tools
          _sectionHeader('Demo Tools'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined,
                      color: AppColors.primary),
                  title: const Text('Seed Demo Data'),
                  subtitle: const Text(
                      'Populate Firestore with sample patients, triage, referrals…'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmSeed(context),
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading:
                      Icon(Icons.info_outline, color: AppColors.secondary),
                  title: Text('Demo Mode Active'),
                  subtitle: Text(
                      'API key via --dart-define=GEMINI_API_KEY=...\nMove to server before production.'),
                  isThreeLine: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About
          _sectionHeader('About'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoTile('App', 'CareLink'),
                _divider(),
                _infoTile('Version', '1.0.0+1 (MVP)'),
                _divider(),
                _infoTile('Hackathon', 'Smart India Hackathon 2026'),
                _divider(),
                _infoTile('Problem', 'SIH26133'),
                _divider(),
                _infoTile('Ministry', 'Govt. of Maharashtra — Health'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(strings.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.riskHigh,
                side: BorderSide(color: AppColors.riskHigh.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label,
          style:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return 'CL';
  }

  void _confirmSeed(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Seed Demo Data'),
        content: const Text(
            'This will write demo patients, triage results, referrals and more to Firestore.\n\nRun only once — running again will create duplicates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seeding data…')),
              );
              try {
                await SeedData.runSeed();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅  Demo data seeded successfully'),
                      backgroundColor: AppColors.riskLow,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seed error: $e'),
                      backgroundColor: AppColors.riskHigh,
                    ),
                  );
                }
              }
            },
            child: const Text('Run Seed'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authServiceProvider).signOut();
    ref.read(userProfileProvider.notifier).clear();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}
