import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/referral_repository.dart';
import '../models/referral_model.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository();
});

final allReferralsProvider = StreamProvider<List<ReferralModel>>((ref) {
  return ref.watch(referralRepositoryProvider).watchAllReferrals();
});

final referralsByPatientProvider =
    StreamProvider.family<List<ReferralModel>, String>((ref, patientId) {
  return ref.watch(referralRepositoryProvider).watchReferralsByPatient(patientId);
});

final referralByIdProvider =
    FutureProvider.family<ReferralModel?, String>((ref, referralId) {
  return ref.watch(referralRepositoryProvider).getReferral(referralId);
});

final activeReferralsProvider = StreamProvider<List<ReferralModel>>((ref) {
  return ref.watch(referralRepositoryProvider).watchActiveReferrals();
});
