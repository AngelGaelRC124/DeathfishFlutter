class GuestbookEntry {
  const GuestbookEntry({
    required this.id,
    required this.uid,
    required this.author,
    required this.message,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String author;
  final String message;
  final DateTime? createdAt;
}
