import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:shiftflow_flutter/core/providers/core_providers.dart';
import 'package:shiftflow_flutter/features/shared/session_providers.dart';

import '../test/support/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tasks のスコープ切替が動作する', (tester) async {
    final authHarness = TestSupabaseAuthHarness(loggedIn: true);
    final repo = TestRouteDataRepository(
      homeContent: const {
        'overview': {
          'openTaskCount': 3,
          'unreadMessageCount': 1,
          'pendingUserCount': 0,
        },
      },
      myTasks: const [
        {
          'id': 'task-1',
          'title': 'My task',
          'status': 'open',
          'priority': 'medium',
        },
      ],
      createdTasks: const [
        {
          'id': 'task-2',
          'title': 'Created task',
          'status': 'open',
          'priority': 'high',
        },
      ],
      allTasks: const [
        {
          'id': 'task-3',
          'title': 'All task',
          'status': 'completed',
          'priority': 'low',
        },
      ],
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
    await _openTasksScreen(tester);

    expect(find.text('My task'), findsOneWidget);
    expect(repo.listMyTasksCalls, greaterThanOrEqualTo(1));

    await tester.tap(find.text('Created'));
    await tester.pumpAndSettle();

    expect(find.text('Created task'), findsOneWidget);
    expect(find.text('My task'), findsNothing);
    expect(repo.listCreatedTasksCalls, greaterThanOrEqualTo(1));

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('All task'), findsOneWidget);
    expect(find.text('Created task'), findsNothing);
    expect(repo.listAllTasksCalls, greaterThanOrEqualTo(1));
  });
}

Future<void> _openTasksScreen(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'タスク'));
  await tester.pumpAndSettle();

  expect(find.text('My'), findsOneWidget);
  expect(find.text('Created'), findsOneWidget);
  expect(find.text('All'), findsOneWidget);
}
