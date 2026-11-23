class UserSession {
  const UserSession({
    required this.email,
    required this.isGuest,
    this.isAdmin = false,
  });

  final String email;
  final bool isGuest;
  final bool isAdmin;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      email: json['email'] as String,
      isGuest: json['is_guest'] as bool,
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'is_guest': isGuest,
    'is_admin': isAdmin,
  };
}
