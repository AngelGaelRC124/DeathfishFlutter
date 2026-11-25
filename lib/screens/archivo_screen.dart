import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../models/user_session.dart';
import '../providers/audio_provider.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../services/track_zine_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/audio_track_button.dart';
import '../widgets/offline_track_button.dart';
import '../widgets/terminal_widgets.dart';
import '../widgets/track_story_share_dialog.dart';
import '../widgets/timed_comments_panel.dart';

class ArchivoScreen extends StatefulWidget {
  const ArchivoScreen({
    super.key,
    required this.dataService,
    required this.firestoreService,
    required this.session,
  });

  final DataService dataService;
  final FirestoreGateway firestoreService;
  final UserSession session;

  @override
  State<ArchivoScreen> createState() => _ArchivoScreenState();
}

class _ArchivoScreenState extends State<ArchivoScreen> {
  bool _favoritesOnly = false;
  late final Stream<Set<String>> _favorites;
  final TrackZineService _zineService = TrackZineService();

  PhaseThreeGateway? get _phaseThreeGateway =>
      widget.firestoreService is PhaseThreeGateway
      ? widget.firestoreService as PhaseThreeGateway
      : null;

  @override
  void initState() {
    super.initState();
    _favorites =
        (widget.session.isGuest
                ? Stream.value(<String>{})
                : widget.firestoreService.watchFavoriteIds(widget.session.uid))
            .asBroadcastStream();
  }

  Future<void> _openLyrics(Track track) async {
    var showingArt = false;
    var selectedVersion = 'MASTER';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => StreamBuilder<Set<String>>(
          stream: _favorites,
          builder: (context, favoriteSnapshot) {
            final favorites = favoriteSnapshot.data ?? const <String>{};
            final isFavorite = favorites.contains(track.id);
            final availableVersions = <(String, String?)>[
              if (track.audioUrl != null || track.audioMediaId != null)
                ('MASTER', track.audioUrl),
              if (track.demoUrl?.isNotEmpty ?? false) ('DEMO', track.demoUrl),
              if (track.rehearsalUrl?.isNotEmpty ?? false)
                ('ENSAYO', track.rehearsalUrl),
            ];
            final hasAudio = availableVersions.isNotEmpty;
            final activeVersion =
                availableVersions.any(
                  (version) => version.$1 == selectedVersion,
                )
                ? selectedVersion
                : availableVersions.firstOrNull?.$1 ?? selectedVersion;
            final restricted = track.soloFans && widget.session.isGuest;
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.82,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'ARCHIVO // ${track.number}',
                              style: const TextStyle(
                                color: TerminalTheme.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: widget.session.isGuest
                                ? 'Inicia sesión para guardar favoritos'
                                : isFavorite
                                ? 'Quitar de favoritos'
                                : 'Guardar en favoritos',
                            onPressed: widget.session.isGuest
                                ? null
                                : () async {
                                    try {
                                      await widget.firestoreService.setFavorite(
                                        widget.session.uid,
                                        track.id,
                                        !isFavorite,
                                      );
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'NO SE PUDO GUARDAR FAVORITO: $error',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: TerminalTheme.red,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      Text(
                        track.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${track.album} // ${track.duration}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      if (hasAudio)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (availableVersions.length > 1)
                              Wrap(
                                spacing: 6,
                                children: [
                                  for (final version in availableVersions)
                                    _DetailTab(
                                      label: '[ ${version.$1} ]',
                                      selected: activeVersion == version.$1,
                                      onTap: () => _selectVersion(
                                        context,
                                        track,
                                        version.$1,
                                        version.$2,
                                        setSheetState,
                                        () => selectedVersion = version.$1,
                                      ),
                                    ),
                                ],
                              ),
                            Row(
                              children: [
                                AudioTrackButton(
                                  key: ValueKey('${track.id}-$activeVersion'),
                                  track: track,
                                  dataService: widget.dataService,
                                  session: widget.session,
                                  sourceUrl: availableVersions
                                      .firstWhere(
                                        (entry) => entry.$1 == activeVersion,
                                      )
                                      .$2,
                                ),
                                const Text(
                                  'REPRODUCIR AUDIO',
                                  style: TextStyle(
                                    color: TerminalTheme.red,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (restricted)
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            '[ ACCESO RESTRINGIDO // INICIA SESIÓN COMO FAN ]',
                            style: TextStyle(
                              color: TerminalTheme.red,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => TrackStoryShareDialog(track: track),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TerminalTheme.red,
                            side: const BorderSide(color: TerminalTheme.red),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: const Text('[ COMPARTIR STORY ]'),
                        ),
                      ),
                      const SizedBox(height: 7),
                      if (track.audioUrl?.isNotEmpty ?? false)
                        OfflineTrackButton(
                          track: track,
                          dataService: widget.dataService,
                          session: widget.session,
                        ),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _exportZine(context, track),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TerminalTheme.red,
                            side: const BorderSide(color: TerminalTheme.red),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: const Text('[ EXPORTAR ZINE PDF ]'),
                        ),
                      ),
                      if (_phaseThreeGateway case final gateway?)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: TimedCommentsPanel(
                            track: track,
                            gateway: gateway,
                            session: widget.session,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailTab(
                              label: '[ LETRAS ]',
                              selected: !showingArt,
                              onTap: () =>
                                  setSheetState(() => showingArt = false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DetailTab(
                              label: '[ ARTE / ZINE ]',
                              selected: showingArt,
                              onTap: () =>
                                  setSheetState(() => showingArt = true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: TerminalTheme.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: showingArt
                              ? track.artUrl == null
                                    ? const Center(
                                        child: Text(
                                          'NO HAY ARTE DISPONIBLE.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      )
                                    : Image.network(
                                        track.artUrl!,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (
                                              context,
                                              child,
                                              progress,
                                            ) => progress == null
                                            ? child
                                            : const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: TerminalTheme.red,
                                                    ),
                                              ),
                                        errorBuilder: (context, error, stack) =>
                                            const Center(
                                              child: Text(
                                                'ERROR AL CARGAR EL ARTE.',
                                                style: TextStyle(
                                                  color: TerminalTheme.red,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                      )
                              : SingleChildScrollView(
                                  child: SelectableText(
                                    track.lyrics,
                                    style: const TextStyle(height: 1.8),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.session.isGuest
                            ? 'INICIA SESIÓN PARA SINCRONIZAR FAVORITOS'
                            : 'FAVORITOS SINCRONIZADOS CON TU CUENTA',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportZine(BuildContext context, Track track) async {
    try {
      final bytes = await _zineService.build(track);
      if (!context.mounted) return;
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename:
            'deathfish-${track.number}-${track.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}.pdf',
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO EXPORTAR EL ZINE: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    }
  }

  Future<void> _selectVersion(
    BuildContext context,
    Track track,
    String version,
    String? sourceUrl,
    void Function(void Function()) setSheetState,
    VoidCallback updateSelection,
  ) async {
    setSheetState(updateSelection);
    final audio = context.read<AudioProvider>();
    if (audio.currentTrack?.id != track.id || !audio.isPlaying) return;
    try {
      await audio.playTrack(
        track,
        readLocalMedia: widget.dataService.readMedia,
        sourceUrl: sourceUrl,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO CAMBIAR LA MEZCLA: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Track>>(
      stream: widget.firestoreService.watchTracks(),
      builder: (context, trackSnapshot) {
        if (trackSnapshot.hasError) {
          return Center(
            child: Text(
              'ERROR AL CARGAR EL ARCHIVO: ${trackSnapshot.error}',
              style: const TextStyle(color: TerminalTheme.red),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!trackSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: TerminalTheme.red),
          );
        }
        return StreamBuilder<Set<String>>(
          stream: _favorites,
          builder: (context, favoriteSnapshot) {
            if (favoriteSnapshot.hasError) {
              return Center(
                child: Text(
                  'ERROR AL CARGAR FAVORITOS: ${favoriteSnapshot.error}',
                  style: const TextStyle(color: TerminalTheme.red),
                ),
              );
            }
            final favorites = favoriteSnapshot.data ?? const <String>{};
            final tracks = trackSnapshot.data!
                .where(
                  (track) => !_favoritesOnly || favorites.contains(track.id),
                )
                .toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '> ARCHIVO DE AUDIO',
                        style: TextStyle(
                          color: TerminalTheme.red,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                    FilterChip(
                      selected: _favoritesOnly,
                      label: Text(_favoritesOnly ? 'FAVORITOS' : 'TODOS'),
                      onSelected: (value) =>
                          setState(() => _favoritesOnly = value),
                      selectedColor: TerminalTheme.red.withValues(alpha: 0.3),
                      checkmarkColor: TerminalTheme.red,
                      side: BorderSide(
                        color: TerminalTheme.red.withValues(alpha: 0.35),
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tracks.isEmpty)
                  TerminalPanel(
                    child: Text(
                      _favoritesOnly
                          ? 'NO HAY CANCIONES FAVORITAS GUARDADAS.'
                          : 'NO HAY CANCIONES DISPONIBLES.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                for (final track in tracks) ...[
                  _TrackRow(
                    track: track,
                    isFavorite: favorites.contains(track.id),
                    onTap: () => _openLyrics(track),
                    dataService: widget.dataService,
                    session: widget.session,
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _TrackRow extends StatefulWidget {
  const _TrackRow({
    required this.track,
    required this.isFavorite,
    required this.onTap,
    required this.dataService,
    required this.session,
  });

  final Track track;
  final bool isFavorite;
  final VoidCallback onTap;
  final DataService dataService;
  final UserSession session;

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  Timer? _countdown;
  DateTime _now = DateTime.now();

  bool get _locked => widget.track.releaseDate?.isAfter(_now) ?? false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant _TrackRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.releaseDate != widget.track.releaseDate) {
      _countdown?.cancel();
      _startCountdown();
    }
  }

  void _startCountdown() {
    if (widget.track.releaseDate?.isAfter(_now) ?? false) {
      _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
        if (!_locked) _countdown?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      onTap: _locked ? null : widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.88),
          border: _locked
              ? null
              : Border.all(color: const Color(0xFF222222), width: 1),
        ),
        child: Row(
          children: [
            Text(
              widget.track.number,
              style: TextStyle(
                color: _locked ? Colors.white54 : TerminalTheme.red,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.track.title,
                    style: TextStyle(
                      color: _locked ? Colors.white70 : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.track.album} // ${widget.track.duration}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  if (_locked) ...[
                    const SizedBox(height: 5),
                    Text(
                      '> SE DESENCRIPTA EN: ${_remaining(widget.track.releaseDate!)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.isFavorite && !_locked)
              const Icon(Icons.favorite, color: TerminalTheme.red, size: 17),
            if (_locked)
              const Icon(Icons.lock_outline, color: Colors.white54, size: 17)
            else if (widget.track.audioUrl?.isNotEmpty ?? false)
              OfflineTrackButton(
                track: widget.track,
                dataService: widget.dataService,
                session: widget.session,
              )
            else if (!widget.isFavorite)
              const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
    if (!_locked) return child;
    return CustomPaint(foregroundPainter: _DashedBorderPainter(), child: child);
  }

  String _remaining(DateTime date) {
    final seconds = date.difference(_now).inSeconds.clamp(0, 0x7fffffff);
    final days = seconds ~/ Duration.secondsPerDay;
    final hours = (seconds ~/ Duration.secondsPerHour) % 24;
    final minutes = (seconds ~/ Duration.secondsPerMinute) % 60;
    final remainder = seconds % 60;
    return '${days.toString().padLeft(2, '0')}d '
        '${hours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m '
        '${remainder.toString().padLeft(2, '0')}s';
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 4.0;
    final path = Path();
    for (var x = 0.0; x < size.width; x += dash + gap) {
      path
        ..moveTo(x, 0)
        ..lineTo((x + dash).clamp(0, size.width), 0)
        ..moveTo(x, size.height)
        ..lineTo((x + dash).clamp(0, size.width), size.height);
    }
    for (var y = 0.0; y < size.height; y += dash + gap) {
      path
        ..moveTo(0, y)
        ..lineTo(0, (y + dash).clamp(0, size.height))
        ..moveTo(size.width, y)
        ..lineTo(size.width, (y + dash).clamp(0, size.height));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: selected ? Colors.black : TerminalTheme.red,
      backgroundColor: selected ? TerminalTheme.red : Colors.black,
      side: const BorderSide(color: TerminalTheme.red, width: 1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(vertical: 10),
    ),
    child: Text(label, style: const TextStyle(fontSize: 10)),
  );
}
