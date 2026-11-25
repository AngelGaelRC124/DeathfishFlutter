import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/track.dart';

class DeathfishAudioHandler extends BaseAudioHandler with SeekHandler {
  DeathfishAudioHandler({AudioPlayer? player})
    : player = player ?? AudioPlayer() {
    _stateSubscription = this.player.onPlayerStateChanged.listen(_publishState);
    _positionSubscription = this.player.onPositionChanged.listen((position) {
      _position = position;
      playbackState.add(
        playbackState.value.copyWith(updatePosition: position),
      );
    });
    _durationSubscription = this.player.onDurationChanged.listen((duration) {
      final item = mediaItem.value;
      if (item != null) mediaItem.add(item.copyWith(duration: duration));
    });
    _publishState(this.player.state);
  }

  final AudioPlayer player;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  Duration _position = Duration.zero;

  Future<void> setTrack(Track track) {
    final artwork = Uri.tryParse(track.artUrl ?? '');
    mediaItem.add(
      MediaItem(
        id: track.id,
        title: track.title,
        album: track.album,
        artist: 'DEATHFISH',
        duration: _parseDuration(track.duration),
        artUri: artwork != null && artwork.hasAuthority ? artwork : null,
      ),
    );
    return Future<void>.value();
  }

  Future<void> clearTrack() async {
    mediaItem.add(null);
  }

  @override
  Future<void> play() async {
    await player.resume();
  }

  @override
  Future<void> pause() async {
    await player.pause();
  }

  @override
  Future<void> stop() async {
    await player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  void _publishState(PlayerState state) {
    final processingState = switch (state) {
      PlayerState.completed => AudioProcessingState.completed,
      PlayerState.stopped => AudioProcessingState.idle,
      _ => AudioProcessingState.ready,
    };
    final playing = state == PlayerState.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        playing: playing,
        processingState: processingState,
        updatePosition: _position,
        speed: 1,
      ),
    );
  }

  Duration? _parseDuration(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    if (minutes == null || seconds == null || seconds > 59) return null;
    return Duration(minutes: minutes, seconds: seconds);
  }

  Future<void> dispose() async {
    await _stateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
  }
}
