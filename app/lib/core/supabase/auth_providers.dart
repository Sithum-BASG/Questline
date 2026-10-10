import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'supabase_providers.dart';

final authRepositoryProvider = Provider<AuthApi>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
