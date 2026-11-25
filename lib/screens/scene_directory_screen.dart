import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/scene_entry.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class SceneDirectoryScreen extends StatelessWidget {
  const SceneDirectoryScreen({super.key, required this.gateway});

  final PhaseThreeGateway? gateway;

  @override
  Widget build(BuildContext context) {
    final service = gateway;
    if (service == null) {
      return const Center(
        child: Text(
          'ESCENA // SERVICIO FIRESTORE NO DISPONIBLE',
          style: TextStyle(color: TerminalTheme.red),
        ),
      );
    }
    return StreamBuilder<List<SceneEntry>>(
      stream: service.watchSceneDirectory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ERROR AL LEER LA ESCENA: ${snapshot.error}',
              style: const TextStyle(color: TerminalTheme.red),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: TerminalTheme.red),
          );
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return const Center(
            child: Text(
              'DIRECTORIO VACÍO // PRÓXIMAMENTE',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const Text(
              '> ESCENA // RED CONTEMPORÁNEA',
              style: TextStyle(
                color: TerminalTheme.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            for (final entry in entries) ...[
              _SceneCard(entry: entry),
              const SizedBox(height: 9),
            ],
          ],
        );
      },
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.entry});

  final SceneEntry entry;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(entry.externalUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        !{'http', 'https'}.contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EL ENLACE DE ESTA FICHA NO ES VÁLIDO.'),
          backgroundColor: TerminalTheme.red,
        ),
      );
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NO SE PUDO ABRIR EL ENLACE.'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR AL ABRIR EL ENLACE: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => TerminalPanel(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '[ ${entry.category.toUpperCase()} ] // ${entry.city.toUpperCase()}',
          style: const TextStyle(color: TerminalTheme.red, fontSize: 9),
        ),
        const SizedBox(height: 5),
        Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (entry.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            entry.description,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: () => _open(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: TerminalTheme.red,
              side: const BorderSide(color: TerminalTheme.red),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('[ ABRIR ENLACE ↗ ]'),
          ),
        ),
      ],
    ),
  );
}
