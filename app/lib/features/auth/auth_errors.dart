import 'package:supabase_flutter/supabase_flutter.dart';

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
  return const AuthUiError(
    message: 'Something went wrong. Check your connection and try again.',
  );
}

AuthUiError mapAuthFailure(Object error) {
  if (error is AuthException) return mapAuthException(error);
  return const AuthUiError(
    message: 'Something went wrong. Check your connection and try again.',
  );
}
