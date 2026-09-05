import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'models/user_model.dart';
import 'features/auth/login_screen.dart';
import 'features/chw_patient/home_screen.dart';
import 'features/doctor/home_screen.dart';
import 'features/admin/dashboard_screen.dart';

class CareLinkApp extends ConsumerWidget {
  const CareLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale for language toggle
    final locale = ref.watch(localeProvider);
    
    return MaterialApp(
      title: 'CareLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Pass the current locale down
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Firebase Auth state
    final authState = ref.watch(authStateProvider);
    // Watch our custom user profile
    final stateProfile = ref.watch(userProfileProvider);
    final asyncProfile = ref.watch(currentUserProfileProvider);
    final userProfile = stateProfile ?? asyncProfile.value;

    return authState.when(
      data: (User? user) {
        if (user == null && stateProfile == null) {
          return const LoginScreen();
        }

        final activeProfile = userProfile ?? _getFallbackProfile(user?.email);

        // Route based on role
        switch (activeProfile.role) {
          case UserRole.chw:
            return const ChwHomeScreen();
          case UserRole.doctor:
            return const DoctorHomeScreen();
          case UserRole.admin:
            return const AdminDashboardScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, trace) => const LoginScreen(),
    );
  }

  UserModel _getFallbackProfile(String? email) {
    final clean = (email ?? '').toLowerCase();
    if (clean.contains('doc')) {
      return UserModel(
        uid: 'fallback-doc',
        email: email ?? 'doctor@carelink.demo',
        displayName: 'Dr. Anita Rao',
        role: UserRole.doctor,
        facilityName: 'Wada PHC',
        createdAt: DateTime.now(),
      );
    } else if (clean.contains('admin')) {
      return UserModel(
        uid: 'fallback-admin',
        email: email ?? 'admin@carelink.demo',
        displayName: 'District Admin',
        role: UserRole.admin,
        facilityName: 'Palghar HQ',
        createdAt: DateTime.now(),
      );
    } else {
      return UserModel(
        uid: 'fallback-chw',
        email: email ?? 'chw@carelink.demo',
        displayName: 'Priya Shinde (CHW)',
        role: UserRole.chw,
        facilityName: 'Palghar Sub-Center',
        createdAt: DateTime.now(),
      );
    }
  }
}
