/// Marathi strings for CareLink
/// Keys must match app_strings_en.dart exactly.
class AppStringsMr {
  AppStringsMr._();

  // ── App General ───────────────────────────────────────────────────────────
  static const String appName = 'केअरलिंक';
  static const String tagline = 'दर पावलावर काळजी जोडतो';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = 'लॉगिन';
  static const String logout = 'लॉगआउट';
  static const String email = 'ईमेल';
  static const String password = 'पासवर्ड';
  static const String loginButton = 'साइन इन करा';
  static const String loginLoading = 'साइन इन होत आहे…';
  static const String loginError = 'चुकीचा ईमेल किंवा पासवर्ड';
  static const String forgotPassword = 'पासवर्ड विसरलात?';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const String roleCHW = 'सामुदायिक आरोग्य कार्यकर्ता';
  static const String roleDoctor = 'डॉक्टर';
  static const String roleAdmin = 'प्रशासक';

  // ── Patient ───────────────────────────────────────────────────────────────
  static const String patients = 'रुग्ण';
  static const String patientList = 'रुग्ण यादी';
  static const String newPatient = 'नवीन रुग्ण';
  static const String patientName = 'रुग्णाचे नाव';
  static const String age = 'वय';
  static const String gender = 'लिंग';
  static const String male = 'पुरुष';
  static const String female = 'स्त्री';
  static const String other = 'इतर';
  static const String village = 'गाव';
  static const String contact = 'संपर्क क्रमांक';
  static const String abhaId = 'ABHA ID (पर्यायी)';
  static const String savePatient = 'रुग्ण जतन करा';
  static const String patientRecord = 'रुग्ण नोंद';
  static const String timeline = 'टाइमलाइन';
  static const String allEvents = 'सर्व';
  static const String vitalsFilter = 'महत्त्वाची चिन्हे';
  static const String prescriptionsFilter = 'औषधे';
  static const String referralsFilter = 'रेफरल';
  static const String visitsFilter = 'भेटी';

  // ── Triage ────────────────────────────────────────────────────────────────
  static const String triage = 'ट्रायज मूल्यांकन';
  static const String triageForm = 'ट्रायज फॉर्म';
  static const String symptoms = 'लक्षणे';
  static const String temperature = 'तापमान (°C)';
  static const String bloodPressureSystolic = 'रक्तदाब - सिस्टोलिक (mmHg)';
  static const String bloodPressureDiastolic = 'रक्तदाब - डायस्टोलिक (mmHg)';
  static const String heartRate = 'हृदय गती (bpm)';
  static const String spO2 = 'SpO₂ (%)';
  static const String respiratoryRate = 'श्वसन दर (/मिनिट)';
  static const String weight = 'वजन (kg)';
  static const String height = 'उंची (cm)';
  static const String chiefComplaint = 'मुख्य तक्रार';
  static const String additionalNotes = 'अतिरिक्त नोंदी';
  static const String runTriage = 'ट्रायज करा';
  static const String triageResult = 'ट्रायज निकाल';
  static const String riskLow = 'कमी जोखीम';
  static const String riskMedium = 'मध्यम जोखीम';
  static const String riskHigh = 'उच्च जोखीम';
  static const String aiNote = 'AI क्लिनिकल नोट';
  static const String aiDisclaimer = 'AI-सहाय्यित — हे क्लिनिकल निदान नाही';
  static const String generateAiNote = 'AI नोट तयार करा (डेमो)';

  // ── Consult ───────────────────────────────────────────────────────────────
  static const String consultRequest = 'सल्ला विनंती';
  static const String consultQueue = 'सल्ला रांग';
  static const String consultChat = 'सल्ला चॅट';
  static const String requestConsult = 'टेलिकन्सल्ट विनंती करा';
  static const String consultReason = 'सल्ल्याचे कारण';
  static const String urgency = 'तातडी';
  static const String acceptConsult = 'सल्ला स्वीकारा';
  static const String startVideoCall = 'व्हिडिओ कॉल सुरू करा';
  static const String videoCallPlaceholder = 'व्हिडिओ कॉल (डेमो)';
  static const String endCall = 'कॉल संपवा';
  static const String typeMessage = 'संदेश टाइप करा…';
  static const String send = 'पाठवा';
  static const String consultPending = 'प्रलंबित';
  static const String consultAccepted = 'स्वीकृत';
  static const String consultClosed = 'बंद';

  // ── Referral ──────────────────────────────────────────────────────────────
  static const String referral = 'रेफरल';
  static const String referrals = 'रेफरल';
  static const String raiseReferral = 'रेफरल द्या';
  static const String referralTo = 'कुठे रेफर करायचे';
  static const String referralReason = 'रेफरलचे कारण';
  static const String referralStatus = 'रेफरल स्थिती';
  static const String statusCreated = 'तयार';
  static const String statusAccepted = 'स्वीकृत';
  static const String statusScheduled = 'नियोजित';
  static const String statusCompleted = 'पूर्ण';
  static const String statusDropped = 'रद्द';
  static const String updateStatus = 'स्थिती अपडेट करा';
  static const String statusHistory = 'स्थिती इतिहास';

  // ── Inventory ─────────────────────────────────────────────────────────────
  static const String inventory = 'औषध साठा';
  static const String medicineName = 'औषध';
  static const String stockLevel = 'साठ्याची पातळी';
  static const String inStock = 'उपलब्ध';
  static const String lowStock = 'कमी';
  static const String outOfStock = 'उपलब्ध नाही';

  // ── Diagnostics ───────────────────────────────────────────────────────────
  static const String diagnostics = 'निदान चाचण्या';
  static const String pendingTests = 'प्रलंबित चाचण्या';
  static const String testName = 'चाचणी';
  static const String testStatus = 'स्थिती';
  static const String testPending = 'प्रलंबित';
  static const String testOrdered = 'आदेशित';
  static const String testCompleted = 'पूर्ण';

  // ── Follow-up ─────────────────────────────────────────────────────────────
  static const String followUp = 'फॉलो-अप कार्ये';
  static const String dueDate = 'देय तारीख';
  static const String taskCategory = 'प्रकार';
  static const String maternal = 'माता';
  static const String child = 'बाल';
  static const String ncd = 'असंसर्गजन्य रोग';
  static const String markDone = 'पूर्ण करा';
  static const String overdue = 'मुदत संपलेली';

  // ── Admin Dashboard ───────────────────────────────────────────────────────
  static const String dashboard = 'डॅशबोर्ड';
  static const String caseVolume = 'केस संख्या';
  static const String activeReferrals = 'सक्रिय रेफरल';
  static const String triageDistribution = 'ट्रायज वितरण';
  static const String stockLevels = 'साठ्याची पातळी';
  static const String totalPatients = 'एकूण रुग्ण';
  static const String thisWeek = 'या आठवड्यात';
  static const String thisMonth = 'या महिन्यात';

  // ── Roadmap ───────────────────────────────────────────────────────────────
  static const String roadmap = 'रोडमॅप';
  static const String comingNext = 'पुढे येणार';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settings = 'सेटिंग्ज';
  static const String language = 'भाषा';
  static const String english = 'English';
  static const String marathi = 'मराठी';
  static const String appVersion = 'अ‍ॅप आवृत्ती';
  static const String demoMode = 'डेमो मोड';

  // ── Common ────────────────────────────────────────────────────────────────
  static const String save = 'जतन करा';
  static const String cancel = 'रद्द करा';
  static const String confirm = 'पुष्टी करा';
  static const String delete = 'हटवा';
  static const String edit = 'संपादित करा';
  static const String back = 'मागे';
  static const String next = 'पुढे';
  static const String submit = 'सबमिट करा';
  static const String loading = 'लोड होत आहे…';
  static const String retry = 'पुन्हा प्रयत्न करा';
  static const String noData = 'माहिती उपलब्ध नाही';
  static const String error = 'काहीतरी चुकले';
  static const String offlineBanner = 'आपण ऑफलाइन आहात — कॅश केलेला डेटा दाखवत आहे';
  static const String onlineBanner = 'परत ऑनलाइन';
  static const String viewAll = 'सर्व पहा';
  static const String today = 'आज';
  static const String yesterday = 'काल';
  static const String unknown = 'अज्ञात';
}
