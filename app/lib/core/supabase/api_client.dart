import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_providers.dart';

/// Failure from an Edge Function, with a short message safe to show.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}

class StartSessionResult {
  const StartSessionResult({required this.sessionId, required this.startedAt, required this.capMinutes});

  final String sessionId;
  final DateTime startedAt;
  final int capMinutes;
}

class HelloResult {
  const HelloResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

/// Maps `{ code, message }` from a function onto friendly copy.
ApiException mapFunctionError(FunctionException error) {
  final details = error.details;
  var code = 'internal';
  var raw = error.reasonPhrase ?? 'Something went wrong';
  if (details is Map) {
    final parsedCode = details['code'];
    final parsedMessage = details['message'];
    if (parsedCode is String && parsedCode.isNotEmpty) code = parsedCode;
    if (parsedMessage is String && parsedMessage.isNotEmpty) raw = parsedMessage;
  } else if (error.status == 0) {
    code = 'network';
    raw = 'The server could not be reached';
  }
  return ApiException(code: code, message: friendlyApiMessage(code, raw));
}

String friendlyApiMessage(String code, String raw) {
  switch (code) {
    case 'unauthorized':
      return 'Sign in to continue.';
    case 'not_found':
      return 'That could not be found.';
    case 'invalid_argument':
      return raw;
    case 'network':
      return 'You are offline. Try again when you are back online.';
    default:
      return 'Something went wrong. Try again.';
  }
}

/// Typed Edge Function calls. One method per action.
class ApiClient {
  ApiClient(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> invoke(
    String function,
    String action, [
    Map<String, dynamic> body = const {},
  ]) async {
    try {
      final response = await _client.functions.invoke(
        function,
        body: {'action': action, ...body},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const {'ok': true};
    } on FunctionException catch (error) {
      throw mapFunctionError(error);
    }
  }

  Future<HelloResult> hello() async {
    final json = await invoke('account', 'hello');
    return HelloResult(
      ok: json['ok'] == true,
      message: json['message'] is String ? json['message'] as String : '',
    );
  }

  Future<Map<String, dynamic>> judgeTask(String taskId) {
    return invoke('tasks', 'judgeTask', {'taskId': taskId});
  }

  Future<Map<String, dynamic>> challengeTask(String taskId, String context) {
    return invoke('tasks', 'challengeTask', {'taskId': taskId, 'context': context});
  }

  Future<Map<String, dynamic>> rescheduleTask(String taskId, String newDueAt, {bool useScroll = false}) {
    return invoke('tasks', 'rescheduleTask', {
      'taskId': taskId,
      'newDueAt': newDueAt,
      'useScroll': useScroll,
    });
  }

  Future<StartSessionResult> startSession({
    required String taskId,
    required String mode,
    bool usePotion = false,
  }) async {
    final json = await invoke('sessions', 'startSession', {
      'taskId': taskId,
      'mode': mode,
      'usePotion': usePotion,
    });
    return StartSessionResult(
      sessionId: json['sessionId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      capMinutes: (json['capMinutes'] as num).round(),
    );
  }

  Future<Map<String, dynamic>> endSession(
    String sessionId,
    List<Map<String, String>> interruptions, {
    bool broken = false,
  }) {
    return invoke('sessions', 'endSession', {
      'sessionId': sessionId,
      'interruptions': interruptions,
      'broken': broken,
    });
  }

  Future<void> completeOnboardingStep(String step, {Map<String, dynamic>? data}) {
    return invoke('account', 'completeOnboardingStep', {
      'step': step,
      'data': ?data,
    });
  }

  Future<Map<String, dynamic>> openChest({
    required String requestId,
    bool useFreeChest = false,
  }) {
    return invoke('loot', 'openChest', {
      'requestId': requestId,
      'useFreeChest': useFreeChest,
    });
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(supabaseClientProvider));
});
