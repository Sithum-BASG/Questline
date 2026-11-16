import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/api_client.dart';

enum AuthFieldOutline { none, email, password }

/// Mapped auth error for the welcome / reset screens.
class AuthUiError {
  const AuthUiError({
    required this.message,
    this.outline = AuthFieldOutline.none,
    this.signInAction = false,
  });

  final String message;
  final AuthFieldOutline outline;

  /// When true, the word "Sign in" in [message] should be tappable.
  final bool signInAction;
}

AuthUiError mapAuthException(AuthException error) {
  final raw = error.message.toLowerCase();
  if (raw.contains('invalid login credentials') ||
      raw.contains('invalid_credentials')) {
    return const AuthUiError(
      message: "That email and password don't match.",
      outline: AuthFieldOutline.password,
    );
  }
  if (raw.contains('user already registered') ||
      raw.contains('already been registered') ||
      raw.contains('already registered')) {
    return const AuthUiError(
      message: 'An account with this email already exists. Sign in instead.',
      outline: AuthFieldOutline.email,
      signInAction: true,
    );
  }
  final code = error.code ?? '';
  if (code == 'email_not_confirmed' || raw.contains('email not confirmed')) {
    return const AuthUiError(
      message: 'Confirm your email first. Check your inbox for the link.',
      outline: AuthFieldOutline.email,
    );
  }
  if (code.contains('rate_limit') || error.statusCode == '429' || raw.contains('rate limit')) {
    return const AuthUiError(message: 'Too many attempts. Wait a minute and try again.');
  }
  if (code == 'weak_password' || raw.contains('password should')) {
    return AuthUiError(message: error.message, outline: AuthFieldOutline.password);
  }
  if (raw.contains('not configured')) {
    return const AuthUiError(message: "Google sign-in isn't set up in this build yet.");
  }
  if (error is AuthRetryableFetchException || error.message.trim().isEmpty) {
    return const AuthUiError(message: _connectionMessage);
  }
  // Anything else: show Supabase's (or Google's) own reason.
  return AuthUiError(message: error.message);
}

const _connectionMessage = 'Something went wrong. Check your connection and try again.';

AuthUiError mapAuthFailure(Object error) {
  if (error is AuthException) return mapAuthException(error);
  // Edge Function errors already carry friendly copy.
  if (error is ApiException) return AuthUiError(message: error.message);
  return const AuthUiError(message: _connectionMessage);
}
