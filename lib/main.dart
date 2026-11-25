import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'models/user_session.dart';
import 'providers/audio_provider.dart';
import 'services/deathfish_audio_handler.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'theme/terminal_theme.dart';
import 'widgets/terminal_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<_BootstrapResult> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<_BootstrapResult> _initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await Supabase.initialize(
      url: 'https://zjiofnjhgfsrhawweaap.supabase.co',
      // ignore: deprecated_member_use
      anonKey: 'sb_publishable_GJyXaojc3cK2v1_SlY3mMA_ZA_vaXGO',
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    DeathfishAudioHandler? audioHandler;
    if (!kIsWeb &&
        {
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform)) {
      audioHandler = await AudioService.init(
        builder: DeathfishAudioHandler.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.deathfish.terminal.audio',
          androidNotificationChannelName: 'DEATHFISH AUDIO',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
    }
    return _BootstrapResult(audioHandler);
  }

  void _retryInitialization() {
    setState(() => _initialization = _initialize());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_BootstrapResult>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MaterialApp(
          title: 'DEATHFISH',
          debugShowCheckedModeBanner: false,
          theme: TerminalTheme.dark,
          home: TerminalMessageScreen(
            message: 'ERROR AL INICIAR SERVICIOS',
            detail: snapshot.error.toString(),
            actionLabel: 'REINTENTAR',
            onAction: _retryInitialization,
          ),
        );
      }
      final result = snapshot.data;
      if (result == null) {
        return MaterialApp(
          title: 'DEATHFISH',
          debugShowCheckedModeBanner: false,
          theme: TerminalTheme.dark,
          home: const SplashScreen(),
        );
      }
      return DeathfishApp(audioHandler: result.audioHandler);
    },
  );
}

class _BootstrapResult {
  const _BootstrapResult(this.audioHandler);

  final DeathfishAudioHandler? audioHandler;
}

class DeathfishApp extends StatefulWidget {
  const DeathfishApp({
    super.key,
    this.authService,
    this.firestoreService,
    this.dataService,
    this.notificationService,
    this.audioHandler,
  });

  final AuthGateway? authService;
  final FirestoreGateway? firestoreService;
  final DataService? dataService;
  final NotificationService? notificationService;
  final DeathfishAudioHandler? audioHandler;

  @override
  State<DeathfishApp> createState() => _DeathfishAppState();
}

class _DeathfishAppState extends State<DeathfishApp> {
  late final AuthGateway _authService;
  late final FirestoreGateway _firestoreService;
  late Future<DataService> _startup;
  late final Future<void> _splashDuration;
  late final NotificationService? _notificationService;
  late final bool _ownsNotificationService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    _notificationService =
        widget.notificationService ??
        (widget.authService == null ? NotificationService() : null);
    _ownsNotificationService =
        widget.notificationService == null && widget.authService == null;
    _startup = _initialize();
    _splashDuration = Future<void>.delayed(const Duration(seconds: 2));
  }

  @override
  void dispose() {
    if (_ownsNotificationService) {
      unawaited(_notificationService?.dispose());
    }
    super.dispose();
  }

  Future<DataService> _initialize() async {
    final suppliedData = widget.dataService;
    if (suppliedData != null) return suppliedData;
    return DataService.load();
  }

  void _retryLoading() {
    setState(() => _startup = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioProvider(handler: widget.audioHandler),
      child: MaterialApp(
        title: 'DEATHFISH',
        debugShowCheckedModeBanner: false,
        theme: TerminalTheme.dark,
        home: FutureBuilder<DataService>(
          future: _startup,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return TerminalMessageScreen(
                message: 'ERROR AL INICIAR FIRESTORE',
                detail: snapshot.error.toString(),
                actionLabel: 'REINTENTAR',
                onAction: _retryLoading,
              );
            }
            if (!snapshot.hasData) return const SplashScreen();
            return FutureBuilder<void>(
              future: _splashDuration,
              builder: (context, splashSnapshot) {
                if (splashSnapshot.connectionState != ConnectionState.done) {
                  return const SplashScreen();
                }
                return _AppGate(
                  authService: _authService,
                  firestoreService: _firestoreService,
                  dataService: snapshot.data!,
                  notificationService: _notificationService,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate({
    required this.authService,
    required this.firestoreService,
    required this.dataService,
    required this.notificationService,
  });

  final AuthGateway authService;
  final FirestoreGateway firestoreService;
  final DataService dataService;
  final NotificationService? notificationService;

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  late Stream<UserSession?> _sessions;
  String? _seededAdminUid;
  Future<void>? _adminSeed;

  @override
  void initState() {
    super.initState();
    _sessions = widget.authService.sessionChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserSession?>(
      stream: _sessions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TerminalMessageScreen(
            message: 'ERROR AL VERIFICAR LA SESIÓN',
            detail: snapshot.error.toString(),
            actionLabel: 'REINTENTAR',
            onAction: () =>
                setState(() => _sessions = widget.authService.sessionChanges),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const TerminalMessageScreen(
            message: 'VERIFICANDO CREDENCIALES...',
            showProgress: true,
          );
        }
        final session = snapshot.data;
        if (session == null) {
          return LoginScreen(
            authService: widget.authService,
            bandInfo: widget.dataService.bandInfo,
          );
        }
        if (session.isAdmin) {
          if (_seededAdminUid != session.uid) {
            _seededAdminUid = session.uid;
            _adminSeed = widget.firestoreService.seedInitialDataIfEmpty();
          }
          return FutureBuilder<void>(
            future: _adminSeed,
            builder: (context, seedSnapshot) {
              if (seedSnapshot.hasError) {
                return TerminalMessageScreen(
                  message: 'ERROR AL INICIALIZAR CONTENIDO',
                  detail: seedSnapshot.error.toString(),
                  actionLabel: 'REINTENTAR',
                  onAction: () => setState(
                    () => _adminSeed = widget.firestoreService
                        .seedInitialDataIfEmpty(),
                  ),
                );
              }
              if (seedSnapshot.connectionState != ConnectionState.done) {
                return const TerminalMessageScreen(
                  message: 'SINCRONIZANDO CONTENIDO INICIAL...',
                  showProgress: true,
                );
              }
              return _appShell(session);
            },
          );
        }
        return _appShell(session);
      },
    );
  }

  Widget _appShell(UserSession session) {
    return AppShell(
      authService: widget.authService,
      firestoreService: widget.firestoreService,
      dataService: widget.dataService,
      session: session,
      notificationService: widget.notificationService,
    );
  }
}
