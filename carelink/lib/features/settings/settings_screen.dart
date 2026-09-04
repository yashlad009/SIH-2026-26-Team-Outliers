import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';
import '../../data/seed/seed_data.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final user = ref.watch(userProfileProvider);
    final isMr = locale == AppLocale.mr;

    return AppScaffold(
      appBar: AppBar(title: Text(isMr ? 'सेटिंग्ज' : 'Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    _initials(user?.displayName ?? '?'),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.displayName ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(user?.email ?? '—',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(user?.role.label ?? '—',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary)),
                  if (user?.facilityName != null)
                    Text(user!.facilityName!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Language toggle
          _sectionHeader(isMr ? 'भाषा' : 'Language'),
          Card(
            child: Column(children: [
              RadioListTile<AppLocale>(
                value: AppLocale.en,
                groupValue: locale,
                onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
                title: const Text('English'),
                activeColor: AppColors.primary,
                dense: true,
              ),
              const Divider(height: 1, indent: 56),
              RadioListTile<AppLocale>(
                value: AppLocale.mr,
                groupValue: locale,
                onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
                title: const Text('मराठी'),
                activeColor: AppColors.primary,
                dense: true,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Demo / Seed
          _sectionHeader('Demo Tools'),
          Card(
            child: Column(children: [
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
              ListTile(
                leading:
                    const Icon(Icons.info_outline, color: AppColors.secondary),
                title: const Text('Demo Mode Active'),
                subtitle: const Text(
                    'API key via --dart-define=GEMINI_API_KEY=...\nMove to server before production.'),
                isThreeLine: true,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // About
          _sectionHeader('About'),
          Card(
            child: Column(children: [
              _infoTile('App', 'CareLink'),
              _divider(),
              _infoTile('Version', '1.0.0+1 (MVP)'),
              _divider(),
              _infoTile('Hackathon', 'Smart India Hackathon 2026'),
              _divider(),
              _infoTile('Problem', 'SIH26133'),
              _divider(),
              _infoTile('Ministry', 'Govt. of Maharashtra — Health'),
            ]),
          ),
          const SizedBox(height: 20),

          // Logout
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(isMr ? 'लॉगआउट' : 'Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.riskHigh,
                side: BorderSide(color: AppColors.riskHigh.withOpacity(0.5)),
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
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1)),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      trailing: Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16);

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
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
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show loading snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seeding data…')));
              try {
                await SeedData.runSeed();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('✅  Demo data seeded successfully'),
                        backgroundColor: AppColors.riskLow),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Seed error: $e'),
                          backgroundColor: AppColors.riskHigh));
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
