import 'package:flutter/material.dart';

import '../models/feed_item.dart';
import '../models/user_session.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({
    super.key,
    required this.dataService,
    required this.firestoreService,
    required this.session,
  });

  final DataService dataService;
  final FirestoreGateway firestoreService;
  final UserSession session;

  @override
  Widget build(BuildContext context) {
    final band = dataService.bandInfo;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TerminalPanel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRect(
                child: Image.asset(
                  'assets/deathfish-banner.JPG',
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 110,
                    child: Center(
                      child: Icon(
                        Icons.waves,
                        color: TerminalTheme.red,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${band.name} // ${band.label}',
                      style: const TextStyle(
                        color: TerminalTheme.red,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'RUIDO, MEMORIA Y TRANSMISIONES DESDE EL FONDO.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: TerminalTheme.red.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: TerminalTheme.red, size: 9),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'SEÑAL DE LA BANDA: ACTIVA // LA PECERA',
                              style: TextStyle(
                                color: TerminalTheme.red,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '> COMUNICADOS RECIENTES',
          style: TextStyle(
            color: TerminalTheme.red,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<FeedItem>>(
          stream: firestoreService.watchFeed(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return TerminalPanel(
                child: Text(
                  'ERROR AL CARGAR COMUNICADOS: ${snapshot.error}',
                  style: const TextStyle(color: TerminalTheme.red),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: TerminalTheme.red),
              );
            }
            final feed = snapshot.data!;
            if (feed.isEmpty) {
              return const TerminalPanel(
                child: Text('NO HAY COMUNICADOS DISPONIBLES.'),
              );
            }
            return Column(
              children: [
                for (final item in feed) ...[
                  TerminalPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.tag,
                                style: const TextStyle(
                                  color: TerminalTheme.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              item.date,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '// ${item.location}',
                          style: const TextStyle(
                            color: TerminalTheme.red,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AttendanceButton(
                          item: item,
                          session: session,
                          firestoreService: firestoreService,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  const _AttendanceButton({
    required this.item,
    required this.session,
    required this.firestoreService,
  });

  final FeedItem item;
  final UserSession session;
  final FirestoreGateway firestoreService;

  @override
  Widget build(BuildContext context) {
    final isAttending = item.attendeeIds.contains(session.uid);
    final count = item.attendeeIds.length;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          if (session.isGuest) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'INICIA SESIÓN COMO FAN PARA CONFIRMAR ASISTENCIA.',
                ),
                backgroundColor: TerminalTheme.red,
              ),
            );
            return;
          }
          try {
            await firestoreService.setEventAttendance(
              item.id,
              session.uid,
              !isAttending,
            );
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('NO SE PUDO ACTUALIZAR LA ASISTENCIA: $error'),
                  backgroundColor: TerminalTheme.red,
                ),
              );
            }
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: isAttending ? Colors.white : TerminalTheme.red,
          backgroundColor: isAttending ? TerminalTheme.red : Colors.black,
          side: const BorderSide(color: TerminalTheme.red, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(vertical: 11),
        ),
        child: Text(
          isAttending
              ? '[ ASISTENCIA CONFIRMADA ✓ ($count) ]'
              : '[ ASISTIRÉ ($count) ]',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
