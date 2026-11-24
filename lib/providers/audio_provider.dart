import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/track.dart';

class AudioProvider extends ChangeNotifier {
  AudioProvider({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
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
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _completeSubscription;

  Track? _currentTrack;
  Source? _currentSource;
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
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_currentTrack?.id != track.id) {
        await _player.stop();
        _currentTrack = track;
        _currentSource = null;
        _position = Duration.zero;
        _duration = Duration.zero;
      }

      final audioUrl = track.audioUrl;
      if (audioUrl != null && audioUrl.isNotEmpty) {
        _currentSource = UrlSource(audioUrl);
      } else {
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
  }) async {
    if (_currentTrack?.id == track.id && isPlaying) {
      await _player.pause();
    } else if (_currentTrack?.id == track.id &&
        _playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await playTrack(track, readLocalMedia: readLocalMedia);
    }
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
    _currentTrack = null;
    _currentSource = null;
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
    super.dispose();
  }
}
