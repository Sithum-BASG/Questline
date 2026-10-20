import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/auth_redirect.dart';
import 'package:questline/features/onboarding/onboarding_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('after first session the free-chest route is allowed', () {
    expect(
      authRedirect(
        loading: false,
        signedIn: true,
        location: '/onboarding/chest',
        onboardingStep: 'first_session',
      ),
      isNull,
    );
    expect(
      authRedirect(
        loading: false,
        signedIn: true,
        location: '/reward',
        onboardingStep: 'first_session',
      ),
      isNull,
    );
  });

  test('pending onboarding chest flag defaults to false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(pendingOnboardingChestProvider), isFalse);
    container.read(pendingOnboardingChestProvider.notifier).setPending(true);
    expect(container.read(pendingOnboardingChestProvider), isTrue);
  });
}
