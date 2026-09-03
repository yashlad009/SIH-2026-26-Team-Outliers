import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
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
    final userProfile = ref.watch(userProfileProvider);

    return authState.when(
      data: (User? user) {
        if (user == null) {
          return const LoginScreen();
        }

        // If user is logged in to Firebase but profile is not loaded yet
        if (userProfile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Route based on role
        switch (userProfile.role) {
          case 'chw':
            return const CHWHomeScreen();
          case 'doctor':
            return const DoctorHomeScreen();
          case 'admin':
            return const AdminDashboardScreen();
          default:
            return const Scaffold(
              body: Center(child: Text('Unknown Role. Please contact Admin.')),
            );
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, trace) => Scaffold(
        body: Center(child: Text('Auth Error: $e')),
      ),
    );
  }
}
