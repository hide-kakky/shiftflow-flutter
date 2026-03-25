import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shiftflow_flutter/core/api/api_client.dart';
import 'package:shiftflow_flutter/core/providers/core_providers.dart';
import 'package:shiftflow_flutter/features/admin/admin_screen.dart';
import 'package:shiftflow_flutter/features/auth/application/auth_controller.dart';
import 'package:shiftflow_flutter/features/auth/presentation/auth_screen.dart';
import 'package:shiftflow_flutter/features/home/home_screen.dart';
import 'package:shiftflow_flutter/features/messages/messages_screen.dart';
import 'package:shiftflow_flutter/features/settings/settings_screen.dart';
import 'package:shiftflow_flutter/features/shared/route_data_repository.dart';
import 'package:shiftflow_flutter/features/shared/session_providers.dart';
import 'package:shiftflow_flutter/l10n/generated/app_localizations.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _TestAuthController extends AuthController {
  _TestAuthController() : super(_MockSupabaseClient());
}

class _FakeRouteDataRepository extends RouteDataRepository {
  _FakeRouteDataRepository({
    this.homeContent = const <String, dynamic>{},
    this.userSettings = const <String, dynamic>{
      'name': 'Tester',
      'role': 'member',
      'theme': 'system',
      'language': 'ja',
      'email': 'tester@example.com',
    },
    this.bootstrapData = const <String, dynamic>{},
    List<Map<String, dynamic>>? messages,
    this.toggleReadResponse = const <String, dynamic>{'isRead': true},
  })  : _messages = List<Map<String, dynamic>>.from(messages ?? const []),
        super(ApiClient(_MockSupabaseClient()));

  final Map<String, dynamic> homeContent;
  final Map<String, dynamic> userSettings;
  final Map<String, dynamic> bootstrapData;
  final Map<String, dynamic> toggleReadResponse;
  final List<Map<String, dynamic>> _messages;

  final List<String> savedLanguages = <String>[];
  final List<String> savedThemes = <String>[];
  final List<String> toggledMessageIds = <String>[];

  @override
  Future<Map<String, dynamic>> getHomeContent() async => homeContent;

  @override
  Future<Map<String, dynamic>> getUserSettings() async => userSettings;

  @override
  Future<Map<String, dynamic>> saveUserSettings({
    String? name,
    String? theme,
    String? language,
  }) async {
    if (language != null) {
      savedLanguages.add(language);
    }
    if (theme != null) {
      savedThemes.add(theme);
    }
    return {
      ...userSettings,
      ...?name == null ? null : {'name': name},
      ...?theme == null ? null : {'theme': theme},
      ...?language == null ? null : {'language': language},
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages({String? folderId}) async {
    return List<Map<String, dynamic>>.from(_messages);
  }

  @override
  Future<Map<String, dynamic>> toggleMemoRead(String messageId) async {
    toggledMessageIds.add(messageId);
    return toggleReadResponse;
  }

  @override
  Future<Map<String, dynamic>> getBootstrapData() async => bootstrapData;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget child,
}) async {
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
        supportedLocales: const [
          Locale('ja'),
          Locale('en'),
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('AuthScreen shows validation message when email and password are empty', (
    tester,
  ) async {
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
          supportedLocales: const [
            Locale('ja'),
            Locale('en'),
          ],
          home: const AuthScreen(),
        ),
      ),
    );

    await tester.tap(find.text('パスワードでログイン'));
    await tester.pump();

    expect(find.text('メールアドレスとパスワードを入力してください。'), findsOneWidget);
  });

  testWidgets('HomeScreen renders overview metrics from repository', (tester) async {
    final repo = _FakeRouteDataRepository(
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
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container: container,
      child: const HomeScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open Tasks'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Unread Messages'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Pending Users'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('MessagesScreen updates read icon after toggle action', (tester) async {
    final repo = _FakeRouteDataRepository(
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
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
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

  testWidgets('SettingsScreen saves selected language and theme', (tester) async {
    final repo = _FakeRouteDataRepository(
      userSettings: const {
        'name': 'Tester',
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

    await _pumpScreen(
      tester,
      container: container,
      child: const SettingsScreen(),
    );
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
    expect(container.read(localeProvider).languageCode, 'en');
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(repo.savedLanguages, ['en']);
    expect(repo.savedThemes, ['dark']);
    expect(prefs.getString('app_locale'), 'en');
    expect(prefs.getString('theme_mode'), 'dark');
  });

  testWidgets('AdminScreen shows permission denied for non managers', (tester) async {
    final container = ProviderContainer(
      overrides: [
        isManagerOrAdminProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container: container,
      child: const AdminScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('権限がありません。'), findsOneWidget);
  });
}
