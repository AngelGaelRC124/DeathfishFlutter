import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/track.dart';
import '../services/deathfish_audio_handler.dart';

class AudioProvider extends ChangeNotifier {
  AudioProvider({AudioPlayer? player, DeathfishAudioHandler? handler})
    : _player = player ?? handler?.player ?? AudioPlayer(),
      _handler = handler {
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });
    _positionSubscription = _player.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      _position = _duration;
      _playerState = PlayerState.stopped;
      notifyListeners();
    });
  }

  final AudioPlayer _player;
  final DeathfishAudioHandler? _handler;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _completeSubscription;

  Track? _currentTrack;
  Source? _currentSource;
  String? _currentSourceKey;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> playTrack(
    Track track, {
    required Future<Uint8List?> Function(String mediaId) readLocalMedia,
    String? sourceUrl,
    String? localFilePath,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final sourceKey = localFilePath ?? sourceUrl ?? track.audioUrl;
      if (_currentTrack?.id != track.id || _currentSourceKey != sourceKey) {
        await _player.stop();
        _currentTrack = track;
        _currentSource = null;
        _currentSourceKey = sourceKey;
        _position = Duration.zero;
        _duration = Duration.zero;
        await _handler?.setTrack(track);
      }

      if (localFilePath != null) {
        _currentSource = DeviceFileSource(localFilePath);
      }
      final audioUrl = sourceUrl ?? track.audioUrl;
      if (_currentSource == null && audioUrl != null && audioUrl.isNotEmpty) {
        _currentSource = UrlSource(audioUrl);
      } else if (_currentSource == null) {
        final mediaId = track.audioMediaId;
        if (mediaId == null) {
          throw StateError('Esta canción no tiene audio adjunto.');
        }
        final bytes = await readLocalMedia(mediaId);
        if (bytes == null) {
          throw StateError('No se encontró el archivo de audio guardado.');
        }
        _currentSource = BytesSource(bytes, mimeType: track.audioMimeType);
      }
      await _player.play(_currentSource!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTrack(
    Track track, {
    required Future<Uint8List?> Function(String mediaId) readLocalMedia,
    String? sourceUrl,
    String? localFilePath,
  }) async {
    final sourceKey = localFilePath ?? sourceUrl ?? track.audioUrl;
    if (_currentTrack?.id == track.id &&
        _currentSourceKey == sourceKey &&
        isPlaying) {
      await _player.pause();
    } else if (_currentTrack?.id == track.id &&
        _currentSourceKey == sourceKey &&
        _playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await playTrack(
        track,
        readLocalMedia: readLocalMedia,
        sourceUrl: sourceUrl,
        localFilePath: localFilePath,
      );
    }
  }

  Future<void> playStream({
    required String title,
    required String url,
  }) async {
    if (url.trim().isEmpty) {
      throw ArgumentError.value(url, 'url', 'La transmisión no tiene URL.');
    }
    final track = Track(
      id: 'radio_live',
      number: 'FM',
      title: title,
      album: 'RADIO LA PECERA',
      duration: 'EN VIVO',
      lyrics: '',
      youtubeUrl: '',
      audioUrl: url,
    );
    await playTrack(
      track,
      readLocalMedia: (_) async => null,
      sourceUrl: url,
    );
  }

  Future<void> togglePlayback() async {
    if (_currentTrack == null || _isLoading) return;
    if (isPlaying) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      final source = _currentSource;
      if (source == null) {
        throw StateError('La pista cargada no tiene un origen de audio.');
      }
      await _player.play(source);
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> close() async {
    await _player.stop();
    await _handler?.clearTrack();
    _currentTrack = null;
    _currentSource = null;
    _currentSourceKey = null;
    _playerState = PlayerState.stopped;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_completeSubscription?.cancel());
    unawaited(_player.dispose());
    unawaited(_handler?.dispose());
    super.dispose();
  }
}
