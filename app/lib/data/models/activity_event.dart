import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_event.freezed.dart';
part 'activity_event.g.dart';

@freezed
abstract class ActivityEvent with _$ActivityEvent {
  const factory ActivityEvent({
    required String id,
    required String actorId,
    required String type,
    required Map<String, dynamic> payload,
    required List<String> visibleTo,
    required DateTime createdAt,
  }) = _ActivityEvent;

  factory ActivityEvent.fromJson(Map<String, dynamic> json) =>
      _$ActivityEventFromJson(json);
}
