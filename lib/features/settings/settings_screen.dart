import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/session_providers.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('ja'));
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(userSettingsProvider).valueOrNull ?? const {};
    final role = settings['role']?.toString() ?? 'guest';
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text(l10n.role),
            subtitle: Text(role),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(l10n.language),
            subtitle: Text(locale.languageCode),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              items: const [
                DropdownMenuItem(value: 'ja', child: Text('日本語')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                ref.read(localeProvider.notifier).state = Locale(value);
                final prefs = await ref.read(sharedPreferencesProvider.future);
                await prefs.setString('app_locale', value);
                await ref
                    .read(routeDataRepositoryProvider)
                    .saveUserSettings(language: value);
              },
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(l10n.theme),
            subtitle: Text(themeMode.name),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                ref.read(themeModeProvider.notifier).state = value;
                final prefs = await ref.read(sharedPreferencesProvider.future);
                await prefs.setString('theme_mode', value.name);
                await ref
                    .read(routeDataRepositoryProvider)
                    .saveUserSettings(theme: value.name);
              },
            ),
          ),
        ),
      ],
    );
  }
}
