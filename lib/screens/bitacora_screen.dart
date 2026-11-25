import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../models/voice_note.dart';
import '../providers/audio_provider.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class BitacoraScreen extends StatelessWidget {
  const BitacoraScreen({
    super.key,
    required this.gateway,
  });

  final VoiceNoteGateway? gateway;

  @override
  Widget build(BuildContext context) {
    final service = gateway;
    if (service == null) {
      return const Center(
        child: TerminalPanel(
          child: Text(
            'BITÁCORA // SERVICIO FIRESTORE NO DISPONIBLE',
            textAlign: TextAlign.center,
            style: TextStyle(color: TerminalTheme.red),
          ),
        ),
      );
    }
    return StreamBuilder<List<VoiceNote>>(
      stream: service.watchVoiceNotes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ERROR AL CARGAR BITÁCORA: ${snapshot.error}',
              style: const TextStyle(color: TerminalTheme.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: TerminalTheme.red),
          );
        }
        final notes = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '> CÁPSULAS DE VOZ // GRABACIONES DEL ESTUDIO',
              style: TextStyle(
                color: TerminalTheme.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (notes.isEmpty)
              const TerminalPanel(
                child: Text(
                  'NO HAY CÁPSULAS DE VOZ DISPONIBLES.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final note in notes) ...[
              _VoiceNoteRow(note: note),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _VoiceNoteRow extends StatelessWidget {
  const _VoiceNoteRow({required this.note});

  final VoiceNote note;

  @override
  Widget build(BuildContext context) => TerminalPanel(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    child: Row(
      children: [
        const Icon(Icons.graphic_eq, color: TerminalTheme.red, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                '${note.author} // ${note.duration}s',
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Reproducir cápsula de voz',
          onPressed: () async {
            try {
              await context.read<AudioProvider>().toggleTrack(
                Track(
                  id: 'voice_${note.id}',
                  number: 'VOZ',
                  title: note.title,
                  album: 'BITÁCORA // ${note.author}',
                  duration: '${note.duration}s',
                  lyrics: '',
                  youtubeUrl: '',
                  audioUrl: note.audioUrl,
                ),
                readLocalMedia: (_) async => null,
              );
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('NO SE PUDO REPRODUCIR LA CÁPSULA: $error'),
                    backgroundColor: TerminalTheme.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.play_arrow, color: TerminalTheme.red),
        ),
      ],
    ),
  );
}
