import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/api_client.dart';
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

  test('maps an unconfirmed email to a confirm-first message', () {
    final mapped = mapAuthException(const AuthException('Email not confirmed', code: 'email_not_confirmed'));
    expect(mapped.message, contains('Confirm your email'));
    expect(mapped.outline, AuthFieldOutline.email);
  });

  test('maps rate limits to a wait message', () {
    final mapped = mapAuthException(const AuthException('email rate limit exceeded', statusCode: '429'));
    expect(mapped.message, contains('Too many attempts'));
  });

  test('says when Google sign-in is not set up', () {
    final mapped = mapAuthException(const AuthException('Google sign-in is not configured yet.'));
    expect(mapped.message, contains("isn't set up"));
  });

  test('shows the server reason for other auth errors', () {
    final mapped = mapAuthException(const AuthException('Signups not allowed for this instance'));
    expect(mapped.message, 'Signups not allowed for this instance');
  });

  test('keeps the connection message for network failures', () {
    final mapped = mapAuthException(AuthRetryableFetchException(message: 'Failed host lookup'));
    expect(mapped.message, contains('connection'));
  });

  test('shows Edge Function errors with their friendly copy', () {
    final mapped = mapAuthFailure(const ApiException(code: 'unauthorized', message: 'Sign in to continue.'));
    expect(mapped.message, 'Sign in to continue.');
  });
}
