class UserSession {
  const UserSession({required this.email, required this.isGuest});

  final String email;
  final bool isGuest;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      email: json['email'] as String,
      isGuest: json['is_guest'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {'email': email, 'is_guest': isGuest};
}
