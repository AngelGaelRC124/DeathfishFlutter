class FeedItem {
  const FeedItem({
    required this.id,
    required this.date,
    required this.title,
    required this.location,
    required this.description,
    required this.tag,
    this.attendeeIds = const [],
  });

  final String id;
  final String date;
  final String title;
  final String location;
  final String description;
  final String tag;
  final List<String> attendeeIds;

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      date: json['fecha'] as String,
      title: json['titulo'] as String,
      location: json['ubicacion'] as String,
      description: json['descripcion'] as String,
      tag: json['tag'] as String,
      attendeeIds: List<String>.unmodifiable(
        (json['asistentes'] as List<dynamic>? ?? const []).cast<String>(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': date,
    'titulo': title,
    'ubicacion': location,
    'descripcion': description,
    'tag': tag,
    'asistentes': attendeeIds,
  };
}
