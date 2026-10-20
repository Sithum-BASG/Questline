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
      return '/onboarding/first-task';
    case 'first_task':
      return '/onboarding/first-task';
    case 'first_session':
      return '/onboarding/chest';
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
  if (onboardingStep == 'first_session' &&
      (location.startsWith('/focus') ||
          location.startsWith('/reward') ||
          location.startsWith('/chests') ||
          location == '/onboarding/chest')) {
    return null;
  }
  return location == target ? null : target;
}
