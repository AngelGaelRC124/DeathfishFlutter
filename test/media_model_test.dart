import 'package:flutter_test/flutter_test.dart';

import 'package:deathfishflutter/models/feed_item.dart';
import 'package:deathfishflutter/models/merch_item.dart';
import 'package:deathfishflutter/models/track.dart';

void main() {
  test('track media URLs round-trip and legacy fields remain optional', () {
    const track = Track(
      id: 'track-1',
      number: '1',
      title: 'TEST',
      album: 'ALBUM',
      duration: '01:00',
      lyrics: '',
      youtubeUrl: '',
      audioUrl: 'https://storage.example/audio.mp3',
      videoUrl: 'https://storage.example/video.mp4',
      videoName: 'video.mp4',
    );

    final restored = Track.fromJson(track.toJson());
    expect(restored.audioUrl, track.audioUrl);
    expect(restored.videoUrl, track.videoUrl);
    expect(restored.videoName, track.videoName);

    final legacy = Map<String, dynamic>.from(track.toJson())
      ..remove('audio_url')
      ..remove('video_url')
      ..remove('video_name');
    expect(Track.fromJson(legacy).videoUrl, isNull);
  });

  test('fan-only and conceptual art track fields round-trip', () {
    const track = Track(
      id: 'track-2',
      number: '2',
      title: 'EXCLUSIVE',
      album: 'ALBUM',
      duration: '02:00',
      lyrics: '',
      youtubeUrl: '',
      soloFans: true,
      artUrl: 'https://storage.example/art.png',
    );

    final restored = Track.fromJson(track.toJson());
    expect(restored.soloFans, isTrue);
    expect(restored.artUrl, track.artUrl);

    final legacy = Map<String, dynamic>.from(track.toJson())
      ..remove('solo_fans')
      ..remove('art_url');
    final restoredLegacy = Track.fromJson(legacy);
    expect(restoredLegacy.soloFans, isFalse);
    expect(restoredLegacy.artUrl, isNull);
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
