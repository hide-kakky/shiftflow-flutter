import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shiftflow_flutter/core/api/api_client.dart';
import 'package:shiftflow_flutter/core/providers/core_providers.dart';
import 'package:shiftflow_flutter/features/shared/route_data_repository.dart';
import 'package:shiftflow_flutter/features/shell/app_router.dart';
import 'package:shiftflow_flutter/l10n/generated/app_localizations.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockSession extends Mock implements Session {}

class _FakeRouteDataRepository extends RouteDataRepository {
  _FakeRouteDataRepository({
    this.bootstrapData = const {
      'participation': {
        'status': 'active',
        'canUseApp': true,
        'organizationRole': 'member',
        'unitRole': 'member',
      },
      'currentOrganization': {'id': 'org-1', 'name': 'ShiftFlow Cafe'},
      'currentUnit': {'id': 'unit-1', 'name': '本部'},
      'availableOrganizations': [],
      'availableUnits': [],
      'navigation': {
        'home': true,
        'tasks': true,
        'messages': true,
        'admin': false,
        'settings': true,
      },
      'badges': {
        'allUnreadMessages': 1,
        'currentUnitUnreadMessages': 1,
        'openTasks': 2,
        'pendingJoinRequests': 0,
      },
      'overview': {
        'openTaskCount': 2,
        'unreadMessageCount': 1,
        'pendingUserCount': 0,
      },
    },
  }) : super(ApiClient(_MockSupabaseClient()));

  final Map<String, dynamic> bootstrapData;

  @override
  Future<Map<String, dynamic>> getHomeContent() async {
    return const {
      'overview': {
        'openTaskCount': 2,
        'unreadMessageCount': 1,
        'pendingUserCount': 0,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getUserSettings() async {
    return const {
      'userId': 'user-1',
      'name': 'Tester',
      'role': 'member',
      'theme': 'system',
      'language': 'ja',
      'email': 'tester@example.com',
    };
  }

  @override
  Future<Map<String, dynamic>> getBootstrapData() async => bootstrapData;
}

Future<void> _pumpRouter(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('ja'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja'), Locale('en')],
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('redirects unauthenticated users to /auth', (tester) async {
    final client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentSession).thenReturn(null);
    when(() => auth.currentUser).thenReturn(null);
    when(
      () => auth.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        routeDataRepositoryProvider.overrideWithValue(
          _FakeRouteDataRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpRouter(tester, container: container);
    await tester.pumpAndSettle();

    expect(find.text('ログイン'), findsOneWidget);
  });

  testWidgets('redirects authenticated users from /auth to /home', (
    tester,
  ) async {
    final client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    final session = _MockSession();
    final user = _MockUser();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentSession).thenReturn(session);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.email).thenReturn('tester@example.com');
    when(
      () => auth.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        routeDataRepositoryProvider.overrideWithValue(
          _FakeRouteDataRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpRouter(tester, container: container);
    await tester.pumpAndSettle();

    expect(find.text('対応中のタスク'), findsWidgets);
  });

  testWidgets('redirects authenticated pending users to /participation', (
    tester,
  ) async {
    final client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    final session = _MockSession();
    final user = _MockUser();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentSession).thenReturn(session);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.email).thenReturn('tester@example.com');
    when(
      () => auth.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        routeDataRepositoryProvider.overrideWithValue(
          _FakeRouteDataRepository(
            bootstrapData: const {
              'participation': {
                'status': 'pending',
                'canUseApp': false,
                'organizationRole': 'member',
                'unitRole': 'none',
              },
              'currentOrganization': {'id': 'org-1', 'name': 'ShiftFlow Cafe'},
              'availableOrganizations': [],
              'availableUnits': [],
              'navigation': {
                'home': false,
                'tasks': false,
                'messages': false,
                'admin': false,
                'settings': true,
              },
              'badges': {
                'allUnreadMessages': 0,
                'currentUnitUnreadMessages': 0,
                'openTasks': 0,
                'pendingJoinRequests': 0,
              },
              'overview': {
                'openTaskCount': 0,
                'unreadMessageCount': 0,
                'pendingUserCount': 0,
              },
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpRouter(tester, container: container);
    await tester.pumpAndSettle();

    expect(find.text('参加申請の承認待ちです'), findsOneWidget);
  });

  testWidgets('re-evaluates router when auth state changes', (tester) async {
    final client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    final user = _MockUser();
    final session = _MockSession();
    final authStateController = StreamController<AuthState>.broadcast();
    Session? currentSession;
    User? currentUser;

    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentSession).thenAnswer((_) => currentSession);
    when(() => auth.currentUser).thenAnswer((_) => currentUser);
    when(
      () => auth.onAuthStateChange,
    ).thenAnswer((_) => authStateController.stream);
    when(() => user.email).thenReturn('tester@example.com');

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        routeDataRepositoryProvider.overrideWithValue(
          _FakeRouteDataRepository(),
        ),
      ],
    );
    addTearDown(() async {
      await authStateController.close();
      container.dispose();
    });

    await _pumpRouter(tester, container: container);
    await tester.pumpAndSettle();
    expect(find.text('ログイン'), findsOneWidget);

    currentSession = session;
    currentUser = user;
    authStateController.add(const AuthState(AuthChangeEvent.signedIn, null));
    await tester.pumpAndSettle();

    expect(find.text('対応中のタスク'), findsWidgets);
  });
}
