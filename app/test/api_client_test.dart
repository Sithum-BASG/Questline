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

  test('a transport failure reads as server waking up', () {
    final error = mapFunctionError(const FunctionsFetchException());
    expect(error.code, 'network');
    expect(error.message, contains('waking up'));
  });

  test('unavailable keeps the server message', () {
    final error = mapFunctionError(
      const FunctionException(
        status: 503,
        details: {
          'code': 'unavailable',
          'message': 'AI judge resting until tomorrow; saved as provisional',
        },
      ),
    );
    expect(error.code, 'unavailable');
    expect(error.message, contains('resting until tomorrow'));
  });
}
