import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/local_cache_service.dart';
import 'data/seed/demo_seeder.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive boxes for local caching
  await LocalCacheService.init();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    DemoSeeder.seedDemoDoctorAndConsults().catchError((e) => debugPrint("Demo seed error: $e"));
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(const ProviderScope(child: CareLinkApp()));
}

