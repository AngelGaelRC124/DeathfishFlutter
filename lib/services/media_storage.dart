import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';

class MediaStorage {
  static const _boxName = 'deathfish_media';
  static Future<Box<Uint8List>>? _openingBox;

  Future<Box<Uint8List>> _box() {
    if (Hive.isBoxOpen(_boxName)) {
      return Future.value(Hive.box<Uint8List>(_boxName));
    }
    return _openingBox ??= _openBox();
  }

  Future<Box<Uint8List>> _openBox() async {
    try {
      await Hive.initFlutter();
      return await Hive.openBox<Uint8List>(_boxName);
    } catch (_) {
      _openingBox = null;
      rethrow;
    }
  }

  Future<void> save(String id, Uint8List bytes) async {
    await (await _box()).put(id, bytes);
  }

  Future<Uint8List?> read(String id) async {
    return (await _box()).get(id);
  }

  Future<void> delete(String id) async {
    await (await _box()).delete(id);
  }
}
