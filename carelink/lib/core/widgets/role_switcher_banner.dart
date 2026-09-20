import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../constants/app_colors.dart';

class RoleSwitcherBanner extends ConsumerWidget {
  const RoleSwitcherBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser = ref.watch(activeUserProfileProvider);
    final currentRole = activeUser?.role ?? UserRole.chw;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.amber.shade900,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.slideshow_outlined, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            const Text(
              'DEMO ROLE SWITCHER: ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            _roleChip(
              ref: ref,
              context: context,
              role: UserRole.chw,
              label: 'CHW',
              isSelected: currentRole == UserRole.chw,
              email: 'chw@carelink.demo',
              displayName: 'Sunita Kamble (CHW)',
              facility: 'Nashik PHC Ward 3',
            ),
            const SizedBox(width: 4),
            _roleChip(
              ref: ref,
              context: context,
              role: UserRole.doctor,
              label: 'Doctor',
              isSelected: currentRole == UserRole.doctor,
              email: 'doctor@carelink.demo',
              displayName: 'Dr. Rajesh Patil',
              facility: 'Nashik PHC Ward 3',
              specialty: 'Cardiology',
            ),
            const SizedBox(width: 4),
            _roleChip(
              ref: ref,
              context: context,
              role: UserRole.admin,
              label: 'Control Room',
              isSelected: currentRole == UserRole.admin,
              email: 'admin@carelink.demo',
              displayName: 'Priya Deshmukh (Admin)',
              facility: 'Nashik District Health Office',
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip({
    required WidgetRef ref,
    required BuildContext context,
    required UserRole role,
    required String label,
    required bool isSelected,
    required String email,
    required String displayName,
    required String facility,
    String? specialty,
  }) {
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        final newUser = UserModel(
          uid: role == UserRole.doctor
              ? 'doctor_uid'
              : role == UserRole.admin
                  ? 'admin_uid'
                  : 'chw_uid',
          email: email,
          displayName: displayName,
          role: role,
          facilityName: facility,
          specialty: specialty,
          isOnDuty: true,
          activeWorkload: role == UserRole.doctor ? 2 : 0,
          createdAt: DateTime.now(),
        );
        ref.read(userProfileProvider.notifier).set(newUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to $displayName role view'),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.amber.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.amber.shade700,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.amber.shade900 : Colors.white,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
