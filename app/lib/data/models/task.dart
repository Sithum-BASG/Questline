import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String userId,
    required String title,
    String? notes,
    DateTime? dueAt,
    DateTime? originalDueAt,
    String? bossId,
    String? raidId,
    required String status,
    required bool rescheduled,
    required bool scrollUsed,
    required DateTime createdAt,
    String? stat,
    int? difficulty,
    int? estMinutes,
    bool? tooBig,
    String? reason,
    required bool provisional,
    required bool challenged,
    DateTime? judgedAt,
    String? completionMode,
    int? completionMinutes,
    DateTime? completedAt,
    DateTime? completionDay,
    int? xpRaw,
    int? xpFinal,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
