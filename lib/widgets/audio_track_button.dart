import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../models/user_session.dart';
import '../providers/audio_provider.dart';
import '../services/data_service.dart';
import '../theme/terminal_theme.dart';

class AudioTrackButton extends StatelessWidget {
  const AudioTrackButton({
    super.key,
    required this.track,
    required this.dataService,
    required this.session,
    this.sourceUrl,
  });

  final Track track;
  final DataService dataService;
  final UserSession session;
  final String? sourceUrl;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final isCurrent = audio.currentTrack?.id == track.id;
    final restricted = track.soloFans && session.isGuest;
    final loading = isCurrent && audio.isLoading;
    final playing = isCurrent && audio.isPlaying;

    return IconButton(
      tooltip: restricted
          ? 'Acceso restringido a fans'
          : playing
          ? 'Pausar audio'
          : 'Reproducir audio',
      onPressed: loading
          ? null
          : () async {
              if (restricted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '[ ACCESO RESTRINGIDO // INICIA SESIÓN COMO FAN ]',
                    ),
                    backgroundColor: TerminalTheme.red,
                  ),
                );
                return;
              }
              try {
                await audio.toggleTrack(
                  track,
                  readLocalMedia: dataService.readMedia,
                  sourceUrl: sourceUrl,
                );
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('NO SE PUDO REPRODUCIR EL AUDIO: $error'),
                      backgroundColor: TerminalTheme.red,
                    ),
                  );
                }
              }
            },
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: TerminalTheme.red,
              ),
            )
          : Icon(
              restricted
                  ? Icons.lock_outline
                  : playing
                  ? Icons.pause
                  : Icons.play_arrow,
              color: TerminalTheme.red,
            ),
    );
  }
}
