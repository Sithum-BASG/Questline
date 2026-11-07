/// Deep-link helpers for party raid invite codes (`questline://join/{code}`).
String raidInviteUri(String code) => 'questline://join/$code';

String raidInviteShareText(String code) {
  return 'Join my Questline raid with code $code (or open ${raidInviteUri(code)}).';
}

String? raidCodeFromUri(Uri uri) {
  if (uri.scheme != 'questline') return null;
  if (uri.host == 'join' && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first.toUpperCase();
  }
  if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'join') {
    return uri.pathSegments[1].toUpperCase();
  }
  return null;
}
