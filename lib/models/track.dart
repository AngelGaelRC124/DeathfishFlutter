import 'package:cloud_firestore/cloud_firestore.dart';

class Track {
  const Track({
    required this.id,
    required this.number,
    required this.title,
    required this.album,
    required this.duration,
    required this.lyrics,
    required this.youtubeUrl,
    this.audioMediaId,
    this.audioName,
    this.audioMimeType,
    this.audioUrl,
    this.demoUrl,
    this.rehearsalUrl,
    this.credits,
    this.videoUrl,
    this.videoName,
    this.soloFans = false,
    this.artUrl,
    this.releaseDate,
  });

  final String id;
  final String number;
  final String title;
  final String album;
  final String duration;
  final String lyrics;
  final String youtubeUrl;
  final String? audioMediaId;
  final String? audioName;
  final String? audioMimeType;
  final String? audioUrl;
  final String? demoUrl;
  final String? rehearsalUrl;
  final String? credits;
  final String? videoUrl;
  final String? videoName;
  final bool soloFans;
  final String? artUrl;
  final DateTime? releaseDate;

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      number: json['numero'].toString(),
      title: json['titulo'] as String,
      album: json['album'] as String,
      duration: json['duracion'] as String,
      lyrics: json['letras'] as String,
      youtubeUrl: json['youtube_url'] as String,
      audioMediaId: json['audio_media_id'] as String?,
      audioName: json['audio_name'] as String?,
      audioMimeType: json['audio_mime_type'] as String?,
      audioUrl: json['audio_url'] as String?,
      demoUrl: json['demo_url'] as String?,
      rehearsalUrl: json['rehearsal_url'] as String?,
      credits: json['credits'] as String?,
      videoUrl: json['video_url'] as String?,
      videoName: json['video_name'] as String?,
      soloFans: json['solo_fans'] as bool? ?? false,
      artUrl: json['art_url'] as String?,
      releaseDate: _date(json['release_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero': number,
    'titulo': title,
    'album': album,
    'duracion': duration,
    'letras': lyrics,
    'youtube_url': youtubeUrl,
    'audio_media_id': audioMediaId,
    'audio_name': audioName,
    'audio_mime_type': audioMimeType,
    'audio_url': audioUrl,
    'demo_url': demoUrl,
    'rehearsal_url': rehearsalUrl,
    'credits': credits,
    'video_url': videoUrl,
    'video_name': videoName,
    'solo_fans': soloFans,
    'art_url': artUrl,
    'release_date': releaseDate,
  };

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
