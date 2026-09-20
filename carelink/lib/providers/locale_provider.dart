import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/local_cache_service.dart';
import '../core/constants/app_strings_en.dart';
import '../core/constants/app_strings_mr.dart';
import '../core/constants/app_strings_hi.dart';
import '../models/user_model.dart';

enum AppLocale { en, mr, hi }

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  final cached = LocalCacheService().getString(LocalCacheService.kLocale);
  if (cached == 'mr') return LocaleNotifier(AppLocale.mr);
  if (cached == 'hi') return LocaleNotifier(AppLocale.hi);
  return LocaleNotifier(AppLocale.en);
});

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier(super.initial);

  void setLocale(AppLocale locale) {
    state = locale;
    LocalCacheService().setString(
      LocalCacheService.kLocale,
      locale.name,
    );
  }

  void cycle() {
    if (state == AppLocale.en) {
      setLocale(AppLocale.mr);
    } else if (state == AppLocale.mr) {
      setLocale(AppLocale.hi);
    } else {
      setLocale(AppLocale.en);
    }
  }
}

// ── String accessor ────────────────────────────────────────────────────────
// Usage: ref.watch(stringsProvider).login
final stringsProvider = Provider<_Strings>((ref) {
  final locale = ref.watch(localeProvider);
  return _Strings(locale);
});

class _Strings {
  final AppLocale locale;
  const _Strings(this.locale);

  bool get isMr => locale == AppLocale.mr;
  bool get isHi => locale == AppLocale.hi;
  bool get isEn => locale == AppLocale.en;

  String get appName => isMr
      ? AppStringsMr.appName
      : (isHi ? AppStringsHi.appName : AppStringsEn.appName);

  String get tagline => isMr
      ? AppStringsMr.tagline
      : (isHi ? AppStringsHi.tagline : AppStringsEn.tagline);

  String get login => isMr
      ? AppStringsMr.login
      : (isHi ? AppStringsHi.login : AppStringsEn.login);

  String get logout => isMr
      ? AppStringsMr.logout
      : (isHi ? AppStringsHi.logout : AppStringsEn.logout);

  String get email => isMr
      ? AppStringsMr.email
      : (isHi ? AppStringsHi.email : AppStringsEn.email);

  String get password => isMr
      ? AppStringsMr.password
      : (isHi ? AppStringsHi.password : AppStringsEn.password);

  String get loginButton => isMr
      ? AppStringsMr.loginButton
      : (isHi ? AppStringsHi.loginButton : AppStringsEn.loginButton);

  String get loginLoading => isMr
      ? AppStringsMr.loginLoading
      : (isHi ? AppStringsHi.loginLoading : AppStringsEn.loginLoading);

  String get loginError => isMr
      ? AppStringsMr.loginError
      : (isHi ? AppStringsHi.loginError : AppStringsEn.loginError);

  String get roleCHW => isMr
      ? AppStringsMr.roleCHW
      : (isHi ? AppStringsHi.roleCHW : AppStringsEn.roleCHW);

  String get roleDoctor => isMr
      ? AppStringsMr.roleDoctor
      : (isHi ? AppStringsHi.roleDoctor : AppStringsEn.roleDoctor);

  String get roleAdmin => isMr
      ? AppStringsMr.roleAdmin
      : (isHi ? AppStringsHi.roleAdmin : AppStringsEn.roleAdmin);

  String roleLabel(UserRole role) {
    switch (role) {
      case UserRole.chw:
        return roleCHW;
      case UserRole.doctor:
        return roleDoctor;
      case UserRole.admin:
        return roleAdmin;
    }
  }

  String get patients => isMr
      ? AppStringsMr.patients
      : (isHi ? AppStringsHi.patients : AppStringsEn.patients);

  String get patientList => isMr
      ? AppStringsMr.patientList
      : (isHi ? AppStringsHi.patientList : AppStringsEn.patientList);

  String get newPatient => isMr
      ? AppStringsMr.newPatient
      : (isHi ? AppStringsHi.newPatient : AppStringsEn.newPatient);

  String get patientName => isMr
      ? AppStringsMr.patientName
      : (isHi ? AppStringsHi.patientName : AppStringsEn.patientName);

  String get age => isMr
      ? AppStringsMr.age
      : (isHi ? AppStringsHi.age : AppStringsEn.age);

  String get gender => isMr
      ? AppStringsMr.gender
      : (isHi ? AppStringsHi.gender : AppStringsEn.gender);

  String get village => isMr
      ? AppStringsMr.village
      : (isHi ? AppStringsHi.village : AppStringsEn.village);

  String get contact => isMr
      ? AppStringsMr.contact
      : (isHi ? AppStringsHi.contact : AppStringsEn.contact);

  String get savePatient => isMr
      ? AppStringsMr.savePatient
      : (isHi ? AppStringsHi.savePatient : AppStringsEn.savePatient);

  String get patientRecord => isMr
      ? AppStringsMr.patientRecord
      : (isHi ? AppStringsHi.patientRecord : AppStringsEn.patientRecord);

  String get triage => isMr
      ? AppStringsMr.triage
      : (isHi ? AppStringsHi.triage : AppStringsEn.triage);

  String get triageForm => isMr
      ? AppStringsMr.triageForm
      : (isHi ? AppStringsHi.triageForm : AppStringsEn.triageForm);

  String get symptoms => isMr
      ? AppStringsMr.symptoms
      : (isHi ? AppStringsHi.symptoms : AppStringsEn.symptoms);

  String get temperature => isMr
      ? AppStringsMr.temperature
      : (isHi ? AppStringsHi.temperature : AppStringsEn.temperature);

  String get chiefComplaint => isMr
      ? AppStringsMr.chiefComplaint
      : (isHi ? AppStringsHi.chiefComplaint : AppStringsEn.chiefComplaint);

  String get runTriage => isMr
      ? AppStringsMr.runTriage
      : (isHi ? AppStringsHi.runTriage : AppStringsEn.runTriage);

  String get triageResult => isMr
      ? AppStringsMr.triageResult
      : (isHi ? AppStringsHi.triageResult : AppStringsEn.triageResult);

  String get riskLow => isMr
      ? AppStringsMr.riskLow
      : (isHi ? AppStringsHi.riskLow : AppStringsEn.riskLow);

  String get riskMedium => isMr
      ? AppStringsMr.riskMedium
      : (isHi ? AppStringsHi.riskMedium : AppStringsEn.riskMedium);

  String get riskHigh => isMr
      ? AppStringsMr.riskHigh
      : (isHi ? AppStringsHi.riskHigh : AppStringsEn.riskHigh);

  String get aiDisclaimer => isMr
      ? AppStringsMr.aiDisclaimer
      : (isHi ? AppStringsHi.aiDisclaimer : AppStringsEn.aiDisclaimer);

  String get consultRequest => isMr
      ? AppStringsMr.consultRequest
      : (isHi ? AppStringsHi.consultRequest : AppStringsEn.consultRequest);

  String get consultQueue => isMr
      ? AppStringsMr.consultQueue
      : (isHi ? AppStringsHi.consultQueue : AppStringsEn.consultQueue);

  String get consultChat => isMr
      ? AppStringsMr.consultChat
      : (isHi ? AppStringsHi.consultChat : AppStringsEn.consultChat);

  String get referrals => isMr
      ? AppStringsMr.referrals
      : (isHi ? AppStringsHi.referrals : AppStringsEn.referrals);

  String get raiseReferral => isMr
      ? AppStringsMr.raiseReferral
      : (isHi ? AppStringsHi.raiseReferral : AppStringsEn.raiseReferral);

  String get inventory => isMr
      ? AppStringsMr.inventory
      : (isHi ? AppStringsHi.inventory : AppStringsEn.inventory);

  String get diagnostics => isMr
      ? AppStringsMr.diagnostics
      : (isHi ? AppStringsHi.diagnostics : AppStringsEn.diagnostics);

  String get followUp => isMr
      ? AppStringsMr.followUp
      : (isHi ? AppStringsHi.followUp : AppStringsEn.followUp);

  String get dashboard => isMr
      ? AppStringsMr.dashboard
      : (isHi ? AppStringsHi.dashboard : AppStringsEn.dashboard);

  String get settings => isMr
      ? AppStringsMr.settings
      : (isHi ? AppStringsHi.settings : AppStringsEn.settings);

  String get language => isMr
      ? AppStringsMr.language
      : (isHi ? AppStringsHi.language : AppStringsEn.language);

  String get english => AppStringsEn.english;
  String get marathi => AppStringsEn.marathi;
  String get hindi => AppStringsEn.hindi;

  String get profile => isMr
      ? AppStringsMr.profile
      : (isHi ? AppStringsHi.profile : AppStringsEn.profile);

  String get facility => isMr
      ? AppStringsMr.facility
      : (isHi ? AppStringsHi.facility : AppStringsEn.facility);

  String get save => isMr
      ? AppStringsMr.save
      : (isHi ? AppStringsHi.save : AppStringsEn.save);

  String get cancel => isMr
      ? AppStringsMr.cancel
      : (isHi ? AppStringsHi.cancel : AppStringsEn.cancel);

  String get loading => isMr
      ? AppStringsMr.loading
      : (isHi ? AppStringsHi.loading : AppStringsEn.loading);

  String get noData => isMr
      ? AppStringsMr.noData
      : (isHi ? AppStringsHi.noData : AppStringsEn.noData);

  String get error => isMr
      ? AppStringsMr.error
      : (isHi ? AppStringsHi.error : AppStringsEn.error);

  String get send => isMr
      ? AppStringsMr.send
      : (isHi ? AppStringsHi.send : AppStringsEn.send);

  String get typeMessage => isMr
      ? AppStringsMr.typeMessage
      : (isHi ? AppStringsHi.typeMessage : AppStringsEn.typeMessage);

  String get viewAll => isMr
      ? AppStringsMr.viewAll
      : (isHi ? AppStringsHi.viewAll : AppStringsEn.viewAll);

  String get roadmap => isMr
      ? AppStringsMr.roadmap
      : (isHi ? AppStringsHi.roadmap : AppStringsEn.roadmap);

  // Dynamic template formatters
  String followUpTasksCount(int count) {
    if (isMr) return '$count फॉलो-अप कार्ये';
    if (isHi) return '$count फॉलो-अप कार्य';
    return '$count Follow-up Tasks';
  }

  String highRiskPatientsCount(int count) {
    if (isMr) return '$count उच्च जोखीम रुग्ण';
    if (isHi) return '$count उच्च जोखिम वाले मरीज';
    return '$count High-Risk Patients';
  }

  String activeReferralsCount(int count) {
    if (isMr) return '$count सक्रिय रेफरल';
    if (isHi) return '$count सक्रिय रेफरल';
    return '$count Active Referrals';
  }
}
