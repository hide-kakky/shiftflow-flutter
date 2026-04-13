import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shiftflow_flutter/core/providers/core_providers.dart';
import 'package:shiftflow_flutter/features/settings/settings_screen.dart';
import 'package:shiftflow_flutter/features/shared/session_providers.dart';

import '../test/support/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Settings で表示名と言語とテーマを保存できる', (tester) async {
    final authHarness = TestSupabaseAuthHarness(loggedIn: true);
    final repo = TestRouteDataRepository(
      homeContent: const {
        'overview': {
          'openTaskCount': 1,
          'unreadMessageCount': 1,
          'pendingUserCount': 0,
        },
      },
      userSettings: const {
        'userId': 'user-1',
        'name': 'Tester',
        'imageUrl': '',
        'role': 'member',
        'theme': 'system',
        'language': 'ja',
        'email': 'tester@example.com',
      },
    );
    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(authHarness.client),
        routeDataRepositoryProvider.overrideWithValue(repo),
        userSettingsProvider.overrideWith((ref) async => repo.userSettings),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(authHarness.dispose);

    await pumpShiftFlowApp(tester, container: container);
    await tester.pumpAndSettle();
    await _openSettingsScreen(tester);

    await tester.enterText(find.byType(TextField).first, '山田 太郎');
    await tester.tap(find.text('プロフィールを保存'));
    await tester.pumpAndSettle();

    await _selectLanguage(tester, 'English');

    await _selectTheme(tester, 'Dark');

    final prefs = await SharedPreferences.getInstance();

    expect(repo.savedNames, ['山田 太郎']);
    expect(repo.savedLanguages, ['en']);
    expect(repo.savedThemes, ['dark']);
    expect(container.read(localeProvider).languageCode, 'en');
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString('app_locale'), 'en');
    expect(prefs.getString('theme_mode'), 'dark');
  });
}

Future<void> _openSettingsScreen(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined).hitTestable().last);
  await tester.pumpAndSettle();

  expect(find.text('プロフィールを保存'), findsOneWidget);
}

Future<void> _selectLanguage(WidgetTester tester, String optionText) async {
  final dropdown = find.byType(DropdownButton<String>).first;
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown.hitTestable().first);
  await tester.pumpAndSettle();

  final option = find.text(optionText).last;
  expect(option, findsOneWidget);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _selectTheme(WidgetTester tester, String optionText) async {
  final dropdown = find.byType(DropdownButton<ThemeMode>).first;
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown.hitTestable().first);
  await tester.pumpAndSettle();

  final option = find.text(optionText).last;
  expect(option, findsOneWidget);
  await tester.tap(option);
  await tester.pumpAndSettle();
}
