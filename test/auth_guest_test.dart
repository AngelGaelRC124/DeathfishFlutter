import 'package:flutter_test/flutter_test.dart';

import 'package:deathfishflutter/services/auth_service.dart';

void main() {
  test('guest session is local and can sign out without Firebase', () async {
    final service = AuthService();

    final session = await service.signInAsGuest();

    expect(session.uid, 'local-guest');
    expect(session.email, 'INVITADO');
    expect(session.isGuest, isTrue);
    expect(session.isAdmin, isFalse);

    await service.signOut();
  });
}
