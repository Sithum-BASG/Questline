import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/notifications/local_notifications.dart';
import 'core/notifications/timezone_init.dart';
import 'core/supabase/supabase_config.dart';
import 'core/supabase/supabase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initTimeZones();
  assertSupabaseConfig();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  final notifications = LocalNotifications(FlutterLocalNotificationsPlugin());
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(Supabase.instance.client),
        localNotificationsProvider.overrideWithValue(notifications),
      ],
      child: const QuestlineApp(),
    ),
  );
}
