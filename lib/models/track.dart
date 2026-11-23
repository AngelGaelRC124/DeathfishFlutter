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
  };
}
