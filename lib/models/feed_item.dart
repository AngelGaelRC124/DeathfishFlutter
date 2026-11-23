class FeedItem {
  const FeedItem({
    required this.id,
    required this.date,
    required this.title,
    required this.location,
    required this.description,
    required this.tag,
  });

  final String id;
  final String date;
  final String title;
  final String location;
  final String description;
  final String tag;

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      date: json['fecha'] as String,
      title: json['titulo'] as String,
      location: json['ubicacion'] as String,
      description: json['descripcion'] as String,
      tag: json['tag'] as String,
    );
  }
}
