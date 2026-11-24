import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/contact_message.dart';
import '../models/feed_item.dart';
import '../models/merch_item.dart';
import '../models/track.dart';

abstract interface class FirestoreGateway {
  Stream<List<FeedItem>> watchFeed();
  Stream<List<Track>> watchTracks();
  Stream<List<MerchItem>> watchMerch();
  Stream<List<ContactMessage>> watchMessages();
  Stream<Set<String>> watchFavoriteIds(String uid);

  Future<void> saveFeedItem(FeedItem item);
  Future<void> deleteFeedItem(String id);
  Future<void> setEventAttendance(String eventId, String uid, bool isAttending);
  Future<void> saveTrack(Track track);
  Future<void> deleteTrack(String id);
  Future<void> saveMerchItem(MerchItem item);
  Future<void> deleteMerchItem(String id);
  Future<void> updateMessageStatus(String id, String status);
  Future<void> deleteMessage(String id);
  Future<void> setFavorite(String uid, String trackId, bool isFavorite);
  Future<void> saveContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  });

  Future<void> seedInitialDataIfEmpty();
}

class FirestoreService implements FirestoreGateway {
  FirestoreService({FirebaseFirestore? firestore, AssetBundle? assetBundle})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _assetBundle = assetBundle ?? rootBundle;

  final FirebaseFirestore _firestore;
  final AssetBundle _assetBundle;

  CollectionReference<Map<String, dynamic>> get _feed =>
      _firestore.collection('feed');
  CollectionReference<Map<String, dynamic>> get _tracks =>
      _firestore.collection('tracks');
  CollectionReference<Map<String, dynamic>> get _merch =>
      _firestore.collection('merch');

  @override
  Stream<List<FeedItem>> watchFeed() => _feed
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_feedFromDocument).toList());

  @override
  Stream<List<Track>> watchTracks() => _tracks
      .orderBy('numero')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_trackFromDocument).toList());

  @override
  Stream<List<MerchItem>> watchMerch() => _merch.snapshots().map(
    (snapshot) => snapshot.docs.map(_merchFromDocument).toList(),
  );

  @override
  Stream<List<ContactMessage>> watchMessages() => _firestore
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((document) {
          final data = document.data();
          final timestamp = data['createdAt'];
          return ContactMessage(
            id: document.id,
            sender: data['remitente'] as String,
            email: data['email'] as String,
            subject: data['asunto'] as String,
            body: data['cuerpo'] as String,
            status: data['estado'] as String,
            createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
          );
        }).toList(),
      );

  @override
  Stream<Set<String>> watchFavoriteIds(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((document) => document.id).toSet());

  @override
  Future<void> saveFeedItem(FeedItem item) async {
    _requireId(item.id);
    await _feed.doc(item.id).set(item.toJson());
  }

  @override
  Future<void> deleteFeedItem(String id) => _feed.doc(id).delete();

  @override
  Future<void> setEventAttendance(
    String eventId,
    String uid,
    bool isAttending,
  ) async {
    _requireId(eventId);
    _requireId(uid);
    await _feed.doc(eventId).update({
      'asistentes': isAttending
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<void> saveTrack(Track track) async {
    _requireId(track.id);
    await _tracks.doc(track.id).set(track.toJson());
  }

  @override
  Future<void> deleteTrack(String id) => _tracks.doc(id).delete();

  @override
  Future<void> saveMerchItem(MerchItem item) async {
    _requireId(item.id);
    await _merch.doc(item.id).set(item.toJson());
  }

  @override
  Future<void> deleteMerchItem(String id) => _merch.doc(id).delete();

  @override
  Future<void> updateMessageStatus(String id, String status) async {
    _requireId(id);
    if (status.trim().isEmpty) {
      throw const FormatException('El estado no puede estar vacío.');
    }
    await _firestore.collection('messages').doc(id).update({
      'estado': status.trim(),
    });
  }

  @override
  Future<void> deleteMessage(String id) =>
      _firestore.collection('messages').doc(id).delete();

  @override
  Future<void> setFavorite(String uid, String trackId, bool isFavorite) async {
    _requireId(uid);
    _requireId(trackId);
    final favorite = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(trackId);
    if (isFavorite) {
      await favorite.set({
        'trackId': trackId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await favorite.delete();
    }
  }

  @override
  Future<void> saveContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final reference = _firestore.collection('messages').doc();
    await reference.set({
      'id': reference.id,
      'remitente': name.trim(),
      'email': email.trim(),
      'asunto': subject.trim(),
      'cuerpo': message.trim(),
      'estado': 'pendiente',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> seedInitialDataIfEmpty() async {
    final collections = <String, CollectionReference<Map<String, dynamic>>>{
      'feed': _feed,
      'tracks': _tracks,
      'merch': _merch,
    };
    final emptyCollections =
        <String, CollectionReference<Map<String, dynamic>>>{};
    for (final entry in collections.entries) {
      final existing = await entry.value.limit(1).get();
      if (existing.docs.isEmpty) emptyCollections[entry.key] = entry.value;
    }
    if (emptyCollections.isEmpty) return;

    final decoded = jsonDecode(
      await _assetBundle.loadString('assets/data.json'),
    );
    if (decoded is! Map) {
      throw const FormatException('La raíz de data.json debe ser un objeto.');
    }
    final source = Map<String, dynamic>.from(decoded);
    for (final entry in emptyCollections.entries) {
      final rawItems = source[entry.key];
      if (rawItems is! List) {
        throw FormatException('La sección "${entry.key}" no es una lista.');
      }
      final items = rawItems.map((item) {
        if (item is! Map) {
          throw FormatException('Hay un elemento inválido en "${entry.key}".');
        }
        return Map<String, dynamic>.from(item);
      });
      final pending = <Map<String, dynamic>>[];
      for (final item in items) {
        final id = item['id'];
        if (id is! String || id.trim().isEmpty) {
          throw FormatException('Un elemento de "${entry.key}" no tiene id.');
        }
        pending.add(item);
      }
      for (var start = 0; start < pending.length; start += 450) {
        final batch = _firestore.batch();
        final end = (start + 450 < pending.length)
            ? start + 450
            : pending.length;
        for (final item in pending.sublist(start, end)) {
          batch.set(entry.value.doc(item['id'] as String), item);
        }
        await batch.commit();
      }
    }
  }

  FeedItem _feedFromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      FeedItem.fromJson({...doc.data(), 'id': doc.id});

  Track _trackFromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      Track.fromJson({...doc.data(), 'id': doc.id});

  MerchItem _merchFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) => MerchItem.fromJson({...doc.data(), 'id': doc.id});

  void _requireId(String id) {
    if (id.trim().isEmpty) {
      throw const FormatException('El identificador no puede estar vacío.');
    }
  }
}
