import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/track.dart';
import '../models/photo_archive_item.dart';
import '../models/user_session.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/audio_track_button.dart';
import '../widgets/terminal_widgets.dart';

class StreamScreen extends StatelessWidget {
  const StreamScreen({
    super.key,
    required this.dataService,
    required this.firestoreService,
    required this.session,
  });

  final DataService dataService;
  final FirestoreGateway firestoreService;
  final UserSession session;

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
                key: ValueKey('${track.id}:${track.videoUrl}'),
                track: track,
                dataService: dataService,
                session: session,
                onPlay: () => _launchVideo(context, track),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            const TerminalPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '> PRÓXIMAMENTE // COMUNIDAD',
                    style: TextStyle(
                      color: TerminalTheme.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'MURO // CÓDIGOS DE LA PECERA',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '> CARRETE // CONTACT SHEET',
              style: TextStyle(
                color: TerminalTheme.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 9),
            _PhotoArchiveSection(
              gateway: firestoreService is PhaseThreeGateway
                  ? firestoreService as PhaseThreeGateway
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _PhotoArchiveSection extends StatelessWidget {
  const _PhotoArchiveSection({required this.gateway});

  final PhaseThreeGateway? gateway;

  @override
  Widget build(BuildContext context) {
    final service = gateway;
    if (service == null) {
      return const TerminalPanel(
        child: Text(
          'CARRETE // SERVICIO FIRESTORE NO DISPONIBLE',
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      );
    }
    return StreamBuilder<List<PhotoArchiveItem>>(
      stream: service.watchPhotoArchive(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TerminalPanel(
            child: Text(
              'ERROR AL REVELAR FOTOGRAFÍAS: ${snapshot.error}',
              style: const TextStyle(color: TerminalTheme.red, fontSize: 10),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 110,
            child: Center(
              child: CircularProgressIndicator(color: TerminalTheme.red),
            ),
          );
        }
        final photos = snapshot.data!;
        if (photos.isEmpty) {
          return const TerminalPanel(
            child: Text(
              'CARRETE VACÍO // NO HAY NEGATIVOS',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemBuilder: (context, index) {
            final item = photos[index];
            return InkWell(
              onTap: () => _showPhoto(context, item),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF222222),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPhoto(
    BuildContext context,
    PhotoArchiveItem item,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close, color: TerminalTheme.red),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Text(
                        'ERROR AL REVELAR NEGATIVO',
                        style: TextStyle(color: TerminalTheme.red),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      item.caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (item.eventDate != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '> ${item.eventDate!.toLocal().toString().split(' ').first}',
                        style: const TextStyle(
                          color: TerminalTheme.red,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    super.key,
    required this.track,
    required this.dataService,
    required this.session,
    required this.onPlay,
  });

  final Track track;
  final DataService dataService;
  final UserSession session;
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
          if (track.videoUrl != null) ...[
            const Divider(height: 18),
            _InlineVideoPlayer(url: track.videoUrl!, name: track.videoName),
          ],
          if (track.audioMediaId != null || track.audioUrl != null) ...[
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
                    track.audioName ?? 'AUDIO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                AudioTrackButton(
                  dataService: dataService,
                  session: session,
                  track: track,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.url, this.name});

  final String url;
  final String? name;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialization = _controller.initialize();
    _controller.addListener(_onVideoChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoChanged);
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onVideoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: TerminalTheme.red.withValues(alpha: 0.4)),
      ),
      child: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'ERROR AL CARGAR VIDEO: ${snapshot.error}',
                style: const TextStyle(color: TerminalTheme.red, fontSize: 10),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: TerminalTheme.red),
              ),
            );
          }
          final aspectRatio = _controller.value.aspectRatio;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.name != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.name!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              AspectRatio(
                aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
                child: VideoPlayer(_controller),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: _controller.value.isPlaying
                        ? 'Pausar video'
                        : 'Reproducir video',
                    onPressed: () => _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play(),
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: TerminalTheme.red,
                    ),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: TerminalTheme.red,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
