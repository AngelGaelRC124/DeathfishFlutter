import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/user_session.dart';
import '../providers/audio_provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';
import '../widgets/global_audio_bar.dart';
import 'admin_screen.dart';
import 'archivo_screen.dart';
import 'contacto_screen.dart';
import 'inicio_screen.dart';
import 'merch_screen.dart';
import 'stream_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.dataService,
    required this.session,
  });

  final AuthGateway authService;
  final FirestoreGateway firestoreService;
  final DataService dataService;
  final UserSession session;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _showAdmin = false;

  Future<void> _showFanPass() async {
    final session = widget.session;
    final passData = jsonEncode({'uid': session.uid, 'email': session.email});
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          '> CREDENCIAL / PASE TERMINAL',
          style: TextStyle(
            color: TerminalTheme.red,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: TerminalTheme.red, width: 1),
                ),
                child: QrImageView(
                  data: passData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.black,
                  eyeStyle: const QrEyeStyle(color: Colors.white),
                  dataModuleStyle: const QrDataModuleStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                (session.name?.trim().isNotEmpty ?? false)
                    ? session.name!
                    : session.email.split('@').first,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                session.isAdmin ? 'ROL // ADMIN' : 'ROL // FAN',
                style: const TextStyle(color: TerminalTheme.red, fontSize: 11),
              ),
              const SizedBox(height: 5),
              SelectableText(
                session.email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'CERRAR',
              style: TextStyle(color: TerminalTheme.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.isAdmin && !widget.session.isAdmin) {
      _showAdmin = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.dataService;
    final pages = [
      InicioScreen(
        dataService: data,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
      MerchScreen(dataService: data, firestoreService: widget.firestoreService),
      ArchivoScreen(
        dataService: data,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
      StreamScreen(
        dataService: data,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
      ContactoScreen(
        dataService: data,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
    ];

    return Scaffold(
      body: TerminalBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  border: Border(
                    bottom: BorderSide(
                      color: TerminalTheme.red.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (_showAdmin)
                      IconButton(
                        tooltip: 'Volver a la app',
                        onPressed: () => setState(() => _showAdmin = false),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: TerminalTheme.red,
                        ),
                      )
                    else
                      const SizedBox(width: 42),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            data.bandInfo.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _showAdmin
                                ? 'MODO ADMINISTRADOR // ${data.bandInfo.label}'
                                : widget.session.isAdmin
                                ? 'ADMINISTRADOR // ${data.bandInfo.label}'
                                : widget.session.isGuest
                                ? 'ACCESO INVITADO // ${data.bandInfo.label}'
                                : data.bandInfo.label,
                            style: const TextStyle(
                              color: TerminalTheme.red,
                              fontSize: 9,
                              letterSpacing: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (widget.session.isAdmin && !_showAdmin)
                      IconButton(
                        tooltip: 'Panel de administrador',
                        onPressed: () => setState(() => _showAdmin = true),
                        icon: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: TerminalTheme.red,
                        ),
                      ),
                    if (!widget.session.isGuest)
                      IconButton(
                        tooltip: 'Credencial de fan',
                        onPressed: _showFanPass,
                        icon: const Icon(
                          Icons.person_outline,
                          color: TerminalTheme.red,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      onPressed: () async {
                        try {
                          await widget.authService.signOut();
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ERROR AL CERRAR SESIÓN: $error'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: TerminalTheme.red),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _showAdmin
                    ? AdminScreen(
                        dataService: data,
                        firestoreService: widget.firestoreService,
                        session: widget.session,
                      )
                    : IndexedStack(index: _selectedIndex, children: pages),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(
                  '© ${data.bandInfo.year} ${data.bandInfo.name} - ${data.bandInfo.label}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer<AudioProvider>(
        builder: (context, audio, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (audio.currentTrack != null) const GlobalAudioBar(),
            if (_showAdmin)
              BottomAppBar(
                color: Colors.black,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAdmin = false),
                  icon: const Icon(Icons.arrow_back, color: TerminalTheme.red),
                  label: const Text(
                    'VOLVER A LA PECERA',
                    style: TextStyle(color: TerminalTheme.red),
                  ),
                ),
              )
            else
              BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                selectedFontSize: 9,
                unselectedFontSize: 8,
                iconSize: 18,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'INICIO',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_bag_outlined),
                    label: 'MERCH',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_music_outlined),
                    label: 'ARCHIVO',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.play_circle_outline),
                    label: 'STREAM',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.mail_outline),
                    label: 'CONTACTO',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
