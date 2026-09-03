import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/local_cache_service.dart';
import '../core/constants/app_strings_en.dart';
import '../core/constants/app_strings_mr.dart';

enum AppLocale { en, mr }

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  // Read persisted locale
  final cached = LocalCacheService().getString(LocalCacheService.kLocale);
  final initial = cached == 'mr' ? AppLocale.mr : AppLocale.en;
  return LocaleNotifier(initial);
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

  void toggle() => setLocale(state == AppLocale.en ? AppLocale.mr : AppLocale.en);
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

  String get appName => isMr ? AppStringsMr.appName : AppStringsEn.appName;
  String get tagline => isMr ? AppStringsMr.tagline : AppStringsEn.tagline;
  String get login => isMr ? AppStringsMr.login : AppStringsEn.login;
  String get logout => isMr ? AppStringsMr.logout : AppStringsEn.logout;
  String get email => isMr ? AppStringsMr.email : AppStringsEn.email;
  String get password => isMr ? AppStringsMr.password : AppStringsEn.password;
  String get loginButton => isMr ? AppStringsMr.loginButton : AppStringsEn.loginButton;
  String get loginLoading => isMr ? AppStringsMr.loginLoading : AppStringsEn.loginLoading;
  String get loginError => isMr ? AppStringsMr.loginError : AppStringsEn.loginError;
  String get patients => isMr ? AppStringsMr.patients : AppStringsEn.patients;
  String get patientList => isMr ? AppStringsMr.patientList : AppStringsEn.patientList;
  String get newPatient => isMr ? AppStringsMr.newPatient : AppStringsEn.newPatient;
  String get patientName => isMr ? AppStringsMr.patientName : AppStringsEn.patientName;
  String get age => isMr ? AppStringsMr.age : AppStringsEn.age;
  String get gender => isMr ? AppStringsMr.gender : AppStringsEn.gender;
  String get village => isMr ? AppStringsMr.village : AppStringsEn.village;
  String get contact => isMr ? AppStringsMr.contact : AppStringsEn.contact;
  String get savePatient => isMr ? AppStringsMr.savePatient : AppStringsEn.savePatient;
  String get patientRecord => isMr ? AppStringsMr.patientRecord : AppStringsEn.patientRecord;
  String get triage => isMr ? AppStringsMr.triage : AppStringsEn.triage;
  String get triageForm => isMr ? AppStringsMr.triageForm : AppStringsEn.triageForm;
  String get symptoms => isMr ? AppStringsMr.symptoms : AppStringsEn.symptoms;
  String get temperature => isMr ? AppStringsMr.temperature : AppStringsEn.temperature;
  String get chiefComplaint => isMr ? AppStringsMr.chiefComplaint : AppStringsEn.chiefComplaint;
  String get runTriage => isMr ? AppStringsMr.runTriage : AppStringsEn.runTriage;
  String get triageResult => isMr ? AppStringsMr.triageResult : AppStringsEn.triageResult;
  String get aiDisclaimer => isMr ? AppStringsMr.aiDisclaimer : AppStringsEn.aiDisclaimer;
  String get consultRequest => isMr ? AppStringsMr.consultRequest : AppStringsEn.consultRequest;
  String get consultQueue => isMr ? AppStringsMr.consultQueue : AppStringsEn.consultQueue;
  String get referrals => isMr ? AppStringsMr.referrals : AppStringsEn.referrals;
  String get raiseReferral => isMr ? AppStringsMr.raiseReferral : AppStringsEn.raiseReferral;
  String get inventory => isMr ? AppStringsMr.inventory : AppStringsEn.inventory;
  String get diagnostics => isMr ? AppStringsMr.diagnostics : AppStringsEn.diagnostics;
  String get followUp => isMr ? AppStringsMr.followUp : AppStringsEn.followUp;
  String get dashboard => isMr ? AppStringsMr.dashboard : AppStringsEn.dashboard;
  String get settings => isMr ? AppStringsMr.settings : AppStringsEn.settings;
  String get language => isMr ? AppStringsMr.language : AppStringsEn.language;
  String get save => isMr ? AppStringsMr.save : AppStringsEn.save;
  String get cancel => isMr ? AppStringsMr.cancel : AppStringsEn.cancel;
  String get loading => isMr ? AppStringsMr.loading : AppStringsEn.loading;
  String get noData => isMr ? AppStringsMr.noData : AppStringsEn.noData;
  String get error => isMr ? AppStringsMr.error : AppStringsEn.error;
  String get send => isMr ? AppStringsMr.send : AppStringsEn.send;
  String get typeMessage => isMr ? AppStringsMr.typeMessage : AppStringsEn.typeMessage;
  String get viewAll => isMr ? AppStringsMr.viewAll : AppStringsEn.viewAll;
  String get roadmap => isMr ? AppStringsMr.roadmap : AppStringsEn.roadmap;
  String get english => AppStringsEn.english;
  String get marathi => AppStringsEn.marathi;
}
