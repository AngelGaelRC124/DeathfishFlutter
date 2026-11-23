import 'package:flutter/material.dart';

import 'models/user_session.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/data_service.dart';
import 'theme/terminal_theme.dart';
import 'widgets/terminal_widgets.dart';

void main() {
  runApp(const DeathfishApp());
}

class DeathfishApp extends StatefulWidget {
  const DeathfishApp({super.key});

  @override
  State<DeathfishApp> createState() => _DeathfishAppState();
}

class _DeathfishAppState extends State<DeathfishApp> {
  late Future<DataService> _dataService;

  @override
  void initState() {
    super.initState();
    _dataService = DataService.load();
  }

  void _retryLoading() {
    setState(() {
      _dataService = DataService.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEATHFISH',
      debugShowCheckedModeBanner: false,
      theme: TerminalTheme.dark,
      home: FutureBuilder<DataService>(
        future: _dataService,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return TerminalMessageScreen(
              message: 'ERROR AL CARGAR LOS ARCHIVOS DE LA PECERA',
              detail: snapshot.error.toString(),
              actionLabel: 'REINTENTAR',
              onAction: _retryLoading,
            );
          }
          if (!snapshot.hasData) {
            return const TerminalMessageScreen(
              message: 'INICIANDO SISTEMA...',
              showProgress: true,
            );
          }
          return _AppGate(dataService: snapshot.data!);
        },
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate({required this.dataService});

  final DataService dataService;

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  UserSession? _session;

  @override
  void initState() {
    super.initState();
    _session = widget.dataService.session;
  }

  void _onAuthenticated(UserSession session) {
    setState(() => _session = session);
  }

  Future<void> _onLogout() async {
    await widget.dataService.logout();
    if (mounted) setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return LoginScreen(
        dataService: widget.dataService,
        onAuthenticated: _onAuthenticated,
      );
    }
    return AppShell(
      dataService: widget.dataService,
      session: session,
      onLogout: _onLogout,
    );
  }
}
