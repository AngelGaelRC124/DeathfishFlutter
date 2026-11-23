class ContactMessage {
  const ContactMessage({
    required this.id,
    required this.sender,
    required this.email,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String sender;
  final String email;
  final String subject;
  final String body;
  final String status;
  final DateTime? createdAt;
}
