import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/track.dart';
import '../services/data_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class StreamScreen extends StatelessWidget {
  const StreamScreen({super.key, required this.dataService});

  final DataService dataService;

  Future<void> _launchVideo(BuildContext context, Track track) async {
    try {
      final launched = await launchUrl(
        Uri.parse(track.youtubeUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NO SE PUDO ABRIR EL ENLACE DE YOUTUBE.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR AL ABRIR EL ENLACE: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracks = dataService.tracks;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '> STREAM / TRANSMISIONES',
          style: TextStyle(
            color: TerminalTheme.red,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        TerminalPanel(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: 175,
            decoration: BoxDecoration(
              color: const Color(0xFF07100A),
              border: Border.all(color: TerminalTheme.red.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: TerminalTheme.red.withValues(alpha: 0.12),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 0.22,
                  child: Image.asset(
                    'assets/live-pecera.JPG',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: TerminalTheme.red,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'SEÑAL CRT // LA PECERA',
                        style: TextStyle(
                          color: TerminalTheme.red,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'ESPERANDO TRANSMISIÓN',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '> LANZAMIENTOS Y VIDEOS',
          style: TextStyle(color: TerminalTheme.red, fontSize: 11),
        ),
        const SizedBox(height: 10),
        for (final track in tracks) ...[
          _ReleaseCard(
            track: track,
            onPlay: () => _launchVideo(context, track),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.track, required this.onPlay});

  final Track track;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return TerminalPanel(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: TerminalTheme.red.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.graphic_eq, color: TerminalTheme.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${track.album} // ${track.duration}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
                const SizedBox(height: 5),
                const Text(
                  'YOUTUBE // DEATHFISH',
                  style: TextStyle(color: TerminalTheme.red, fontSize: 9),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Abrir en YouTube',
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow, color: TerminalTheme.red),
          ),
        ],
      ),
    );
  }
}
