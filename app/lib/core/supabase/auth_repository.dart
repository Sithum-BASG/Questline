import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email and password auth. Google sign-in is added on the welcome screen.
abstract class AuthApi {
  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signInWithGoogle({required String serverClientId});
  Future<void> signOut();
}

class AuthRepository implements AuthApi {
  AuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signUp({required String email, required String password}) {
    return _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle({required String serverClientId}) async {
    if (serverClientId.isEmpty) {
      throw const AuthException('Google sign-in is not configured yet.');
    }
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(serverClientId: serverClientId);
      _googleReady = true;
    }
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Google did not return a sign-in token.');
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return;
      throw AuthException(error.description ?? 'Google sign-in failed.');
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

bool _googleReady = false;
