class Track {
  const Track({
    required this.id,
    required this.number,
    required this.title,
    required this.album,
    required this.duration,
    required this.lyrics,
    required this.youtubeUrl,
  });

  final String id;
  final String number;
  final String title;
  final String album;
  final String duration;
  final String lyrics;
  final String youtubeUrl;

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      number: json['numero'] as String,
      title: json['titulo'] as String,
      album: json['album'] as String,
      duration: json['duracion'] as String,
      lyrics: json['letras'] as String,
      youtubeUrl: json['youtube_url'] as String,
    );
  }
}
