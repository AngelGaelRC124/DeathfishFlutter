import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../models/user_session.dart';
import '../providers/audio_provider.dart';
import '../services/data_service.dart';
import '../theme/terminal_theme.dart';

class OfflineTrackButton extends StatefulWidget {
  const OfflineTrackButton({
    super.key,
    required this.track,
    required this.dataService,
    required this.session,
  });

  final Track track;
  final DataService dataService;
  final UserSession session;

  @override
  State<OfflineTrackButton> createState() => _OfflineTrackButtonState();
}

class _OfflineTrackButtonState extends State<OfflineTrackButton> {
  final DefaultCacheManager _cache = DefaultCacheManager();
  FileInfo? _cachedFile;
  double? _progress;
  bool _isChecking = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  Future<void> _checkCache() async {
    final url = widget.track.audioUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _isChecking = false);
      return;
    }
    try {
      final cached = await _cache.getFileFromCache(url);
      if (mounted) {
        setState(() {
          _cachedFile = cached;
          _isChecking = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO VERIFICAR LA CACHÉ OFFLINE: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    }
  }

  Future<void> _handleTap() async {
    final url = widget.track.audioUrl;
    if (url == null || url.isEmpty || _progress != null) return;
    if (widget.track.soloFans && widget.session.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ESTA PISTA ES EXCLUSIVA PARA FANS REGISTRADOS.'),
          backgroundColor: TerminalTheme.red,
        ),
      );
      return;
    }
    if (_cachedFile != null) {
      final audio = context.read<AudioProvider>();
      setState(() => _isPlaying = true);
      try {
        await audio.playTrack(
          widget.track,
          readLocalMedia: widget.dataService.readMedia,
          localFilePath: _cachedFile!.file.path,
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('NO SE PUDO REPRODUCIR EL ARCHIVO OFFLINE: $error'),
              backgroundColor: TerminalTheme.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isPlaying = false);
      }
      return;
    }
    setState(() => _progress = 0);
    try {
      await for (final event in _cache.getFileStream(url, withProgress: true)) {
        if (event is DownloadProgress) {
          if (mounted) setState(() => _progress = event.progress);
        } else if (event is FileInfo) {
          _cachedFile = event;
          if (mounted) setState(() => _progress = null);
        }
      }
      if (_cachedFile == null) {
        throw StateError('La descarga terminó sin guardar el archivo.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _progress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO GUARDAR OFFLINE: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.track.audioUrl?.isNotEmpty ?? false;
    final label = _progress != null
        ? '[ ↓ ${((_progress ?? 0) * 100).round()}% ]'
        : _isPlaying
        ? '[ REPRODUCIENDO ]'
        : _cachedFile != null
        ? '[ ✓ GUARDADO ]'
        : '[ ↓ OFFLINE ]';
    return OutlinedButton(
      onPressed: !hasUrl ||
              _isChecking ||
              _progress != null ||
              (widget.track.soloFans && widget.session.isGuest)
          ? null
          : _handleTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: TerminalTheme.red,
        side: const BorderSide(color: TerminalTheme.red),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 9),
      ),
      child: Text(_isChecking ? '[ ... ]' : label),
    );
  }
}
