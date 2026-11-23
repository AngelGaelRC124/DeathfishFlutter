import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({
    super.key,
    required this.dataService,
    required this.firestoreService,
  });

  final DataService dataService;
  final FirestoreGateway firestoreService;

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
        StreamBuilder(
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
