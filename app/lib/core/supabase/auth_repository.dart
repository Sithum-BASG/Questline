import 'package:supabase_flutter/supabase_flutter.dart';

/// Email and password auth. Google sign-in is added on the welcome screen.
abstract class AuthApi {
  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
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
  Future<void> signOut() => _client.auth.signOut();
}
