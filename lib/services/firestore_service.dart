import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/contact_message.dart';
import '../models/ep_progress.dart';
import '../models/feed_item.dart';
import '../models/guestbook_entry.dart';
import '../models/merch_item.dart';
import '../models/photo_archive_item.dart';
import '../models/radio_station.dart';
import '../models/scene_entry.dart';
import '../models/secret_code.dart';
import '../models/track.dart';
import '../models/timed_comment.dart';
import '../models/voice_note.dart';

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

abstract interface class RadioGateway {
  Stream<RadioStation> watchRadioStation();
  Stream<List<RadioChatMessage>> watchRadioChat();
  Future<void> updateRadioStation({
    required bool isLive,
    required String streamUrl,
    required String programTitle,
  });
  Future<void> sendRadioMessage({
    required String uid,
    required String author,
    required String message,
  });
  Future<void> clearRadioChat();
  Future<void> adjustRadioListeners(int delta);
}

abstract interface class VoiceNoteGateway {
  Stream<List<VoiceNote>> watchVoiceNotes();
  Future<void> saveVoiceNote({
    required String title,
    required String author,
    required String audioUrl,
    required int duration,
  });
  Future<void> deleteVoiceNote(String id);
}

abstract interface class PhaseTwoGateway {
  Stream<List<SecretCode>> watchSecretCodes({required bool activeOnly});
  Future<void> saveSecretCode(SecretCode code);
  Future<void> deleteSecretCode(String code);
  Future<SecretCode> redeemSecretCode(String uid, String code);
  Stream<List<GuestbookEntry>> watchGuestbook();
  Future<void> addGuestbookMessage({
    required String uid,
    required String author,
    required String message,
  });
  Future<void> deleteGuestbookEntry(String id);
  Future<Map<String, dynamic>?> readUserProfile(String uid);
  Future<void> registerEventAttendance(String uid);
}

abstract interface class PhaseThreeGateway {
  Stream<EpProgress> watchEpProgress();
  Future<void> saveEpProgress(EpProgress progress);
  Stream<List<SceneEntry>> watchSceneDirectory();
  Future<void> saveSceneEntry(SceneEntry entry);
  Future<void> deleteSceneEntry(String id);
  Stream<List<TimedComment>> watchTimedComments(String trackId);
  Future<void> addTimedComment({
    required String trackId,
    required String uid,
    required String userName,
    required int second,
    required String text,
  });
  Future<void> deleteTimedComment(String trackId, String commentId);
  Stream<List<PhotoArchiveItem>> watchPhotoArchive();
  Future<void> savePhotoArchiveItem(PhotoArchiveItem item);
  Future<void> deletePhotoArchiveItem(String id);
}

class FirestoreService
    implements
        FirestoreGateway,
        RadioGateway,
        VoiceNoteGateway,
        PhaseTwoGateway,
        PhaseThreeGateway {
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
  DocumentReference<Map<String, dynamic>> get _radio =>
      _firestore.collection('config').doc('radio');
  CollectionReference<Map<String, dynamic>> get _radioChat =>
      _radio.collection('chat');
  CollectionReference<Map<String, dynamic>> get _secretCodes =>
      _firestore.collection('secret_codes');
  CollectionReference<Map<String, dynamic>> get _guestbook =>
      _firestore.collection('guestbook');
  DocumentReference<Map<String, dynamic>> get _epProgress =>
      _firestore.collection('config').doc('ep_progress');
  CollectionReference<Map<String, dynamic>> get _sceneDirectory =>
      _firestore.collection('scene_directory');
  CollectionReference<Map<String, dynamic>> get _photoArchive =>
      _firestore.collection('photo_archive');

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
  Stream<RadioStation> watchRadioStation() => _radio.snapshots().map(
    (snapshot) => RadioStation.fromJson(snapshot.data() ?? const {}),
  );

  @override
  Stream<List<RadioChatMessage>> watchRadioChat() => _radioChat
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.reversed.map((document) {
          final data = document.data();
          final timestamp = data['createdAt'];
          return RadioChatMessage(
            author: data['author'] as String? ?? 'FAN',
            message: data['message'] as String? ?? '',
            createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
          );
        }).toList(),
      );

  @override
  Future<void> updateRadioStation({
    required bool isLive,
    required String streamUrl,
    required String programTitle,
  }) => _firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(_radio);
    final previous = snapshot.data() ?? const <String, dynamic>{};
    transaction.set(
      _radio,
      {
        'isLive': isLive,
        'streamUrl': streamUrl.trim(),
        'programTitle': programTitle.trim(),
        'listenersCount': previous['listenersCount'] as int? ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  });

  @override
  Future<void> sendRadioMessage({
    required String uid,
    required String author,
    required String message,
  }) async {
    _requireId(uid);
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty || trimmedMessage.length > 240) {
      throw const FormatException('El saludo debe tener entre 1 y 240 caracteres.');
    }
    await _radioChat.add({
      'uid': uid,
      'author': author.trim().isEmpty ? 'FAN' : author.trim(),
      'message': trimmedMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> clearRadioChat() async {
    while (true) {
      final snapshot = await _radioChat.limit(400).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> adjustRadioListeners(int delta) async {
    if (delta != 1 && delta != -1) {
      throw ArgumentError.value(delta, 'delta', 'Solo se admite +/- 1.');
    }
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_radio);
      final data = snapshot.data() ?? const <String, dynamic>{};
      final count = data['listenersCount'] as int? ?? 0;
      transaction.set(
        _radio,
        {'listenersCount': (count + delta).clamp(0, 0x7fffffff)},
        SetOptions(merge: true),
      );
    });
  }

  @override
  Stream<List<VoiceNote>> watchVoiceNotes() => _firestore
      .collection('voice_notes')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((document) {
          final data = document.data();
          final timestamp = data['createdAt'];
          return VoiceNote(
            id: document.id,
            title: data['title'] as String? ?? '',
            author: data['author'] as String? ?? '',
            audioUrl: data['audioUrl'] as String? ?? '',
            duration: data['duration'] as int? ?? 0,
            createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
          );
        }).toList(),
      );

  @override
  Future<void> saveVoiceNote({
    required String title,
    required String author,
    required String audioUrl,
    required int duration,
  }) async {
    await _firestore.collection('voice_notes').add({
      'title': title.trim(),
      'author': author.trim(),
      'audioUrl': audioUrl,
      'duration': duration,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteVoiceNote(String id) =>
      _firestore.collection('voice_notes').doc(id).delete();

  @override
  Stream<List<SecretCode>> watchSecretCodes({required bool activeOnly}) {
    Query<Map<String, dynamic>> query = _secretCodes;
    if (activeOnly) query = query.where('active', isEqualTo: true);
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((document) => SecretCode.fromJson(document.data()))
          .toList()
        ..sort((left, right) => left.code.compareTo(right.code)),
    );
  }

  @override
  Future<void> saveSecretCode(SecretCode code) async {
    final normalized = code.code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9_-]{3,40}$').hasMatch(normalized)) {
      throw const FormatException(
        'El código debe usar de 3 a 40 caracteres A-Z, 0-9, guion o guion bajo.',
      );
    }
    await _secretCodes.doc(normalized).set(
      SecretCode(
        code: normalized,
        rewardTitle: code.rewardTitle.trim(),
        rewardDescription: code.rewardDescription.trim(),
        active: code.active,
        secretUrl: code.secretUrl?.trim().isEmpty == true
            ? null
            : code.secretUrl?.trim(),
      ).toJson(),
    );
  }

  @override
  Future<void> deleteSecretCode(String code) =>
      _secretCodes.doc(code.trim().toUpperCase()).delete();

  @override
  Future<SecretCode> redeemSecretCode(String uid, String code) =>
      _firestore.runTransaction((transaction) async {
        final normalized = code.trim().toUpperCase();
        _requireId(uid);
        final codeReference = _secretCodes.doc(normalized);
        final userReference = _firestore.collection('users').doc(uid);
        final codeSnapshot = await transaction.get(codeReference);
        final userSnapshot = await transaction.get(userReference);
        final codeData = codeSnapshot.data();
        if (codeData == null || codeData['active'] != true) {
          throw StateError('CÓDIGO INVÁLIDO O DESACTIVADO.');
        }
        if (!userSnapshot.exists) {
          throw StateError('NO SE ENCONTRÓ EL PERFIL DEL USUARIO.');
        }
        final secretCode = SecretCode.fromJson(codeData);
        final unlockedCodes =
            userSnapshot.data()?['unlockedCodes'] as List<dynamic>? ?? [];
        if (!unlockedCodes.contains(normalized)) {
          transaction.update(userReference, {
            'unlockedCodes': FieldValue.arrayUnion([normalized]),
          });
        }
        return secretCode;
      });

  @override
  Stream<List<GuestbookEntry>> watchGuestbook() => _guestbook
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.reversed.map((document) {
          final data = document.data();
          final timestamp = data['createdAt'];
          return GuestbookEntry(
            id: document.id,
            uid: data['uid'] as String? ?? '',
            author: data['author'] as String? ?? 'FAN',
            message: data['message'] as String? ?? '',
            createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
          );
        }).toList(),
      );

  @override
  Future<void> addGuestbookMessage({
    required String uid,
    required String author,
    required String message,
  }) async {
    _requireId(uid);
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty || trimmedMessage.length > 200) {
      throw const FormatException(
        'El mensaje debe tener entre 1 y 200 caracteres.',
      );
    }
    await _guestbook.add({
      'uid': uid,
      'author': author.trim().isEmpty ? 'FAN' : author.trim(),
      'message': trimmedMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteGuestbookEntry(String id) => _guestbook.doc(id).delete();

  @override
  Future<Map<String, dynamic>?> readUserProfile(String uid) async {
    _requireId(uid);
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.data();
  }

  @override
  Future<void> registerEventAttendance(String uid) async {
    _requireId(uid);
    await _firestore.collection('users').doc(uid).update({
      'eventsAttended': FieldValue.increment(1),
    });
  }

  @override
  Stream<EpProgress> watchEpProgress() => _epProgress.snapshots().map(
    (snapshot) => EpProgress.fromJson(snapshot.data() ?? const {}),
  );

  @override
  Future<void> saveEpProgress(EpProgress progress) =>
      _epProgress.set(progress.toJson());

  @override
  Stream<List<SceneEntry>> watchSceneDirectory() =>
      _sceneDirectory.snapshots().map((snapshot) {
        final entries = snapshot.docs
            .map((document) => SceneEntry.fromJson(document.id, document.data()))
            .toList();
        entries.sort((left, right) {
          final category = left.category.compareTo(right.category);
          return category == 0 ? left.name.compareTo(right.name) : category;
        });
        return entries;
      });

  @override
  Future<void> saveSceneEntry(SceneEntry entry) async {
    final reference = entry.id.isEmpty
        ? _sceneDirectory.doc()
        : _sceneDirectory.doc(entry.id);
    await reference.set(entry.toJson());
  }

  @override
  Future<void> deleteSceneEntry(String id) =>
      _sceneDirectory.doc(id).delete();

  @override
  Stream<List<TimedComment>> watchTimedComments(String trackId) => _tracks
      .doc(trackId)
      .collection('timed_comments')
      .orderBy('second')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => TimedComment.fromJson(document.id, document.data()))
            .toList(),
      );

  @override
  Future<void> addTimedComment({
    required String trackId,
    required String uid,
    required String userName,
    required int second,
    required String text,
  }) async {
    _requireId(trackId);
    _requireId(uid);
    final trimmedText = text.trim();
    if (second < 0 || trimmedText.isEmpty || trimmedText.length > 200) {
      throw const FormatException(
        'La nota requiere un segundo válido y entre 1 y 200 caracteres.',
      );
    }
    await _tracks.doc(trackId).collection('timed_comments').add({
      'uid': uid,
      'userName': userName.trim().isEmpty ? 'FAN' : userName.trim(),
      'second': second,
      'text': trimmedText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteTimedComment(String trackId, String commentId) =>
      _tracks.doc(trackId).collection('timed_comments').doc(commentId).delete();

  @override
  Stream<List<PhotoArchiveItem>> watchPhotoArchive() => _photoArchive
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (document) =>
                  PhotoArchiveItem.fromJson(document.id, document.data()),
            )
            .toList(),
      );

  @override
  Future<void> savePhotoArchiveItem(PhotoArchiveItem item) async {
    final reference = item.id.isEmpty
        ? _photoArchive.doc()
        : _photoArchive.doc(item.id);
    await reference.set(item.toJson());
  }

  @override
  Future<void> deletePhotoArchiveItem(String id) =>
      _photoArchive.doc(id).delete();

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
