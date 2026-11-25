import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const bucketName = 'media';

  final SupabaseClient _client;

  Future<String> pickAndUploadFile({
    required String folder,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final extension = fileName.split('.').last.toLowerCase();
      const mimeTypes = {
        'mp3': 'audio/mpeg',
        'm4a': 'audio/mp4',
        'wav': 'audio/wav',
        'mp4': 'video/mp4',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'bmp': 'image/bmp',
        'heic': 'image/heic',
        'heif': 'image/heif',
        'avif': 'image/avif',
      };
      final mimeType = mimeTypes[extension];
      if (mimeType == null) {
        throw FormatException('Tipo de archivo no admitido: .$extension');
      }

      final objectPath =
          '$folder/${DateTime.now().microsecondsSinceEpoch}.$extension';
      await _client.storage
          .from(bucketName)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );
      return _client.storage.from(bucketName).getPublicUrl(objectPath);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
