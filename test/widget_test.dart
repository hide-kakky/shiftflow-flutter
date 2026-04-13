import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shiftflow_flutter/core/providers/core_providers.dart';
import 'package:shiftflow_flutter/features/admin/admin_screen.dart';
import 'package:shiftflow_flutter/features/auth/application/auth_controller.dart';
import 'package:shiftflow_flutter/features/auth/presentation/auth_screen.dart';
import 'package:shiftflow_flutter/features/home/home_screen.dart';
import 'package:shiftflow_flutter/features/messages/messages_screen.dart';
import 'package:shiftflow_flutter/features/settings/settings_screen.dart';
import 'package:shiftflow_flutter/features/shared/session_providers.dart';
import 'package:shiftflow_flutter/features/tasks/tasks_screen.dart';
import 'package:shiftflow_flutter/l10n/generated/app_localizations.dart';
import 'support/test_harness.dart';

class _TestAuthController extends AuthController {
  _TestAuthController() : super(TestSupabaseAuthHarness().client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'AuthScreen shows validation message when email and password are empty',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith((ref) => _TestAuthController()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ja'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ja'), Locale('en')],
            home: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('パスワードでログイン'));
      await tester.pump();

      expect(find.text('メールアドレスとパスワードを入力してください。'), findsOneWidget);
    },
  );

  testWidgets('HomeScreen renders overview metrics from repository', (
    tester,
  ) async {
    final repo = TestRouteDataRepository(
      homeContent: const {
        'overview': {
          'openTaskCount': 4,
          'unreadMessageCount': 2,
          'pendingUserCount': 1,
        },
      },
      bootstrapData: const {},
    );
    final container = ProviderContainer(
      overrides: [routeDataRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await pumpTestScreen(
      tester,
      container: container,
      child: const HomeScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('対応中のタスク'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.text('未読メッセージ'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('保留中ユーザー'), findsWidgets);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('MessagesScreen updates read icon after toggle action', (
    tester,
  ) async {
    final repo = TestRouteDataRepository(
      messages: const [
        {
          'id': 'message-1',
          'title': '朝会',
          'body': '本日の共有事項',
          'isRead': false,
          'is_pinned': true,
        },
      ],
      toggleReadResponse: const {'isRead': true},
    );
    final container = ProviderContainer(
      overrides: [routeDataRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await pumpTestScreen(
      tester,
      container: container,
      child: const MessagesScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();

    expect(repo.toggledMessageIds, ['message-1']);
    expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
  });

  testWidgets('MessagesScreen filters by folder and unread only', (
    tester,
  ) async {
    final repo = TestRouteDataRepository(
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
    final container = ProviderContainer(
      overrides: [routeDataRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await pumpTestScreen(
      tester,
      container: container,
      child: const MessagesScreen(),
    );
    await tester.pumpAndSettle();

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
  });

  testWidgets('TasksScreen switches scope between My, Created, All', (
    tester,
  ) async {
    final repo = TestRouteDataRepository(
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
      overrides: [routeDataRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await pumpTestScreen(
      tester,
      container: container,
      child: const TasksScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('My task'), findsOneWidget);
    expect(repo.listMyTasksCalls, greaterThanOrEqualTo(1));

    await tester.tap(find.text('Created'));
    await tester.pumpAndSettle();
    expect(find.text('Created task'), findsOneWidget);
    expect(repo.listCreatedTasksCalls, greaterThanOrEqualTo(1));

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('All task'), findsOneWidget);
    expect(repo.listAllTasksCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('SettingsScreen saves profile, language and theme', (
    tester,
  ) async {
    final repo = TestRouteDataRepository(
      userSettings: const {
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
        routeDataRepositoryProvider.overrideWithValue(repo),
        userSettingsProvider.overrideWith((ref) async => repo.userSettings),
      ],
    );
    addTearDown(container.dispose);

    await pumpTestScreen(
      tester,
      container: container,
      child: const SettingsScreen(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '山田 太郎');
    await tester.tap(find.text('プロフィールを保存'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<ThemeMode>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(repo.savedNames, ['山田 太郎']);
    expect(container.read(localeProvider).languageCode, 'en');
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(repo.savedLanguages, ['en']);
    expect(repo.savedThemes, ['dark']);
    expect(prefs.getString('app_locale'), 'en');
    expect(prefs.getString('theme_mode'), 'dark');
  });

  testWidgets('AdminScreen shows permission denied for non managers', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [isManagerOrAdminProvider.overrideWith((ref) => false)],
    );
    addTearDown(container.dispose);

    await pumpTestScreen(
      tester,
      container: container,
      child: const AdminScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('権限がありません。'), findsOneWidget);
  });
}
