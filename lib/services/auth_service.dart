import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_session.dart';

abstract interface class AuthGateway {
  Stream<UserSession?> get sessionChanges;

  Future<UserSession> signIn(String email, String password);
  Future<UserSession> register(String name, String email, String password);
  Future<UserSession> signInAsGuest();
  Future<bool> isCurrentUserAdmin();
  Future<void> signOut();
}

class AuthService implements AuthGateway {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<UserSession?> get sessionChanges =>
      _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(null);
        if (user.isAnonymous) return Stream.value(_toSession(user, false));
        return _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .map(
              (profile) => _toSession(user, profile.data()?['rol'] == 'admin'),
            );
      });

  @override
  Future<UserSession> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication no devolvió un usuario.');
    }
    await _ensureFanProfile(user);
    return _sessionFor(user);
  }

  @override
  Future<UserSession> register(
    String name,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication no devolvió un usuario.');
    }
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'nombre': name.trim(),
      'email': user.email ?? email.trim(),
      'rol': 'fan',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return _toSession(user, false);
  }

  @override
  Future<UserSession> signInAsGuest() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication no devolvió un usuario.');
    }
    return _toSession(user, false);
  }

  @override
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;
    final profile = await _firestore.collection('users').doc(user.uid).get();
    return profile.data()?['rol'] == 'admin';
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<UserSession> _sessionFor(User user) async {
    if (user.isAnonymous) return _toSession(user, false);
    await _ensureFanProfile(user);
    return _toSession(user, await isCurrentUserAdmin());
  }

  Future<void> _ensureFanProfile(User user) async {
    final reference = _firestore.collection('users').doc(user.uid);
    final profile = await reference.get();
    if (!profile.exists) {
      await reference.set({
        'uid': user.uid,
        'nombre': user.displayName ?? '',
        'email': user.email ?? '',
        'rol': 'fan',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  UserSession _toSession(User user, bool isAdmin) => UserSession(
    uid: user.uid,
    email: user.email ?? 'INVITADO',
    isGuest: user.isAnonymous,
    isAdmin: isAdmin,
  );
}
