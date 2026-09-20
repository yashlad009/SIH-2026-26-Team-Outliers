/// Hindi strings for CareLink
/// Used by the locale system. Keys match app_strings_en.dart exactly.
class AppStringsHi {
  AppStringsHi._();

  // ── App General ───────────────────────────────────────────────────────────
  static const String appName = 'केयरलिंक';
  static const String tagline = 'स्वास्थ्य सेवाओं को हर कदम पर जोड़ना';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = 'लॉगिन';
  static const String logout = 'लॉगआउट';
  static const String email = 'ईमेल';
  static const String password = 'पासवर्ड';
  static const String loginButton = 'साइन इन करें';
  static const String loginLoading = 'साइन इन हो रहा है…';
  static const String loginError = 'अमान्य ईमेल या पासवर्ड';
  static const String forgotPassword = 'पासवर्ड भूल गए?';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const String roleCHW = 'सामुदायिक स्वास्थ्य कार्यकर्ता (CHW)';
  static const String roleDoctor = 'डॉक्टर';
  static const String roleAdmin = 'व्यवस्थापक (Admin)';

  // ── Patient ───────────────────────────────────────────────────────────────
  static const String patients = 'मरीज';
  static const String patientList = 'मरीजों की सूची';
  static const String newPatient = 'नया मरीज';
  static const String patientName = 'मरीज का नाम';
  static const String age = 'आयु';
  static const String gender = 'लिंग';
  static const String male = 'पुरुष';
  static const String female = 'महिला';
  static const String other = 'अन्य';
  static const String village = 'गांव';
  static const String contact = 'संपर्क नंबर';
  static const String abhaId = 'आभा आईडी (वैकल्पिक)';
  static const String savePatient = 'मरीज सुरक्षित करें';
  static const String patientRecord = 'मरीज रिकॉर्ड';
  static const String timeline = 'टाइमलाइन';
  static const String allEvents = 'सभी';
  static const String vitalsFilter = 'महत्वपूर्ण लक्षण';
  static const String prescriptionsFilter = 'दवाएं';
  static const String referralsFilter = 'रेफरल';
  static const String visitsFilter = 'दौरे';

  // ── Triage ────────────────────────────────────────────────────────────────
  static const String triage = 'ट्राइएज मूल्यांकन';
  static const String triageForm = 'ट्राइएज फॉर्म';
  static const String symptoms = 'लक्षण';
  static const String temperature = 'तापमान (°C)';
  static const String bloodPressureSystolic = 'बीपी सिस्टोलिक (mmHg)';
  static const String bloodPressureDiastolic = 'बीपी डायस्टोलिक (mmHg)';
  static const String heartRate = 'हृदय गति (bpm)';
  static const String spO2 = 'SpO₂ (%)';
  static const String respiratoryRate = 'श्वसन दर (/मिनट)';
  static const String weight = 'वजन (kg)';
  static const String height = 'ऊंचाई (cm)';
  static const String chiefComplaint = 'मुख्य शिकायत';
  static const String additionalNotes = 'अतिरिक्त टिप्पणी';
  static const String runTriage = 'ट्राइएज जांचें';
  static const String triageResult = 'ट्राइएज परिणाम';
  static const String riskLow = 'कम जोखिम';
  static const String riskMedium = 'मध्यम जोखिम';
  static const String riskHigh = 'उच्च जोखिम';
  static const String aiNote = 'AI क्लिनिकल नोट';
  static const String aiDisclaimer = 'AI-सहायता प्राप्त — यह क्लिनिकल निदान नहीं है';
  static const String generateAiNote = 'AI नोट तैयार करें (डेमो)';

  // ── Consult ───────────────────────────────────────────────────────────────
  static const String consultRequest = 'परामर्श अनुरोध';
  static const String consultQueue = 'परामर्श कतार';
  static const String consultChat = 'परामर्श चैट';
  static const String requestConsult = 'टेलीपरामर्श अनुरोध करें';
  static const String consultReason = 'परामर्श का कारण';
  static const String urgency = 'प्राथमिकता';
  static const String acceptConsult = 'परामर्श स्वीकार करें';
  static const String startVideoCall = 'वीडियो कॉल शुरू करें';
  static const String videoCallPlaceholder = 'वीडियो कॉल (डेमो)';
  static const String endCall = 'कॉल समाप्त करें';
  static const String typeMessage = 'संदेश टाइप करें…';
  static const String send = 'भेजें';
  static const String consultPending = 'लंबित';
  static const String consultAccepted = 'स्वीकृत';
  static const String consultClosed = 'बंद';

  // ── Referral ──────────────────────────────────────────────────────────────
  static const String referral = 'रेफरल';
  static const String referrals = 'रेफरल';
  static const String raiseReferral = 'रेफरल दर्ज करें';
  static const String referralTo = 'रेफर करें';
  static const String referralReason = 'रेफरल का कारण';
  static const String referralStatus = 'रेफरल स्थिति';
  static const String statusCreated = 'निर्मित';
  static const String statusAccepted = 'स्वीकृत';
  static const String statusScheduled = 'निर्धारित';
  static const String statusCompleted = 'पूर्ण';
  static const String statusDropped = 'रद्द';
  static const String updateStatus = 'स्थिति अद्यतन करें';
  static const String statusHistory = 'स्थिति इतिहास';

  // ── Inventory ─────────────────────────────────────────────────────────────
  static const String inventory = 'दवा सूची';
  static const String medicineName = 'दवा';
  static const String stockLevel = 'स्टॉक स्तर';
  static const String inStock = 'उपलब्ध';
  static const String lowStock = 'कम';
  static const String outOfStock = 'स्टॉक खत्म';

  // ── Diagnostics ───────────────────────────────────────────────────────────
  static const String diagnostics = 'निदान परीक्षण';
  static const String pendingTests = 'लंबित परीक्षण';
  static const String testName = 'परीक्षण';
  static const String testStatus = 'स्थिति';
  static const String testPending = 'लंबित';
  static const String testOrdered = 'आदेशित';
  static const String testCompleted = 'पूर्ण';

  // ── Follow-up ─────────────────────────────────────────────────────────────
  static const String followUp = 'फॉलो-अप कार्य';
  static const String dueDate = 'नियत तिथि';
  static const String taskCategory = 'श्रेणी';
  static const String maternal = 'मातृ स्वास्थ्य';
  static const String child = 'बाल स्वास्थ्य';
  static const String ncd = 'गैर-संचारी रोग (NCD)';
  static const String markDone = 'पूर्ण चिन्हित करें';
  static const String overdue = 'समयातीत';

  // ── Admin Dashboard ───────────────────────────────────────────────────────
  static const String dashboard = 'डैशबोर्ड';
  static const String caseVolume = 'मामलों की संख्या';
  static const String activeReferrals = 'सक्रिय रेफरल';
  static const String triageDistribution = 'ट्राइएज वितरण';
  static const String stockLevels = 'स्टॉक स्तर';
  static const String totalPatients = 'कुल मरीज';
  static const String thisWeek = 'इस सप्ताह';
  static const String thisMonth = 'इस महीने';

  // ── Roadmap ───────────────────────────────────────────────────────────────
  static const String roadmap = 'रोडमैप';
  static const String comingNext = 'आगामी सुविधाएँ';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settings = 'सेटिंग्स';
  static const String language = 'भाषा (Language)';
  static const String english = 'English';
  static const String marathi = 'मराठी';
  static const String hindi = 'हिन्दी';
  static const String appVersion = 'ऐप संस्करण';
  static const String demoMode = 'डेमो मोड';
  static const String profile = 'प्रोफ़ाइल';
  static const String facility = 'स्वास्थ्य केंद्र';

  // ── Common ────────────────────────────────────────────────────────────────
  static const String save = 'सुरक्षित करें';
  static const String cancel = 'रद्द करें';
  static const String confirm = 'पुष्टि करें';
  static const String delete = 'हटाएं';
  static const String edit = 'संपादित करें';
  static const String back = 'वापस';
  static const String next = 'आगे';
  static const String submit = 'जमा करें';
  static const String loading = 'लोड हो रहा है…';
  static const String retry = 'पुनः प्रयास करें';
  static const String noData = 'कोई डेटा उपलब्ध नहीं';
  static const String error = 'कुछ गलत हो गया';
  static const String offlineBanner = 'आप ऑफ़लाइन हैं — सहेजा गया डेटा दिखाया जा रहा है';
  static const String onlineBanner = 'पुनः ऑनलाइन';
  static const String viewAll = 'सभी देखें';
  static const String today = 'आज';
  static const String yesterday = 'कल';
  static const String unknown = 'अज्ञात';
}
