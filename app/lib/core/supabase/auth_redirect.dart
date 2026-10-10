/// Route for a signed-in player's onboarding step. `null` means the account
/// row does not exist yet, so welcome still has to call `signed_in`.
String routeForOnboardingStep(String? step) {
  switch (step) {
    case null:
      return '/welcome';
    case 'signed_in':
      return '/onboarding/character';
    case 'character':
      return '/onboarding/story';
    case 'story':
      return '/onboarding/study';
    case 'study':
    case 'first_task':
    case 'first_session':
      return '/onboarding/first-task';
    default:
      return '/home';
  }
}

/// Where the app should send the user. Loading keeps the current screen.
/// A finished player can move around the app. An unfinished one stays on their step.
String? authRedirect({
  required bool loading,
  required bool signedIn,
  required String location,
  String? onboardingStep,
  bool stepLoading = false,
}) {
  if (loading || (signedIn && stepLoading)) return null;
  if (!signedIn) return location == '/welcome' ? null : '/welcome';
  final target = routeForOnboardingStep(onboardingStep);
  if (target == '/home') return location == '/welcome' ? '/home' : null;
  return location == target ? null : target;
}
