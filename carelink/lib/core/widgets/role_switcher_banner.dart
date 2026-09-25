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
    final activeUid = activeUser?.uid ?? 'chw_uid';

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
              uid: 'chw_uid',
              role: UserRole.chw,
              label: 'CHW',
              isSelected: activeUid == 'chw_uid',
              email: 'chw@carelink.demo',
              displayName: 'Sunita Kamble (CHW)',
              facility: 'Nashik PHC Ward 3',
            ),
            const SizedBox(width: 4),
            _roleChip(
              ref: ref,
              context: context,
              uid: 'demo_doctor_vikram',
              role: UserRole.doctor,
              label: 'Dr. Vikram (Pulmonology)',
              isSelected: activeUid == 'demo_doctor_vikram',
              email: 'doctor.vikram@carelink.demo',
              displayName: 'Dr. Vikram Deshmukh',
              facility: 'Nashik Civil Hospital',
              specialty: 'Pulmonology',
            ),
            const SizedBox(width: 4),
            _roleChip(
              ref: ref,
              context: context,
              uid: 'doctor_uid',
              role: UserRole.doctor,
              label: 'Dr. Rajesh',
              isSelected: activeUid == 'doctor_uid',
              email: 'doctor@carelink.demo',
              displayName: 'Dr. Rajesh Patil',
              facility: 'Nashik PHC Ward 3',
              specialty: 'Cardiology',
            ),
            const SizedBox(width: 4),
            _roleChip(
              ref: ref,
              context: context,
              uid: 'admin_uid',
              role: UserRole.admin,
              label: 'Control Room',
              isSelected: activeUid == 'admin_uid',
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
    required String uid,
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
          uid: uid,
          email: email,
          displayName: displayName,
          role: role,
          facilityName: facility,
          specialty: specialty,
          isOnDuty: true,
          activeWorkload: role == UserRole.doctor ? 1 : 0,
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

