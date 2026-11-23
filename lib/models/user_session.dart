class UserSession {
  const UserSession({
    required this.uid,
    required this.email,
    required this.isGuest,
    this.isAdmin = false,
  });

  final String uid;
  final String email;
  final bool isGuest;
  final bool isAdmin;
}
