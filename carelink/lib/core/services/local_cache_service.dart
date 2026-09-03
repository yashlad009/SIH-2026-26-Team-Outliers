import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed local cache for offline support.
/// Currently used to cache the last-viewed patient record as JSON.
class LocalCacheService {
  static const _patientBox = 'cachedPatients';
  static const _prefsBox = 'appPrefs';

  /// Must be called in main() before runApp.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_patientBox);
    await Hive.openBox<String>(_prefsBox);
  }

  // ── Patient caching ───────────────────────────────────────────────────────

  Future<void> cachePatient(String patientId, String jsonData) async {
    final box = Hive.box<String>(_patientBox);
    await box.put(patientId, jsonData);
  }

  String? getCachedPatient(String patientId) {
    final box = Hive.box<String>(_patientBox);
    return box.get(patientId);
  }

  Future<void> clearPatientCache(String patientId) async {
    final box = Hive.box<String>(_patientBox);
    await box.delete(patientId);
  }

  List<String> getCachedPatientIds() {
    final box = Hive.box<String>(_patientBox);
    return box.keys.cast<String>().toList();
  }

  // ── App preferences ───────────────────────────────────────────────────────

  Future<void> setString(String key, String value) async {
    final box = Hive.box<String>(_prefsBox);
    await box.put(key, value);
  }

  String? getString(String key) {
    final box = Hive.box<String>(_prefsBox);
    return box.get(key);
  }

  Future<void> remove(String key) async {
    final box = Hive.box<String>(_prefsBox);
    await box.delete(key);
  }

  // ── Known keys ────────────────────────────────────────────────────────────
  static const String kLocale = 'locale';
  static const String kSeedDone = 'seed_done';
}
