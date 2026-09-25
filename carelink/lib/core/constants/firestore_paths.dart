/// Firestore collection/document path constants.
/// Always use these — never hardcode strings inline.
class FirestorePaths {
  FirestorePaths._();

  // ── Collections ───────────────────────────────────────────────────────────
  static const String users = 'users';
  static const String patients = 'patients';
  static const String triageResults = 'triage_results';
  static const String consultRequests = 'consult_requests';
  static const String referrals = 'referrals';
  static const String medicineStock = 'medicine_stock';
  static const String diagnosticTests = 'diagnostic_tests';
  static const String followUpTasks = 'follow_up_tasks';
  static const String timelineEvents = 'timeline_events';
  static const String careCases = 'care_cases';
  static const String facilities = 'facilities';

  // ── Sub-collections ───────────────────────────────────────────────────────
  /// Chat messages sub-collection under a consult_request doc
  static String consultMessages(String consultId) =>
      '$consultRequests/$consultId/messages';

  /// Timeline events sub-collection under a patient doc
  static String patientTimeline(String patientId) =>
      '$patients/$patientId/timeline';

  /// Referral status history sub-collection
  static String referralHistory(String referralId) =>
      '$referrals/$referralId/status_history';

  // ── User doc ──────────────────────────────────────────────────────────────
  static String userDoc(String uid) => '$users/$uid';
  static String patientDoc(String patientId) => '$patients/$patientId';
  static String referralDoc(String referralId) => '$referrals/$referralId';
  static String consultDoc(String consultId) => '$consultRequests/$consultId';
  static String careCaseDoc(String careCaseId) => '$careCases/$careCaseId';
}
