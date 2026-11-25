class VoiceNote {
  const VoiceNote({
    required this.id,
    required this.title,
    required this.author,
    required this.audioUrl,
    required this.duration,
    this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String audioUrl;
  final int duration;
  final DateTime? createdAt;
}
