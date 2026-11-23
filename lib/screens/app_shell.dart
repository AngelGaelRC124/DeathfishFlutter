import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/data_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';
import 'archivo_screen.dart';
import 'contacto_screen.dart';
import 'inicio_screen.dart';
import 'merch_screen.dart';
import 'stream_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.dataService,
    required this.session,
    required this.onLogout,
  });

  final DataService dataService;
  final UserSession session;
  final Future<void> Function() onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final data = widget.dataService;
    final pages = [
      InicioScreen(dataService: data),
      MerchScreen(dataService: data),
      ArchivoScreen(dataService: data),
      StreamScreen(dataService: data),
      ContactoScreen(dataService: data),
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
                            widget.session.isGuest
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
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      onPressed: () async {
                        try {
                          await widget.onLogout();
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
                child: IndexedStack(index: _selectedIndex, children: pages),
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
      bottomNavigationBar: BottomNavigationBar(
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
    );
  }
}
