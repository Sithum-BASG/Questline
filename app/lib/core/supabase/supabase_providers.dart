import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in Supabase client. Overridden in `main` after `Supabase.initialize`.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  throw StateError('Supabase is not initialised. Override supabaseClientProvider in main.');
});

/// Auth changes for the current client, including the initial session.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});
