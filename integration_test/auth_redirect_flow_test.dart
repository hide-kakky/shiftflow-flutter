import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:shiftflow_flutter/core/providers/core_providers.dart';
import 'package:shiftflow_flutter/features/shared/session_providers.dart';

import '../test/support/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('未ログイン時は auth へリダイレクトされる', (tester) async {
    final authHarness = TestSupabaseAuthHarness(loggedIn: false);
    final repo = TestRouteDataRepository();
    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(authHarness.client),
        routeDataRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(authHarness.dispose);

    await pumpShiftFlowApp(tester, container: container);
    await tester.pumpAndSettle();

    expect(find.text('ログイン'), findsOneWidget);
    expect(
      find.text('Supabase Auth の Magic Link でログインします。'),
      findsOneWidget,
    );
  });

  testWidgets('認証済みなら home が表示される', (tester) async {
    final authHarness = TestSupabaseAuthHarness(loggedIn: true);
    final repo = TestRouteDataRepository(
      homeContent: const {
        'overview': {
          'openTaskCount': 4,
          'unreadMessageCount': 2,
          'pendingUserCount': 1,
        },
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

    expect(find.text('対応中のタスク'), findsWidgets);
    expect(find.text('未読メッセージ'), findsWidgets);
  });

  testWidgets('auth 状態変更で redirect が再評価される', (tester) async {
    final authHarness = TestSupabaseAuthHarness(loggedIn: false);
    final repo = TestRouteDataRepository(
      homeContent: const {
        'overview': {
          'openTaskCount': 1,
          'unreadMessageCount': 0,
          'pendingUserCount': 0,
        },
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
    expect(find.text('ログイン'), findsOneWidget);

    authHarness.setLoggedIn(true);
    await tester.pumpAndSettle();

    expect(find.text('対応中のタスク'), findsWidgets);
  });
}
