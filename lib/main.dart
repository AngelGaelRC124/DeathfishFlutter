import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'models/user_session.dart';
import 'providers/audio_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/firestore_service.dart';
import 'theme/terminal_theme.dart';
import 'widgets/terminal_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://zjiofnjhgfsrhawweaap.supabase.co',
    // ignore: deprecated_member_use
    anonKey: 'sb_publishable_GJyXaojc3cK2v1_SlY3mMA_ZA_vaXGO',
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const DeathfishApp());
}

class DeathfishApp extends StatefulWidget {
  const DeathfishApp({
    super.key,
    this.authService,
    this.firestoreService,
    this.dataService,
  });

  final AuthGateway? authService;
  final FirestoreGateway? firestoreService;
  final DataService? dataService;

  @override
  State<DeathfishApp> createState() => _DeathfishAppState();
}

class _DeathfishAppState extends State<DeathfishApp> {
  late final AuthGateway _authService;
  late final FirestoreGateway _firestoreService;
  late Future<DataService> _startup;
  late final Future<void> _splashDuration;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    _startup = _initialize();
    _splashDuration = Future<void>.delayed(const Duration(seconds: 2));
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
      create: (_) => AudioProvider(),
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
  });

  final AuthGateway authService;
  final FirestoreGateway firestoreService;
  final DataService dataService;

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
    );
  }
}
