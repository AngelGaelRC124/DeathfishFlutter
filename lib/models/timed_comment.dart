import 'package:cloud_firestore/cloud_firestore.dart';

class TimedComment {
  const TimedComment({
    required this.id,
    required this.uid,
    required this.userName,
    required this.second,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String userName;
  final int second;
  final String text;
  final DateTime? createdAt;

  factory TimedComment.fromJson(String id, Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return TimedComment(
      id: id,
      uid: json['uid'] as String? ?? '',
      userName: json['userName'] as String? ?? 'FAN',
      second: (json['second'] as num? ?? 0).toInt(),
      text: json['text'] as String? ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : createdAt is DateTime
          ? createdAt
          : null,
    );
  }
}
