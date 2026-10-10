import 'package:freezed_annotation/freezed_annotation.dart';

part 'inbox_message.freezed.dart';
part 'inbox_message.g.dart';

@freezed
abstract class InboxMessage with _$InboxMessage {
  const factory InboxMessage({
    required String id,
    required String userId,
    required String type,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _InboxMessage;

  factory InboxMessage.fromJson(Map<String, dynamic> json) =>
      _$InboxMessageFromJson(json);
}
