import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('function errors map to friendly text', () {
    final error = mapFunctionError(
      const FunctionException(
        status: 401,
        details: {'code': 'unauthorized', 'message': 'Sign in required'},
      ),
    );
    expect(error.code, 'unauthorized');
    expect(error.message, 'Sign in to continue.');
  });

  test('a transport failure reads as offline', () {
    final error = mapFunctionError(const FunctionsFetchException());
    expect(error.code, 'network');
    expect(error.message, contains('offline'));
  });
}
