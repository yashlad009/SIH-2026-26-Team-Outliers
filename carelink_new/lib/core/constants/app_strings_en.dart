/// English strings for CareLink
/// Used by the locale system. Keys must match app_strings_mr.dart exactly.
class AppStringsEn {
  AppStringsEn._();

  // ── App General ───────────────────────────────────────────────────────────
  static const String appName = 'CareLink';
  static const String tagline = 'Connecting Care, Every Step';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String loginButton = 'Sign In';
  static const String loginLoading = 'Signing in…';
  static const String loginError = 'Invalid email or password';
  static const String forgotPassword = 'Forgot password?';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const String roleCHW = 'Community Health Worker';
  static const String roleDoctor = 'Doctor';
  static const String roleAdmin = 'Admin';

  // ── Patient ───────────────────────────────────────────────────────────────
  static const String patients = 'Patients';
  static const String patientList = 'Patient List';
  static const String newPatient = 'New Patient';
  static const String patientName = 'Patient Name';
  static const String age = 'Age';
  static const String gender = 'Gender';
  static const String male = 'Male';
  static const String female = 'Female';
  static const String other = 'Other';
  static const String village = 'Village';
  static const String contact = 'Contact Number';
  static const String abhaId = 'ABHA ID (optional)';
  static const String savePatient = 'Save Patient';
  static const String patientRecord = 'Patient Record';
  static const String timeline = 'Timeline';
  static const String allEvents = 'All';
  static const String vitalsFilter = 'Vitals';
  static const String prescriptionsFilter = 'Prescriptions';
  static const String referralsFilter = 'Referrals';
  static const String visitsFilter = 'Visits';

  // ── Triage ────────────────────────────────────────────────────────────────
  static const String triage = 'Triage Assessment';
  static const String triageForm = 'Triage Form';
  static const String symptoms = 'Symptoms';
  static const String temperature = 'Temperature (°C)';
  static const String bloodPressureSystolic = 'BP Systolic (mmHg)';
  static const String bloodPressureDiastolic = 'BP Diastolic (mmHg)';
  static const String heartRate = 'Heart Rate (bpm)';
  static const String spO2 = 'SpO₂ (%)';
  static const String respiratoryRate = 'Respiratory Rate (/min)';
  static const String weight = 'Weight (kg)';
  static const String height = 'Height (cm)';
  static const String chiefComplaint = 'Chief Complaint';
  static const String additionalNotes = 'Additional Notes';
  static const String runTriage = 'Run Triage';
  static const String triageResult = 'Triage Result';
  static const String riskLow = 'Low Risk';
  static const String riskMedium = 'Medium Risk';
  static const String riskHigh = 'High Risk';
  static const String aiNote = 'AI Clinical Note';
  static const String aiDisclaimer = 'AI-assisted — not a clinical diagnosis';
  static const String generateAiNote = 'Generate AI Note (Demo)';

  // ── Consult ───────────────────────────────────────────────────────────────
  static const String consultRequest = 'Request Consultation';
  static const String consultQueue = 'Consultation Queue';
  static const String consultChat = 'Consultation Chat';
  static const String requestConsult = 'Request Teleconsult';
  static const String consultReason = 'Reason for Consultation';
  static const String urgency = 'Urgency';
  static const String acceptConsult = 'Accept Consultation';
  static const String startVideoCall = 'Start Video Call';
  static const String videoCallPlaceholder = 'Video Call (Demo)';
  static const String endCall = 'End Call';
  static const String typeMessage = 'Type a message…';
  static const String send = 'Send';
  static const String consultPending = 'Pending';
  static const String consultAccepted = 'Accepted';
  static const String consultClosed = 'Closed';

  // ── Referral ──────────────────────────────────────────────────────────────
  static const String referral = 'Referral';
  static const String referrals = 'Referrals';
  static const String raiseReferral = 'Raise Referral';
  static const String referralTo = 'Refer To';
  static const String referralReason = 'Reason for Referral';
  static const String referralStatus = 'Referral Status';
  static const String statusCreated = 'Created';
  static const String statusAccepted = 'Accepted';
  static const String statusScheduled = 'Scheduled';
  static const String statusCompleted = 'Completed';
  static const String statusDropped = 'Dropped';
  static const String updateStatus = 'Update Status';
  static const String statusHistory = 'Status History';

  // ── Inventory ─────────────────────────────────────────────────────────────
  static const String inventory = 'Medicine Inventory';
  static const String medicineName = 'Medicine';
  static const String stockLevel = 'Stock Level';
  static const String inStock = 'In Stock';
  static const String lowStock = 'Low';
  static const String outOfStock = 'Out of Stock';

  // ── Diagnostics ───────────────────────────────────────────────────────────
  static const String diagnostics = 'Diagnostic Tests';
  static const String pendingTests = 'Pending Tests';
  static const String testName = 'Test';
  static const String testStatus = 'Status';
  static const String testPending = 'Pending';
  static const String testOrdered = 'Ordered';
  static const String testCompleted = 'Completed';

  // ── Follow-up ─────────────────────────────────────────────────────────────
  static const String followUp = 'Follow-up Tasks';
  static const String dueDate = 'Due Date';
  static const String taskCategory = 'Category';
  static const String maternal = 'Maternal';
  static const String child = 'Child';
  static const String ncd = 'NCD';
  static const String markDone = 'Mark Done';
  static const String overdue = 'Overdue';

  // ── Admin Dashboard ───────────────────────────────────────────────────────
  static const String dashboard = 'Dashboard';
  static const String caseVolume = 'Case Volume';
  static const String activeReferrals = 'Active Referrals';
  static const String triageDistribution = 'Triage Distribution';
  static const String stockLevels = 'Stock Levels';
  static const String totalPatients = 'Total Patients';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';

  // ── Roadmap ───────────────────────────────────────────────────────────────
  static const String roadmap = 'Roadmap';
  static const String comingNext = 'Coming Next';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settings = 'Settings';
  static const String language = 'Language';
  static const String english = 'English';
  static const String marathi = 'मराठी';
  static const String appVersion = 'App Version';
  static const String demoMode = 'Demo Mode';

  // ── Common ────────────────────────────────────────────────────────────────
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String submit = 'Submit';
  static const String loading = 'Loading…';
  static const String retry = 'Retry';
  static const String noData = 'No data available';
  static const String error = 'Something went wrong';
  static const String offlineBanner = 'You are offline — showing cached data';
  static const String onlineBanner = 'Back online';
  static const String viewAll = 'View All';
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String unknown = 'Unknown';
}
