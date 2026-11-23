import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deathfishflutter/main.dart';
import 'package:deathfishflutter/models/contact_message.dart';
import 'package:deathfishflutter/models/feed_item.dart';
import 'package:deathfishflutter/models/merch_item.dart';
import 'package:deathfishflutter/models/track.dart';
import 'package:deathfishflutter/models/user_session.dart';
import 'package:deathfishflutter/services/auth_service.dart';
import 'package:deathfishflutter/services/data_service.dart';
import 'package:deathfishflutter/services/firestore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest receives live content with read-only access', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final authService = _FakeAuthService();
    final firestoreService = _FakeFirestoreService();
    final dataService = await DataService.load();
    addTearDown(authService.dispose);

    await tester.pumpWidget(
      DeathfishApp(
        authService: authService,
        firestoreService: firestoreService,
        dataService: dataService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(firestoreService.seedCount, 0);
    await tester.tap(find.text('ENTRAR COMO INVITADO'));
    await tester.pumpAndSettle();

    expect(find.text('ACCESO INVITADO // LA PECERA RECORDS'), findsOneWidget);
    expect(find.text('> COMUNICADOS RECIENTES'), findsOneWidget);
    expect(find.byTooltip('Panel de administrador'), findsNothing);

    await tester.tap(find.text('MERCH'));
    await tester.pumpAndSettle();
    expect(find.text('> MERCH OFICIAL'), findsOneWidget);
    await tester.tap(find.text('AGREGAR').first);
    await tester.pumpAndSettle();
    expect(find.text('CARRITO (1)'), findsOneWidget);
    await tester.tap(find.text('CARRITO (1)'));
    await tester.pumpAndSettle();
    expect(find.text('\$300.00'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ARCHIVO'));
    await tester.pumpAndSettle();
    expect(find.text('wow&flutter'), findsOneWidget);
    await tester.tap(find.text('wow&flutter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('INICIANDO ARCHIVO DE TEXTO'), findsOneWidget);
    final favoriteButton = find.ancestor(
      of: find.byIcon(Icons.favorite_border),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(favoriteButton).onPressed, isNull);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('STREAM'));
    await tester.pumpAndSettle();
    expect(find.text('> STREAM / TRANSMISIONES'), findsOneWidget);
    await tester.tap(find.text('CONTACTO'));
    await tester.pumpAndSettle();
    expect(find.text('NOMBRE / ORGANIZACIÓN'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    await tester.tap(find.text('CREAR CUENTA DE FAN'));
    await tester.pumpAndSettle();
    expect(find.text('NOMBRE'), findsOneWidget);
    expect(find.text('CREAR CUENTA'), findsOneWidget);
  });
}

class _FakeAuthService implements AuthGateway {
  final StreamController<UserSession?> _changes =
      StreamController<UserSession?>.broadcast();
  UserSession? _session;

  Future<void> dispose() => _changes.close();

  @override
  Stream<UserSession?> get sessionChanges async* {
    yield _session;
    yield* _changes.stream;
  }

  @override
  Future<UserSession> signIn(String email, String password) async {
    final session = UserSession(
      uid: 'fan-test',
      email: email,
      isGuest: false,
      isAdmin: email == 'admin@deathfish.com',
    );
    _session = session;
    _changes.add(session);
    return session;
  }

  @override
  Future<UserSession> register(
    String name,
    String email,
    String password,
  ) async {
    final session = await signIn(email, password);
    return session;
  }

  @override
  Future<UserSession> signInAsGuest() async {
    const session = UserSession(
      uid: 'guest-test',
      email: 'INVITADO',
      isGuest: true,
    );
    _session = session;
    _changes.add(session);
    return session;
  }

  @override
  Future<bool> isCurrentUserAdmin() async => false;

  @override
  Future<void> signOut() async {
    _session = null;
    _changes.add(null);
  }
}

class _FakeFirestoreService implements FirestoreGateway {
  int seedCount = 0;

  static const _feed = [
    FeedItem(
      id: 'post_01',
      date: '2026-11-15',
      title: 'SESIÓN DE PRUEBA',
      location: 'LA PECERA',
      description: 'Comunicado de prueba.',
      tag: 'ESTUDIO',
    ),
  ];
  static const _tracks = [
    Track(
      id: 'trk_01',
      number: '01',
      title: 'wow&flutter',
      album: 'Deathfish 1',
      duration: '03:18',
      lyrics: '[INICIANDO ARCHIVO DE TEXTO: wow&flutter]',
      youtubeUrl: 'https://www.youtube.com/@deathfishband',
    ),
  ];
  static const _merch = [
    MerchItem(
      id: 'mrc_01',
      name: 'PLAYERA TERMINAL',
      category: 'ROPA',
      price: 300,
      sizes: ['S', 'M', 'L', 'XL'],
      stock: 12,
      image: 'assets/fondo1.JPG',
      description: 'Producto de prueba.',
    ),
  ];

  @override
  Stream<List<FeedItem>> watchFeed() => Stream.value(_feed);

  @override
  Stream<List<Track>> watchTracks() => Stream.value(_tracks);

  @override
  Stream<List<MerchItem>> watchMerch() => Stream.value(_merch);

  @override
  Stream<List<ContactMessage>> watchMessages() => Stream.value([]);

  @override
  Stream<Set<String>> watchFavoriteIds(String uid) => Stream.value({});

  @override
  Future<void> saveFeedItem(FeedItem item) async {}

  @override
  Future<void> deleteFeedItem(String id) async {}

  @override
  Future<void> saveTrack(Track track) async {}

  @override
  Future<void> deleteTrack(String id) async {}

  @override
  Future<void> saveMerchItem(MerchItem item) async {}

  @override
  Future<void> deleteMerchItem(String id) async {}

  @override
  Future<void> updateMessageStatus(String id, String status) async {}

  @override
  Future<void> deleteMessage(String id) async {}

  @override
  Future<void> setFavorite(String uid, String trackId, bool isFavorite) async {}

  @override
  Future<void> saveContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {}

  @override
  Future<void> seedInitialDataIfEmpty() async {
    seedCount++;
  }
}
