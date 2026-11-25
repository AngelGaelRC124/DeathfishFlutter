import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../models/track.dart';
import '../theme/terminal_theme.dart';

class TrackStoryShareDialog extends StatefulWidget {
  const TrackStoryShareDialog({super.key, required this.track});

  final Track track;

  @override
  State<TrackStoryShareDialog> createState() => _TrackStoryShareDialogState();
}

class _TrackStoryShareDialogState extends State<TrackStoryShareDialog> {
  final GlobalKey _storyBoundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    ui.Image? image;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = _storyBoundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('No se pudo preparar la tarjeta de Story.');
      }
      image = await renderObject.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw StateError('No se pudo codificar la tarjeta como PNG.');
      }
      final bytes = png.buffer.asUint8List();
      final fileName = 'deathfish_${widget.track.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}.png';
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        text: '${widget.track.title} // DEATHFISH',
        fileNameOverrides: [fileName],
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO COMPARTIR LA STORY: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    } finally {
      image?.dispose();
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.68;
    final storyHeight = maxHeight.clamp(250.0, 560.0).toDouble();
    final storyWidth = storyHeight * 9 / 16;
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(14),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _storyBoundaryKey,
              child: SizedBox(
                width: storyWidth,
                height: storyHeight,
                child: _TrackStoryCard(track: widget.track),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSharing
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      'CERRAR',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSharing ? null : _share,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: TerminalTheme.red,
                      side: const BorderSide(color: TerminalTheme.red),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(_isSharing ? 'PREPARANDO...' : '[ COMPARTIR ]'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackStoryCard extends StatelessWidget {
  const _TrackStoryCard({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.black,
      border: Border.all(color: TerminalTheme.red, width: 3),
    ),
    padding: const EdgeInsets.all(14),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DEATHFISH // LA PECERA RECORDS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TerminalTheme.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF080808),
                  border: Border.all(color: TerminalTheme.red, width: 1),
                ),
                padding: const EdgeInsets.all(8),
                child: track.artUrl?.isNotEmpty ?? false
                    ? Image.network(
                        track.artUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : Image.asset(
                                'assets/logooficial.png',
                                fit: BoxFit.contain,
                              ),
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/logooficial.png',
                              fit: BoxFit.contain,
                            ),
                      )
                    : Image.asset(
                        'assets/logooficial.png',
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              track.title.toUpperCase(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.08,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${track.album} // ${track.duration}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
            const Spacer(),
            const Text(
              'ESCUCHA EN LA APP OFICIAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TerminalTheme.red,
                fontSize: 9,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
