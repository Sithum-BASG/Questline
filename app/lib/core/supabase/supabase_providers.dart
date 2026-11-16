import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in Supabase client. Overridden in `main` after `Supabase.initialize`.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  throw StateError('Supabase is not initialised. Override supabaseClientProvider in main.');
});

/// Id of the signed-in user, or null when signed out. Emits only when the
/// account changes (sign-in, sign-out, switching accounts), not on token refresh.
/// Read it through [watchAccount].
final signedInUserIdProvider = StreamProvider<String?>((ref) {
  final auth = ref.watch(supabaseClientProvider).auth;
  return auth.onAuthStateChange.map((state) => state.session?.user.id).distinct();
});

/// Ties a provider to the signed-in account: it re-runs when a different
/// account signs in or out (not on token refresh). Every provider that reads
/// the user's own data calls this first, so switching accounts never shows the
/// previous account's data.
void watchAccount(Ref ref) {
  ref.watch(signedInUserIdProvider.select((id) => id.asData?.value));
}

/// Auth changes for the current client, including the initial session.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});
