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
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user?.uid;
    if (uid == null) return null;
    return getUserProfile(uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.doc(FirestorePaths.userDoc(uid)).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return getUserProfile(uid);
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
