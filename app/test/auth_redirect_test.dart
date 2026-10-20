import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/auth_redirect.dart';

void main() {
  test('a signed-out player is sent to welcome', () {
    expect(
      authRedirect(loading: false, signedIn: false, location: '/home'),
      '/welcome',
    );
    expect(
      authRedirect(loading: false, signedIn: false, location: '/welcome'),
      isNull,
    );
  });

  test('a new account stays on welcome until the player row exists', () {
    expect(
      authRedirect(loading: false, signedIn: true, location: '/welcome', onboardingStep: null),
      isNull,
    );
  });

  test('onboarding resumes at the step the server stored', () {
    expect(routeForOnboardingStep('signed_in'), '/onboarding/character');
    expect(routeForOnboardingStep('character'), '/onboarding/story');
    expect(routeForOnboardingStep('story'), '/onboarding/study');
    expect(routeForOnboardingStep('study'), '/onboarding/first-task');
    expect(routeForOnboardingStep('first_task'), '/onboarding/first-task');
    expect(routeForOnboardingStep('first_session'), '/onboarding/first-session');
    expect(routeForOnboardingStep('done'), '/home');
    expect(
      authRedirect(
        loading: false,
        signedIn: true,
        location: '/home',
        onboardingStep: 'signed_in',
      ),
      '/onboarding/character',
    );
  });

  test('auth loading does not redirect', () {
    expect(
      authRedirect(loading: true, signedIn: false, location: '/home'),
      isNull,
    );
  });
}
