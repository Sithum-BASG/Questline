import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'auth_repository.dart';
import 'supabase_providers.dart';

final authRepositoryProvider = Provider<AuthApi>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

typedef CompleteOnboarding = Future<void> Function(String step, {Map<String, dynamic>? data});

final completeOnboardingProvider = Provider<CompleteOnboarding>((ref) {
  return (step, {data}) => ref.read(apiClientProvider).completeOnboardingStep(step, data: data);
});

/// `player_state.onboarding_step` for the signed-in user, or null when the row does not exist yet.
final onboardingStepProvider = FutureProvider<String?>((ref) async {
  final auth = ref.watch(authStateProvider);
  final userId = auth.asData?.value.session?.user.id;
  if (userId == null) return null;
  final row = await ref.watch(supabaseClientProvider)
      .from('player_state')
      .select('onboarding_step')
      .eq('user_id', userId)
      .maybeSingle();
  final step = row?['onboarding_step'];
  return step is String ? step : null;
});
