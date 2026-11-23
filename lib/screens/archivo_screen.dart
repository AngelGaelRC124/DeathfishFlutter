import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/data_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class ArchivoScreen extends StatefulWidget {
  const ArchivoScreen({super.key, required this.dataService});

  final DataService dataService;

  @override
  State<ArchivoScreen> createState() => _ArchivoScreenState();
}

class _ArchivoScreenState extends State<ArchivoScreen> {
  bool _favoritesOnly = false;

  Future<void> _openLyrics(Track track) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) {
          final isFavorite = widget.dataService.favoriteIds.contains(track.id);
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
                          tooltip: isFavorite
                              ? 'Quitar de favoritos offline'
                              : 'Guardar en favoritos offline',
                          onPressed: () async {
                            try {
                              await widget.dataService.toggleFavorite(track.id);
                              if (context.mounted) updateSheet(() {});
                              if (mounted) setState(() {});
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                            isFavorite ? Icons.favorite : Icons.favorite_border,
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
                    const Divider(height: 28),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: TerminalTheme.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: SelectableText(
                            track.lyrics,
                            style: const TextStyle(height: 1.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isFavorite
                          ? 'FAVORITO GUARDADO EN ESTE DISPOSITIVO'
                          : 'MARCA COMO FAVORITO PARA ACCEDER OFFLINE',
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
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final favorites = widget.dataService.favoriteIds;
    final tracks = widget.dataService.tracks
        .where((track) => !_favoritesOnly || favorites.contains(track.id))
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
              onSelected: (value) => setState(() => _favoritesOnly = value),
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
          const TerminalPanel(
            child: Text(
              'NO HAY CANCIONES FAVORITAS GUARDADAS.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        for (final track in tracks) ...[
          _TrackRow(
            track: track,
            isFavorite: favorites.contains(track.id),
            onTap: () => _openLyrics(track),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.isFavorite,
    required this.onTap,
  });

  final Track track;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: TerminalPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Text(
              track.number,
              style: const TextStyle(color: TerminalTheme.red),
            ),
            const SizedBox(width: 14),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (isFavorite)
              const Icon(Icons.favorite, color: TerminalTheme.red, size: 17)
            else
              const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
