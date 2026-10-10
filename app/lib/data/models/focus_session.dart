import 'package:freezed_annotation/freezed_annotation.dart';

part 'focus_session.freezed.dart';
part 'focus_session.g.dart';

@freezed
abstract class FocusSession with _$FocusSession {
  const factory FocusSession({
    required String id,
    required String userId,
    required String taskId,
    required String mode,
    required DateTime startedAt,
    DateTime? endedAt,
    required List<dynamic> interruptions,
    required int interruptionSeconds,
    int? verifiedMinutes,
    required String status,
    required bool potion,
    required bool demo,
    required bool processed,
    Map<String, dynamic>? summary,
  }) = _FocusSession;

  factory FocusSession.fromJson(Map<String, dynamic> json) =>
      _$FocusSessionFromJson(json);
}
