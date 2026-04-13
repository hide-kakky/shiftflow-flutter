import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:shiftflow_flutter/core/providers/core_providers.dart';
import 'package:shiftflow_flutter/features/shared/session_providers.dart';

import '../test/support/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Messages 一覧とフィルタが動作する', (tester) async {
    final authHarness = TestSupabaseAuthHarness(loggedIn: true);
    final repo = TestRouteDataRepository(
      homeContent: const {
        'overview': {
          'openTaskCount': 2,
          'unreadMessageCount': 2,
          'pendingUserCount': 0,
        },
      },
      folders: const [
        {'id': 'folder-1', 'name': '連絡'},
        {'id': 'folder-2', 'name': '運用'},
      ],
      messages: const [
        {
          'id': 'message-1',
          'title': '未読メッセージ',
          'body': '未読',
          'isRead': false,
          'folder_id': 'folder-1',
        },
        {
          'id': 'message-2',
          'title': '既読メッセージ',
          'body': '既読',
          'isRead': true,
          'folder_id': 'folder-1',
        },
        {
          'id': 'message-3',
          'title': '別フォルダ',
          'body': '未読',
          'isRead': false,
          'folder_id': 'folder-2',
        },
      ],
    );
    final container = _buildAuthenticatedContainer(authHarness, repo);
    addTearDown(container.dispose);
    addTearDown(authHarness.dispose);

    await pumpShiftFlowApp(tester, container: container);
    await tester.pumpAndSettle();
    await _openMessagesScreen(tester);

    expect(find.text('未読メッセージ'), findsOneWidget);
    expect(find.text('既読メッセージ'), findsOneWidget);
    expect(find.text('別フォルダ'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('連絡').last);
    await tester.pumpAndSettle();

    expect(find.text('未読メッセージ'), findsOneWidget);
    expect(find.text('既読メッセージ'), findsOneWidget);
    expect(find.text('別フォルダ'), findsNothing);

    await tester.tap(find.text('未読のみ'));
    await tester.pumpAndSettle();

    expect(find.text('未読メッセージ'), findsOneWidget);
    expect(find.text('既読メッセージ'), findsNothing);
    expect(repo.requestedFolderIds, contains('folder-1'));
    expect(repo.requestedUnreadOnly, contains(true));
  });

  testWidgets('既読切替で UI と repository 呼び出しが更新される', (tester) async {
    final authHarness = TestSupabaseAuthHarness(loggedIn: true);
    final repo = TestRouteDataRepository(
      homeContent: const {
        'overview': {
          'openTaskCount': 1,
          'unreadMessageCount': 1,
          'pendingUserCount': 0,
        },
      },
      folders: const [
        {'id': 'folder-1', 'name': '連絡'},
        {'id': 'folder-2', 'name': '運用'},
      ],
      messages: const [
        {
          'id': 'message-1',
          'title': '未読メッセージ',
          'body': '本日の共有事項',
          'isRead': false,
          'folder_id': 'folder-1',
        },
      ],
      toggleReadResponse: const {'isRead': true},
    );
    final container = _buildAuthenticatedContainer(authHarness, repo);
    addTearDown(container.dispose);
    addTearDown(authHarness.dispose);

    await pumpShiftFlowApp(tester, container: container);
    await tester.pumpAndSettle();
    await _openMessagesScreen(tester);

    expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();

    expect(repo.toggledMessageIds, ['message-1']);
    expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
  });
}

ProviderContainer _buildAuthenticatedContainer(
  TestSupabaseAuthHarness authHarness,
  TestRouteDataRepository repo,
) {
  return ProviderContainer(
    overrides: [
      supabaseClientProvider.overrideWithValue(authHarness.client),
      routeDataRepositoryProvider.overrideWithValue(repo),
      userSettingsProvider.overrideWith((ref) async => repo.userSettings),
    ],
  );
}

Future<void> _openMessagesScreen(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'メッセージ'));
  await tester.pumpAndSettle();

  expect(find.text('未読のみ'), findsOneWidget);
}
