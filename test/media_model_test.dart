import 'package:flutter_test/flutter_test.dart';

import 'package:deathfishflutter/models/feed_item.dart';
import 'package:deathfishflutter/models/ep_progress.dart';
import 'package:deathfishflutter/models/merch_item.dart';
import 'package:deathfishflutter/models/scene_entry.dart';
import 'package:deathfishflutter/models/secret_code.dart';
import 'package:deathfishflutter/models/track.dart';

void main() {
  test('EP progress clamps percentage to the supported range', () {
    final progress = EpProgress.fromJson({
      'projectName': 'DEATHFISH 1',
      'stage': 'MEZCLA',
      'percentage': 120,
      'statusNote': 'Últimos ajustes',
    });

    expect(progress.percentage, 100);
    expect(progress.toJson()['percentage'], 100);
  });

  test('scene directory entry serializes all public directory fields', () {
    const entry = SceneEntry(
      id: 'scene-1',
      name: 'FORO TEST',
      category: 'FORO',
      city: 'CDMX',
      description: 'Espacio independiente.',
      externalUrl: 'https://example.test',
    );

    expect(
      SceneEntry.fromJson(entry.id, entry.toJson()).externalUrl,
      entry.externalUrl,
    );
  });

  test('secret reward metadata round-trips with optional links', () {
    const code = SecretCode(
      code: 'PECERA2026',
      rewardTitle: 'ACCESO A LA PECERA',
      rewardDescription: 'Recompensa de prueba.',
      secretUrl: 'https://example.test/bonus',
      active: true,
    );

    final restored = SecretCode.fromJson(code.toJson());
    expect(restored.code, code.code);
    expect(restored.rewardTitle, code.rewardTitle);
    expect(restored.rewardDescription, code.rewardDescription);
    expect(restored.secretUrl, code.secretUrl);
    expect(restored.active, isTrue);
  });

  test('track media URLs round-trip and legacy fields remain optional', () {
    final track = Track(
      id: 'track-1',
      number: '1',
      title: 'TEST',
      album: 'ALBUM',
      duration: '01:00',
      lyrics: '',
      youtubeUrl: '',
      audioUrl: 'https://storage.example/audio.mp3',
      demoUrl: 'https://storage.example/demo.mp3',
      rehearsalUrl: 'https://storage.example/rehearsal.mp3',
      credits: 'CRÉDITOS DE PRUEBA',
      videoUrl: 'https://storage.example/video.mp4',
      videoName: 'video.mp4',
    );

    final restored = Track.fromJson(track.toJson());
    expect(restored.audioUrl, track.audioUrl);
    expect(restored.demoUrl, track.demoUrl);
    expect(restored.rehearsalUrl, track.rehearsalUrl);
    expect(restored.credits, track.credits);
    expect(restored.videoUrl, track.videoUrl);
    expect(restored.videoName, track.videoName);

    final legacy = Map<String, dynamic>.from(track.toJson())
      ..remove('audio_url')
      ..remove('demo_url')
      ..remove('rehearsal_url')
      ..remove('video_url')
      ..remove('video_name');
    expect(Track.fromJson(legacy).videoUrl, isNull);
    expect(Track.fromJson(legacy).demoUrl, isNull);
    expect(Track.fromJson(legacy).rehearsalUrl, isNull);
  });

  test('fan-only and conceptual art track fields round-trip', () {
    final track = Track(
      id: 'track-2',
      number: '2',
      title: 'EXCLUSIVE',
      album: 'ALBUM',
      duration: '02:00',
      lyrics: '',
      youtubeUrl: '',
      soloFans: true,
      artUrl: 'https://storage.example/art.png',
      releaseDate: DateTime.utc(2027, 1, 2, 3, 4),
    );

    final restored = Track.fromJson(track.toJson());
    expect(restored.soloFans, isTrue);
    expect(restored.artUrl, track.artUrl);
    expect(restored.releaseDate, track.releaseDate);

    final legacy = Map<String, dynamic>.from(track.toJson())
      ..remove('solo_fans')
      ..remove('art_url')
      ..remove('release_date');
    final restoredLegacy = Track.fromJson(legacy);
    expect(restoredLegacy.soloFans, isFalse);
    expect(restoredLegacy.artUrl, isNull);
    expect(restoredLegacy.releaseDate, isNull);
  });

  test('feed attendance list round-trips and defaults for old documents', () {
    const item = FeedItem(
      id: 'event-1',
      date: '2026-11-15',
      title: 'EVENT',
      location: 'VENUE',
      description: '',
      tag: 'LIVE',
      attendeeIds: ['fan-1', 'fan-2'],
    );

    expect(FeedItem.fromJson(item.toJson()).attendeeIds, item.attendeeIds);

    final legacy = Map<String, dynamic>.from(item.toJson())
      ..remove('asistentes');
    expect(FeedItem.fromJson(legacy).attendeeIds, isEmpty);
  });

  test('merch image URLs round-trip without requiring a remote URL', () {
    const product = MerchItem(
      id: 'product-1',
      name: 'TEST',
      category: 'ROPA',
      price: 100,
      sizes: ['M'],
      stock: 1,
      image: '',
      description: '',
      imageUrl: 'https://storage.example/image.png',
    );

    expect(MerchItem.fromJson(product.toJson()).imageUrl, product.imageUrl);
  });
}
