import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/auth/auth_errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps invalid credentials to the password outline', () {
    final mapped = mapAuthException(
      const AuthException('Invalid login credentials'),
    );
    expect(mapped.message, contains("don't match"));
    expect(mapped.outline, AuthFieldOutline.password);
  });

  test('maps already registered to email outline with sign-in action', () {
    final mapped = mapAuthException(
      const AuthException('User already registered'),
    );
    expect(mapped.signInAction, isTrue);
    expect(mapped.outline, AuthFieldOutline.email);
  });

  test('maps unknown errors to the network fallback', () {
    final mapped = mapAuthFailure(Exception('offline'));
    expect(mapped.message, contains('connection'));
    expect(mapped.outline, AuthFieldOutline.none);
  });
}
