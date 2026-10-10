/// Where the app should send the user from the current location.
/// Loading keeps the current screen. A signed-in player goes home until
/// onboarding resume is wired to `player_state.onboarding_step`.
String? authRedirect({
  required bool loading,
  required bool signedIn,
  required String location,
}) {
  if (loading) return null;
  final onWelcome = location == '/welcome';
  if (!signedIn && !onWelcome) return '/welcome';
  if (signedIn && onWelcome) return '/home';
  return null;
}
