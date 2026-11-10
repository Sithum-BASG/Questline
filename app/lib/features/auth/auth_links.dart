/// True when [uri] is the email auth / password-reset callback.
bool isAuthCallbackUri(Uri uri) {
  if (uri.scheme != 'questline') return false;
  final host = uri.host.toLowerCase();
  if (host == 'auth-callback') return true;
  // questline:///auth-callback
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  return segments.length == 1 && segments.first.toLowerCase() == 'auth-callback';
}
