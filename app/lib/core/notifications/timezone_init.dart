import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Loads the timezone database and sets the local location from the device.
Future<String> initTimeZones() async {
  tz_data.initializeTimeZones();
  String name;
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    name = info.identifier;
  } catch (_) {
    name = 'UTC';
  }
  try {
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    tz.setLocalLocation(tz.UTC);
    name = 'UTC';
  }
  return name;
}
