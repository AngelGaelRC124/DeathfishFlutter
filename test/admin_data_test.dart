import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deathfishflutter/models/feed_item.dart';
import 'package:deathfishflutter/models/merch_item.dart';
import 'package:deathfishflutter/models/track.dart';
import 'package:deathfishflutter/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('admin CRUD persists feed, tracks, and merch locally', () async {
    SharedPreferences.setMockInitialValues({});
    final service = await DataService.load();

    await expectLater(
      service.saveFeedItem(
        const FeedItem(
          id: 'post_admin_test',
          date: '2026-11-23',
          title: 'AVISO DE PRUEBA',
          location: 'LA PECERA',
          description: 'Prueba',
          tag: 'TEST',
        ),
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      service.login('adminfish', 'incorrecta'),
      throwsA(isA<FormatException>()),
    );
    await service.login('adminfish', 'administrafish');

    const feedItem = FeedItem(
      id: 'post_admin_test',
      date: '2026-11-23',
      title: 'AVISO DE PRUEBA',
      location: 'LA PECERA',
      description: 'Prueba',
      tag: 'TEST',
    );
    const track = Track(
      id: 'trk_admin_test',
      number: '99',
      title: 'CANCIÓN DE PRUEBA',
      album: 'DEMO',
      duration: '01:00',
      lyrics: 'LETRA DE PRUEBA',
      youtubeUrl: 'https://www.youtube.com/watch?v=test',
    );
    const merch = MerchItem(
      id: 'mrc_admin_test',
      name: 'PRODUCTO DE PRUEBA',
      category: 'TEST',
      price: 10,
      sizes: ['ÚNICA'],
      stock: 2,
      image: 'assets/fondo1.JPG',
      description: 'Producto de prueba',
    );

    await service.saveFeedItem(feedItem);
    await service.saveTrack(track);
    await service.saveMerchItem(merch);

    final reloaded = await DataService.load();
    expect(
      reloaded.feed.singleWhere((item) => item.id == feedItem.id).title,
      feedItem.title,
    );
    expect(
      reloaded.tracks.singleWhere((item) => item.id == track.id).title,
      track.title,
    );
    expect(
      reloaded.merch.singleWhere((item) => item.id == merch.id).name,
      merch.name,
    );

    await reloaded.saveFeedItem(
      const FeedItem(
        id: 'post_admin_test',
        date: '2026-11-23',
        title: 'AVISO EDITADO',
        location: 'LA PECERA',
        description: 'Prueba actualizada',
        tag: 'TEST',
      ),
    );
    await reloaded.deleteFeedItem(feedItem.id);
    await reloaded.deleteTrack(track.id);
    await reloaded.deleteMerchItem(merch.id);

    final afterDelete = await DataService.load();
    expect(afterDelete.feed.any((item) => item.id == feedItem.id), isFalse);
    expect(afterDelete.tracks.any((item) => item.id == track.id), isFalse);
    expect(afterDelete.merch.any((item) => item.id == merch.id), isFalse);
  });
}
