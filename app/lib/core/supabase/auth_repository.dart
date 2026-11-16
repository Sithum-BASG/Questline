import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Email and password auth. Google sign-in is added on the welcome screen.
abstract class AuthApi {
  /// Returns true when the new account is signed in straight away, false when
  /// the project requires the email to be confirmed first.
  Future<bool> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  /// Returns true once Supabase has a session, false when the user (or the
  /// platform) cancelled the Google prompt.
  Future<bool> signInWithGoogle({required String serverClientId});
  Future<void> resetPasswordForEmail(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
}

class AuthRepository implements AuthApi {
  AuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(email: email, password: password);
    return response.session != null;
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signInWithGoogle({required String serverClientId}) async {
    if (serverClientId.isEmpty) {
      throw const AuthException('Google sign-in is not configured yet.');
    }
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      // On iOS the app signs in with its own iOS client; the web client id still sets the token's
      // audience, which Supabase checks. Without an override the SDK uses GIDClientID from Info.plist.
      final iosClient = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS && googleIosClientId.isNotEmpty
          ? googleIosClientId
          : null;
      await google.initialize(clientId: iosClient, serverClientId: serverClientId);
      _googleReady = true;
    }
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Google did not return a sign-in token.');
      }
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return response.session != null;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return false;
      throw AuthException(error.description ?? 'Google sign-in failed.');
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'questline://auth-callback',
    );
  }

  @override
  Future<void> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

bool _googleReady = false;
