/// Deep-link helpers for friend codes (`questline://friend/{code}`).
String friendInviteUri(String friendCode) => 'questline://friend/$friendCode';

String friendInviteShareText(String friendCode) {
  return 'Add me on Questline with code $friendCode (or open ${friendInviteUri(friendCode)}).';
}

String? friendCodeFromUri(Uri uri) {
  if (uri.scheme != 'questline') return null;
  if (uri.host == 'friend' && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first.toUpperCase();
  }
  // questline:///friend/CODE and questline://friend/CODE both appear in the wild.
  if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'friend') {
    return uri.pathSegments[1].toUpperCase();
  }
  return null;
}
