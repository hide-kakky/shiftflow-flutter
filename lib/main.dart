import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/notifications/notification_permission_service.dart';
import 'features/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppEnv.validate();

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
  await NotificationPermissionService.requestIfNeeded();

  final prefs = await SharedPreferences.getInstance();
  final locale = prefs.getString('app_locale') ?? 'ja';
  final themeMode = prefs.getString('theme_mode') ?? 'system';

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((_) => Locale(locale)),
        themeModeProvider.overrideWith(
          (_) => switch (themeMode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
        ),
      ],
      child: const ShiftFlowApp(),
    ),
  );
}
