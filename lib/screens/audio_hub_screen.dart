import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import 'archivo_screen.dart';
import 'bitacora_screen.dart';
import 'radio_screen.dart';

class AudioHubScreen extends StatefulWidget {
  const AudioHubScreen({
    super.key,
    required this.dataService,
    required this.firestoreService,
    required this.session,
  });

  final DataService dataService;
  final FirestoreGateway firestoreService;
  final UserSession session;

  @override
  State<AudioHubScreen> createState() => AudioHubScreenState();
}

class AudioHubScreenState extends State<AudioHubScreen> {
  int _selectedTab = 0;

  void selectRadio() {
    if (_selectedTab != 1) setState(() => _selectedTab = 1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ArchivoScreen(
        dataService: widget.dataService,
        firestoreService: widget.firestoreService,
        session: widget.session,
      ),
      RadioScreen(
        gateway: widget.firestoreService is RadioGateway
            ? widget.firestoreService as RadioGateway
            : null,
        session: widget.session,
        isActive: _selectedTab == 1,
      ),
      BitacoraScreen(
        gateway: widget.firestoreService is VoiceNoteGateway
            ? widget.firestoreService as VoiceNoteGateway
            : null,
      ),
    ];
    return Column(
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              for (final entry in [
                (0, '[ TRACKS ]'),
                (1, '[ RADIO FM ]'),
                (2, '[ BITÁCORA ]'),
              ]) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectedTab = entry.$1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _selectedTab == entry.$1
                          ? Colors.black
                          : TerminalTheme.red,
                      backgroundColor: _selectedTab == entry.$1
                          ? TerminalTheme.red
                          : Colors.black,
                      side: const BorderSide(color: TerminalTheme.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(entry.$2),
                  ),
                ),
                if (entry.$1 < 2) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(index: _selectedTab, children: pages),
        ),
      ],
    );
  }
}
