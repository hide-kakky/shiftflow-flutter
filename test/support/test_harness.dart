import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shiftflow_flutter/app.dart';
import 'package:shiftflow_flutter/core/api/api_client.dart';
import 'package:shiftflow_flutter/features/shared/route_data_repository.dart';
import 'package:shiftflow_flutter/l10n/generated/app_localizations.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class TestSupabaseAuthHarness {
  TestSupabaseAuthHarness({
    bool loggedIn = false,
    String email = 'tester@example.com',
  }) : client = _MockSupabaseClient(),
       auth = _MockGoTrueClient(),
       user = User(
         id: 'user-1',
         appMetadata: const <String, dynamic>{},
         userMetadata: const <String, dynamic>{},
         aud: 'authenticated',
         email: email,
         createdAt: DateTime(2026, 1, 1).toIso8601String(),
       ),
       _controller = StreamController<AuthState>.broadcast() {
    session = Session(
      accessToken: 'test-access-token',
      tokenType: 'bearer',
      user: user,
    );

    when(() => client.auth).thenReturn(auth);
    when(() => auth.onAuthStateChange).thenAnswer((_) => _controller.stream);

    setLoggedIn(loggedIn, emitEvent: false);
  }

  final SupabaseClient client;
  final GoTrueClient auth;
  final User user;
  late final Session session;
  final StreamController<AuthState> _controller;

  void setLoggedIn(bool loggedIn, {bool emitEvent = true}) {
    final currentSession = loggedIn ? session : null;
    final currentUser = loggedIn ? user : null;
    when(() => auth.currentSession).thenReturn(currentSession);
    when(() => auth.currentUser).thenReturn(currentUser);

    if (emitEvent) {
      _controller.add(
        AuthState(
          loggedIn ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut,
          currentSession,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class TestRouteDataRepository extends RouteDataRepository {
  TestRouteDataRepository({
    this.homeContent = const <String, dynamic>{},
    this.userSettings = const <String, dynamic>{
      'userId': 'user-1',
      'name': 'Tester',
      'imageUrl': '',
      'role': 'member',
      'theme': 'system',
      'language': 'ja',
      'email': 'tester@example.com',
    },
    this.bootstrapData = const <String, dynamic>{},
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? folders,
    List<Map<String, dynamic>>? myTasks,
    List<Map<String, dynamic>>? createdTasks,
    List<Map<String, dynamic>>? allTasks,
    this.toggleReadResponse = const <String, dynamic>{'isRead': true},
  }) : _messages = List<Map<String, dynamic>>.from(messages ?? const []),
       _folders = List<Map<String, dynamic>>.from(folders ?? const []),
       _myTasks = List<Map<String, dynamic>>.from(myTasks ?? const []),
       _createdTasks = List<Map<String, dynamic>>.from(
         createdTasks ?? const [],
       ),
       _allTasks = List<Map<String, dynamic>>.from(allTasks ?? const []),
       super(ApiClient(_MockSupabaseClient()));

  final Map<String, dynamic> homeContent;
  final Map<String, dynamic> userSettings;
  final Map<String, dynamic> bootstrapData;
  final Map<String, dynamic> toggleReadResponse;
  final List<Map<String, dynamic>> _messages;
  final List<Map<String, dynamic>> _folders;
  final List<Map<String, dynamic>> _myTasks;
  final List<Map<String, dynamic>> _createdTasks;
  final List<Map<String, dynamic>> _allTasks;

  final List<String> savedLanguages = <String>[];
  final List<String> savedNames = <String>[];
  final List<String> savedThemes = <String>[];
  final List<String> savedImageUrls = <String>[];
  final List<String> toggledMessageIds = <String>[];
  final List<String?> requestedFolderIds = <String?>[];
  final List<bool> requestedUnreadOnly = <bool>[];
  int listMyTasksCalls = 0;
  int listCreatedTasksCalls = 0;
  int listAllTasksCalls = 0;

  @override
  Future<Map<String, dynamic>> getHomeContent() async => homeContent;

  @override
  Future<Map<String, dynamic>> getUserSettings() async => userSettings;

  @override
  Future<Map<String, dynamic>> saveUserSettings({
    String? name,
    String? theme,
    String? language,
    String? imageUrl,
  }) async {
    if (language != null) {
      savedLanguages.add(language);
    }
    if (name != null) {
      savedNames.add(name);
    }
    if (theme != null) {
      savedThemes.add(theme);
    }
    if (imageUrl != null) {
      savedImageUrls.add(imageUrl);
    }
    return {
      ...userSettings,
      ...?name == null ? null : {'name': name},
      ...?theme == null ? null : {'theme': theme},
      ...?language == null ? null : {'language': language},
      ...?imageUrl == null ? null : {'imageUrl': imageUrl},
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages({
    String? folderId,
    bool unreadOnly = false,
  }) async {
    requestedFolderIds.add(folderId);
    requestedUnreadOnly.add(unreadOnly);
    return _messages
        .where((message) {
          final messageFolderId = message['folder_id']?.toString();
          final matchesFolder =
              folderId == null ||
              folderId.isEmpty ||
              messageFolderId == folderId;
          final isRead = message['isRead'] == true;
          final matchesUnread = !unreadOnly || !isRead;
          return matchesFolder && matchesUnread;
        })
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> listActiveFolders() async {
    return List<Map<String, dynamic>>.from(_folders);
  }

  @override
  Future<Map<String, dynamic>> toggleMemoRead(String messageId) async {
    toggledMessageIds.add(messageId);
    return toggleReadResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> listMyTasks() async {
    listMyTasksCalls += 1;
    return List<Map<String, dynamic>>.from(_myTasks);
  }

  @override
  Future<List<Map<String, dynamic>>> listCreatedTasks() async {
    listCreatedTasksCalls += 1;
    return List<Map<String, dynamic>>.from(_createdTasks);
  }

  @override
  Future<List<Map<String, dynamic>>> listAllTasks() async {
    listAllTasksCalls += 1;
    return List<Map<String, dynamic>>.from(_allTasks);
  }

  @override
  Future<Map<String, dynamic>> getBootstrapData() async => bootstrapData;
}

Future<void> pumpTestScreen(
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
        supportedLocales: const [Locale('ja'), Locale('en')],
        home: Scaffold(body: child),
      ),
    ),
  );
}

Future<void> pumpShiftFlowApp(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ShiftFlowApp(),
    ),
  );
}
