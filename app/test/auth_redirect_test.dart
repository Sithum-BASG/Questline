import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/auth_redirect.dart';

void main() {
  test('a signed-out player is sent to welcome', () {
    expect(
      authRedirect(loading: false, signedIn: false, location: '/home'),
      '/welcome',
    );
    expect(
      authRedirect(loading: false, signedIn: false, location: '/welcome'),
      isNull,
    );
  });

  test('a signed-in player leaves welcome for home', () {
    expect(
      authRedirect(loading: false, signedIn: true, location: '/welcome'),
      '/home',
    );
    expect(
      authRedirect(loading: false, signedIn: true, location: '/quests'),
      isNull,
    );
  });

  test('auth loading does not redirect', () {
    expect(
      authRedirect(loading: true, signedIn: false, location: '/home'),
      isNull,
    );
  });
}
