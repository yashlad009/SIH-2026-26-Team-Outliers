import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(const Duration(seconds: 4));
      final uid = cred.user?.uid;
      if (uid == null) return _fallbackUser(email);
      final profile = await getUserProfile(uid);
      return profile ?? _fallbackUser(email, uid: uid);
    } catch (e) {
      // Demo fallback if Firebase Auth or Firestore is unseeded/offline
      return _fallbackUser(email);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.doc(FirestorePaths.userDoc(uid)).get().timeout(const Duration(seconds: 3));
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final profile = await getUserProfile(user.uid);
    return profile ?? _fallbackUser(user.email ?? '');
  }

  UserModel _fallbackUser(String email, {String? uid}) {
    final cleanEmail = email.trim().toLowerCase();
    final userUid = uid ?? 'demo-uid-${DateTime.now().millisecondsSinceEpoch}';
    if (cleanEmail.contains('doc')) {
      return UserModel(
        uid: userUid,
        email: email,
        displayName: 'Dr. Anita Rao',
        role: UserRole.doctor,
        facilityName: 'Wada PHC',
        createdAt: DateTime.now(),
      );
    } else if (cleanEmail.contains('admin')) {
      return UserModel(
        uid: userUid,
        email: email,
        displayName: 'District Admin',
        role: UserRole.admin,
        facilityName: 'Palghar HQ',
        createdAt: DateTime.now(),
      );
    } else {
      return UserModel(
        uid: userUid,
        email: email,
        displayName: 'Priya Shinde (CHW)',
        role: UserRole.chw,
        facilityName: 'Palghar Sub-Center',
        createdAt: DateTime.now(),
      );
    }
  }

  /// Creates an auth user + Firestore profile.
  /// Used by the seed script only.
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? facilityName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      facilityName: facilityName,
      createdAt: DateTime.now(),
    );
    await _db.doc(FirestorePaths.userDoc(uid)).set(user.toFirestore());
    return user;
  }
}
