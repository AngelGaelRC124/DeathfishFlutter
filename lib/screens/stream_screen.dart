import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/track.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class StreamScreen extends StatelessWidget {
  const StreamScreen({
    super.key,
    required this.dataService,
    required this.firestoreService,
  });

  final DataService dataService;
  final FirestoreGateway firestoreService;

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
    return StreamBuilder<List<Track>>(
      stream: firestoreService.watchTracks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ERROR AL CARGAR LANZAMIENTOS: ${snapshot.error}',
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
        final tracks = snapshot.data!;
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
                  border: Border.all(
                    color: TerminalTheme.red.withValues(alpha: 0.45),
                  ),
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
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
                dataService: dataService,
                onPlay: () => _launchVideo(context, track),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    required this.track,
    required this.dataService,
    required this.onPlay,
  });

  final Track track;
  final DataService dataService;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return TerminalPanel(
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: TerminalTheme.red.withValues(alpha: 0.4),
                  ),
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
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
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
                onPressed: track.youtubeUrl.trim().isEmpty ? null : onPlay,
                icon: const Icon(Icons.play_arrow, color: TerminalTheme.red),
              ),
            ],
          ),
          if (track.audioMediaId != null) ...[
            const Divider(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.audio_file_outlined,
                  color: TerminalTheme.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    track.audioName ?? 'AUDIO LOCAL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                _AudioPlaybackButton(dataService: dataService, track: track),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AudioPlaybackButton extends StatefulWidget {
  const _AudioPlaybackButton({required this.dataService, required this.track});

  final DataService dataService;
  final Track track;

  @override
  State<_AudioPlaybackButton> createState() => _AudioPlaybackButtonState();
}

class _AudioPlaybackButtonState extends State<_AudioPlaybackButton> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSubscription;
  PlayerState _playerState = PlayerState.stopped;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    setState(() => _isLoading = true);
    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else if (_playerState == PlayerState.paused) {
        await _player.resume();
      } else {
        final mediaId = widget.track.audioMediaId;
        if (mediaId == null) {
          throw StateError('Esta canción no tiene audio adjunto.');
        }
        final bytes = await widget.dataService.readMedia(mediaId);
        if (bytes == null) {
          throw StateError('No se encontró el archivo de audio guardado.');
        }
        await _player.play(
          BytesSource(bytes, mimeType: widget.track.audioMimeType),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NO SE PUDO REPRODUCIR EL AUDIO: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _playerState == PlayerState.playing
          ? 'Pausar audio'
          : 'Reproducir audio',
      onPressed: _isLoading ? null : _togglePlayback,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: TerminalTheme.red,
              ),
            )
          : Icon(
              _playerState == PlayerState.playing
                  ? Icons.pause
                  : Icons.play_arrow,
              color: TerminalTheme.red,
            ),
    );
  }
}
