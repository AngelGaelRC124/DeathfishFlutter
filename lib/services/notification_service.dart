import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final StreamController<Object> _errors = StreamController<Object>.broadcast();
  StreamSubscription<String>? _tokenSubscription;
  String? _activeUid;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;
  Stream<Object> get errors => _errors.stream;

  Future<List<String>> initializeForUser(String uid) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'El usuario no puede estar vacío.');
    }
    if (_activeUid == uid) return const [];
    await _tokenSubscription?.cancel();
    _activeUid = uid;
    final warnings = <String>[];

    try {
      NotificationSettings? settings;
      try {
        settings = await _messaging.requestPermission();
      } catch (error, stackTrace) {
        if (!kIsWeb) Error.throwWithStackTrace(error, stackTrace);
        warnings.add('PERMISO WEB DE NOTIFICACIONES NO DISPONIBLE.');
      }
      if (settings?.authorizationStatus == AuthorizationStatus.denied) {
        warnings.add(
          'NOTIFICACIONES DESACTIVADAS EN LOS PERMISOS DEL NAVEGADOR.',
        );
      }

      if (!kIsWeb) {
        try {
          await _messaging.subscribeToTopic('deathfish_all');
        } catch (error, stackTrace) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      }

      String? token;
      try {
        // Keep saving the FCM token while Firebase's API transitions to FID registration.
        // ignore: deprecated_member_use
        token = await _messaging.getToken();
      } catch (error, stackTrace) {
        if (!kIsWeb) Error.throwWithStackTrace(error, stackTrace);
        warnings.add('TOKEN WEB NO DISPONIBLE; REVISA VAPID / SERVICE WORKER.');
      }
      if (token != null && token.isNotEmpty) {
        try {
          await _storeToken(uid, token);
        } catch (error, stackTrace) {
          if (!kIsWeb) Error.throwWithStackTrace(error, stackTrace);
          warnings.add(
            'TOKEN WEB NO GUARDADO; REVISA LAS REGLAS DE FIRESTORE.',
          );
        }
      } else {
        warnings.add('FIREBASE MESSAGING NO DEVOLVIÓ UN TOKEN FCM.');
      }

      // ignore: deprecated_member_use
      _tokenSubscription = _messaging.onTokenRefresh.listen((nextToken) {
        unawaited(
          _storeToken(uid, nextToken).catchError((
            Object error,
            StackTrace stack,
          ) {
            _errors.add(error);
          }),
        );
      }, onError: _errors.add);
      return warnings;
    } catch (error, stackTrace) {
      _activeUid = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> stopForUser(String uid) async {
    if (_activeUid != uid) return;
    _activeUid = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  Future<void> _storeToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _errors.close();
  }
}
