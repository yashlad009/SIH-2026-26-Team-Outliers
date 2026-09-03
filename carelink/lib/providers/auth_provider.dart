import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return ref.read(authServiceProvider).getUserProfile(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserModel?>((ref) {
  return UserProfileNotifier(ref.read(authServiceProvider));
});

class UserProfileNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  UserProfileNotifier(this._authService) : super(null);

  Future<void> load() async {
    state = await _authService.getCurrentUserProfile();
  }

  void set(UserModel? user) => state = user;

  void clear() => state = null;
}
