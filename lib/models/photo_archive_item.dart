import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoArchiveItem {
  const PhotoArchiveItem({
    required this.id,
    required this.imageUrl,
    required this.caption,
    this.eventDate,
    this.createdAt,
  });

  final String id;
  final String imageUrl;
  final String caption;
  final DateTime? eventDate;
  final DateTime? createdAt;

  factory PhotoArchiveItem.fromJson(String id, Map<String, dynamic> json) =>
      PhotoArchiveItem(
        id: id,
        imageUrl: json['imageUrl'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        eventDate: _date(json['eventDate']),
        createdAt: _date(json['createdAt']),
      );

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    'caption': caption,
    'eventDate': eventDate,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
