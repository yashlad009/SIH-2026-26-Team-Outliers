import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/login_screen.dart';
import 'features/chw_patient/new_patient_screen.dart';
import 'features/doctor/dummy_video_call_screen.dart';
import 'features/inventory/medicine_stock_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PreviewApp(),
    ),
  );
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink UI Preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F41BB)),
        useMaterial3: true,
      ),
      home: const PreviewHomeScreen(),
    );
  }
}

class PreviewHomeScreen extends StatelessWidget {
  const PreviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareLink UI Preview'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'This is a temporary preview entry point to inspect existing UI screens without running into missing dependency errors.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _PreviewButton(
            title: 'Login Screen',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
          _PreviewButton(
            title: 'New Patient Screen',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewPatientScreen()),
            ),
          ),
          _PreviewButton(
            title: 'Dummy Video Call Screen',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DummyVideoCallScreen(patientName: 'John Doe'),
              ),
            ),
          ),
          _PreviewButton(
            title: 'Medicine Stock Screen',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicineStockScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _PreviewButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: onTap,
        child: Text(title),
      ),
    );
  }
}
