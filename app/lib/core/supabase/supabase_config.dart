/// Public client config from `--dart-define` or `--dart-define-from-file`.
///
/// Local URL is the default. The anon key is not stored in git (the commit
/// hook treats any JWT as a secret). Copy `dart_defines.example.json` to
/// `dart_defines.local.json` and paste the anon key from `supabase status`.
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:54321',
);

const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Web OAuth client id. Empty until `GOOGLE_WEB_CLIENT_ID` is set. The secret stays on the server.
const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// Throws when a launch config left the URL or anon key blank.
void assertSupabaseConfig() {
  final urlOk = supabaseUrl.startsWith('http://') || supabaseUrl.startsWith('https://');
  if (!urlOk || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Set SUPABASE_URL and SUPABASE_ANON_KEY (see app/dart_defines.example.json).',
    );
  }
}
