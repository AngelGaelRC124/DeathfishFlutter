import 'dart:async';

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
    : _auth = auth, // ignore: prefer_initializing_formals
      _firestore = firestore; // ignore: prefer_initializing_formals

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final StreamController<UserSession?> _localSessionChanges =
      StreamController<UserSession?>.broadcast(sync: true);
  UserSession? _localGuestSession;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestoreDb =>
      _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserSession?> get sessionChanges =>
      Stream<UserSession?>.multi((controller) {
        StreamSubscription<User?>? authSubscription;
        StreamSubscription<UserSession?>? localSubscription;
        StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
        profileSubscription;

        void observeUser(User? user) {
          unawaited(profileSubscription?.cancel());
          profileSubscription = null;
          final localGuest = _localGuestSession;
          if (localGuest != null) {
            controller.add(localGuest);
          } else if (user == null) {
            controller.add(null);
          } else if (user.isAnonymous) {
            controller.add(_toSession(user, false));
          } else {
            profileSubscription = _firestoreDb
                .collection('users')
                .doc(user.uid)
                .snapshots()
                .listen((profile) {
                  final data = profile.data();
                  controller.add(
                    _toSession(
                      user,
                      data?['rol'] == 'admin',
                      name: data?['nombre'] as String?,
                    ),
                  );
                }, onError: controller.addError);
          }
        }

        authSubscription = _firebaseAuth.authStateChanges().listen(
          observeUser,
          onError: controller.addError,
        );
        localSubscription = _localSessionChanges.stream.listen((session) {
          _localGuestSession = session;
          observeUser(_firebaseAuth.currentUser);
        }, onError: controller.addError);

        controller.onCancel = () async {
          await authSubscription?.cancel();
          await localSubscription?.cancel();
          await profileSubscription?.cancel();
        };
      });

  @override
  Future<UserSession> signIn(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
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
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication no devolvió un usuario.');
    }
    await _firestoreDb.collection('users').doc(user.uid).set({
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
    const session = UserSession(
      uid: 'local-guest',
      email: 'INVITADO',
      isGuest: true,
    );
    _localGuestSession = session;
    _localSessionChanges.add(session);
    return session;
  }

  @override
  Future<bool> isCurrentUserAdmin() async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.isAnonymous) return false;
    final profile = await _firestoreDb.collection('users').doc(user.uid).get();
    return profile.data()?['rol'] == 'admin';
  }

  @override
  Future<void> signOut() async {
    if (_localGuestSession != null) {
      _localGuestSession = null;
      _localSessionChanges.add(null);
      return;
    }
    await _firebaseAuth.signOut();
  }

  Future<UserSession> _sessionFor(User user) async {
    if (user.isAnonymous) return _toSession(user, false);
    await _ensureFanProfile(user);
    return _toSession(user, await isCurrentUserAdmin());
  }

  Future<void> _ensureFanProfile(User user) async {
    final reference = _firestoreDb.collection('users').doc(user.uid);
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

  UserSession _toSession(User user, bool isAdmin, {String? name}) =>
      UserSession(
        uid: user.uid,
        email: user.email ?? 'INVITADO',
        isGuest: user.isAnonymous,
        isAdmin: isAdmin,
        name: name ?? user.displayName,
      );
}
