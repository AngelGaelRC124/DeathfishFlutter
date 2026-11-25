class SceneEntry {
  const SceneEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.description,
    required this.externalUrl,
  });

  final String id;
  final String name;
  final String category;
  final String city;
  final String description;
  final String externalUrl;

  factory SceneEntry.fromJson(String id, Map<String, dynamic> json) =>
      SceneEntry(
        id: id,
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        city: json['city'] as String? ?? '',
        description: json['description'] as String? ?? '',
        externalUrl: json['externalUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'city': city,
    'description': description,
    'externalUrl': externalUrl,
  };
}
