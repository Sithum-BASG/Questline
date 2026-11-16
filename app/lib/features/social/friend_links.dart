/// Deep-link helpers for friend codes (`questline://friend/{code}`).
String friendInviteUri(String friendCode) => 'questline://friend/$friendCode';

String friendInviteShareText(String friendCode) {
  return 'Add me on Questline with code $friendCode (or open ${friendInviteUri(friendCode)}).';
}

final _plainCode = RegExp(r'^[A-Za-z0-9]{8}$');

String? friendCodeFromUri(Uri uri) {
  if (uri.scheme != 'questline') return null;
  final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  if (uri.host == 'friend' && segments.isNotEmpty) {
    return segments.first.toUpperCase();
  }
  // questline:///friend/CODE and questline://friend/CODE both appear in the wild.
  if (segments.length >= 2 && segments.first == 'friend') {
    return segments[1].toUpperCase();
  }
  return null;
}

/// Friend code from scanned QR text: an invite link or a bare 8-character code.
String? friendCodeFromScan(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  final fromLink = uri == null ? null : friendCodeFromUri(uri);
  if (fromLink != null) return _plainCode.hasMatch(fromLink) ? fromLink : null;
  final bare = text.replaceAll('-', '').replaceAll(' ', '');
  return _plainCode.hasMatch(bare) ? bare.toUpperCase() : null;
}
