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

/// Always returns the active user profile from state, async stream, or authenticated Firebase user.
final activeUserProfileProvider = Provider<UserModel?>((ref) {
  final stateUser = ref.watch(userProfileProvider);
  if (stateUser != null) return stateUser;

  final asyncUser = ref.watch(currentUserProfileProvider).valueOrNull;
  if (asyncUser != null) return asyncUser;

  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    final email = (firebaseUser.email ?? '').toLowerCase();
    final displayName = firebaseUser.displayName?.isNotEmpty == true
        ? firebaseUser.displayName!
        : (email.contains('doc')
            ? 'Dr. Anita Rao'
            : email.contains('admin')
                ? 'District Admin'
                : 'Priya Shinde (CHW)');
    final role = email.contains('doc')
        ? UserRole.doctor
        : email.contains('admin')
            ? UserRole.admin
            : UserRole.chw;
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? 'user@carelink.org',
      displayName: displayName,
      role: role,
      facilityName: role == UserRole.doctor
          ? 'Wada PHC'
          : role == UserRole.admin
              ? 'Palghar HQ'
              : 'Palghar Sub-Center',
      createdAt: DateTime.now(),
    );
  }

  return null;
});

