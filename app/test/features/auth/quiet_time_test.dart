import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/auth/settings_screen.dart';

void main() {
  test('parseQuietTime reads HH:MM:SS from Postgres', () {
    expect(parseQuietTime('23:00:00'), const TimeOfDay(hour: 23, minute: 0));
    expect(parseQuietTime('07:30'), const TimeOfDay(hour: 7, minute: 30));
  });

  test('formatQuietTime writes HH:MM:SS for user_settings', () {
    expect(formatQuietTime(const TimeOfDay(hour: 23, minute: 0)), '23:00:00');
    expect(formatQuietTime(const TimeOfDay(hour: 7, minute: 5)), '07:05:00');
  });
}
