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
import 'package:shiftflow_flutter/features/shell/bootstrap_gate_screen.dart';
import 'package:shiftflow_flutter/features/tasks/tasks_screen.dart';
import 'package:shiftflow_flutter/l10n/generated/app_localizations.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _TestAuthController extends AuthController {
  _TestAuthController() : super(_MockSupabaseClient());
}

class _FakeExternalUrlLauncher extends ExternalUrlLauncher {
  final List<Uri> launchedUris = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    launchedUris.add(uri);
    return true;
  }
}

class _FakeRouteDataRepository extends RouteDataRepository {
  _FakeRouteDataRepository({
    this.homeContent = const <String, dynamic>{},
    this.userSettings = const <String, dynamic>{
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
    Map<String, Map<String, dynamic>>? messageDetails,
    List<Map<String, dynamic>>? myTasks,
    List<Map<String, dynamic>>? createdTasks,
    List<Map<String, dynamic>>? allTasks,
    Map<String, Map<String, dynamic>>? taskDetails,
    List<Map<String, dynamic>>? users,
    Map<String, List<Map<String, dynamic>>>? templatesByFolder,
    List<Map<String, dynamic>>? joinRequests,
    List<Map<String, dynamic>>? units,
    Map<String, List<Map<String, dynamic>>>? unitMembershipsByUnit,
    List<Map<String, dynamic>>? invites,
    Map<String, List<Map<String, dynamic>>>? searchResultsByKeyword,
    this.toggleReadResponse = const <String, dynamic>{'isRead': true},
  }) : _messages = List<Map<String, dynamic>>.from(messages ?? const []),
       _messageDetails = Map<String, Map<String, dynamic>>.from(
         messageDetails ?? const {},
       ),
       _folders = List<Map<String, dynamic>>.from(folders ?? const []),
       _myTasks = List<Map<String, dynamic>>.from(myTasks ?? const []),
       _createdTasks = List<Map<String, dynamic>>.from(
         createdTasks ?? const [],
       ),
       _allTasks = List<Map<String, dynamic>>.from(allTasks ?? const []),
       _taskDetails = Map<String, Map<String, dynamic>>.from(
         taskDetails ?? const {},
       ),
       _users = List<Map<String, dynamic>>.from(users ?? const []),
       _joinRequests = List<Map<String, dynamic>>.from(
         joinRequests ?? const [],
       ),
       _units = List<Map<String, dynamic>>.from(units ?? const []),
       _unitMembershipsByUnit = Map<String, List<Map<String, dynamic>>>.from(
         unitMembershipsByUnit ?? const {},
       ),
       _invites = List<Map<String, dynamic>>.from(invites ?? const []),
       _searchResultsByKeyword = Map<String, List<Map<String, dynamic>>>.from(
         searchResultsByKeyword ?? const {},
       ),
       _templatesByFolder = Map<String, List<Map<String, dynamic>>>.from(
         templatesByFolder ?? const {},
       ),
       super(ApiClient(_MockSupabaseClient()));

  final Map<String, dynamic> homeContent;
  final Map<String, dynamic> userSettings;
  final Map<String, dynamic> bootstrapData;
  final Map<String, dynamic> toggleReadResponse;
  final List<Map<String, dynamic>> _messages;
  final Map<String, Map<String, dynamic>> _messageDetails;
  final List<Map<String, dynamic>> _folders;
  final List<Map<String, dynamic>> _myTasks;
  final List<Map<String, dynamic>> _createdTasks;
  final List<Map<String, dynamic>> _allTasks;
  final Map<String, Map<String, dynamic>> _taskDetails;
  final List<Map<String, dynamic>> _users;
  final List<Map<String, dynamic>> _joinRequests;
  final List<Map<String, dynamic>> _units;
  final Map<String, List<Map<String, dynamic>>> _unitMembershipsByUnit;
  final List<Map<String, dynamic>> _invites;
  final Map<String, List<Map<String, dynamic>>> _searchResultsByKeyword;
  final Map<String, List<Map<String, dynamic>>> _templatesByFolder;

  final List<String> savedLanguages = <String>[];
  final List<String> savedNames = <String>[];
  final List<String> savedThemes = <String>[];
  final List<String> savedImageUrls = <String>[];
  final List<String> toggledMessageIds = <String>[];
  final List<List<String>> bulkReadRequests = <List<String>>[];
  final List<String> deletedMessageIds = <String>[];
  final List<String> downloadAttachmentIds = <String>[];
  final List<String> updatedTaskIds = <String>[];
  final List<String> deletedTaskIds = <String>[];
  final List<String> completedTaskIds = <String>[];
  final List<String> updatedTemplateIds = <String>[];
  final List<String> deletedTemplateIds = <String>[];
  final List<String> approvedJoinRequestIds = <String>[];
  final List<String> rejectedJoinRequestIds = <String>[];
  final List<String> createdUnitNames = <String>[];
  final List<String> updatedUnitIds = <String>[];
  final List<Map<String, String>> assignedUnitMembers = <Map<String, String>>[];
  final List<String> createdInviteLabels = <String>[];
  final List<String> acceptedInviteTokens = <String>[];
  final List<String> changedCurrentUnitIds = <String>[];
  final List<String?> requestedFolderIds = <String?>[];
  final List<bool> requestedUnreadOnly = <bool>[];
  final List<Map<String, dynamic>> sentMessages = <Map<String, dynamic>>[];
  final List<Map<String, String?>> requestedJoinPayloads =
      <Map<String, String?>>[];
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
    String? currentOrganizationId,
    String? currentUnitId,
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
    String? currentUnitId,
    String tab = 'current',
    String? folderId,
    String scope = 'shared',
    bool unreadOnly = false,
    String? keyword,
  }) async {
    requestedFolderIds.add(folderId);
    requestedUnreadOnly.add(unreadOnly);
    return _messages
        .where((message) {
          final messageScope = message['message_scope']?.toString() ?? 'shared';
          final matchesScope = switch (scope) {
            'direct' => messageScope == 'direct',
            'shared' => messageScope != 'direct',
            _ => true,
          };
          final messageFolderId = message['folder_id']?.toString();
          final matchesFolder =
              folderId == null ||
              folderId.isEmpty ||
              messageFolderId == folderId;
          final isRead = message['isRead'] == true;
          final matchesUnread = !unreadOnly || !isRead;
          return matchesScope && matchesFolder && matchesUnread;
        })
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> listActiveFolders() async {
    return List<Map<String, dynamic>>.from(_folders);
  }

  @override
  Future<List<Map<String, dynamic>>> listFolders() async {
    return List<Map<String, dynamic>>.from(_folders);
  }

  @override
  Future<Map<String, dynamic>> toggleMemoRead(String messageId) async {
    toggledMessageIds.add(messageId);
    return toggleReadResponse;
  }

  @override
  Future<Map<String, dynamic>> markMemosReadBulk(
    List<String> messageIds,
  ) async {
    bulkReadRequests.add(List<String>.from(messageIds));
    for (final messageId in messageIds) {
      _replaceMessage(messageId, {'isRead': true});
    }
    return {'updated': messageIds.length};
  }

  @override
  Future<Map<String, dynamic>> getMessageById(String messageId) async {
    return _messageDetails[messageId] ??
        _messages.firstWhere(
          (message) => message['id'] == messageId,
          orElse: () => <String, dynamic>{'id': messageId},
        );
  }

  @override
  Future<void> deleteMessageById(String messageId) async {
    deletedMessageIds.add(messageId);
    _messages.removeWhere((message) => message['id'] == messageId);
    _messageDetails.remove(messageId);
  }

  @override
  Future<Map<String, dynamic>> messageReadStatus(String messageId) async {
    return const {
      'readUsers': <Map<String, dynamic>>[],
      'unreadUsers': <Map<String, dynamic>>[],
    };
  }

  @override
  Future<Map<String, dynamic>> downloadAttachment(String attachmentId) async {
    downloadAttachmentIds.add(attachmentId);
    return {'url': 'https://example.com/$attachmentId'};
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
  Future<Map<String, dynamic>> getTaskById(String taskId) async {
    return _taskDetails[taskId] ??
        _myTasks.firstWhere(
          (task) => task['id'] == taskId,
          orElse: () => <String, dynamic>{'id': taskId},
        );
  }

  @override
  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? status,
    DateTime? dueAt,
    String? priority,
    String? unitId,
    List<String>? assigneeUserIds,
  }) async {
    updatedTaskIds.add(taskId);
    final current = Map<String, dynamic>.from(await getTaskById(taskId));
    final updated = {
      ...current,
      ...?title == null ? null : {'title': title},
      ...?description == null ? null : {'description': description},
      ...?status == null ? null : {'status': status},
      ...?priority == null ? null : {'priority': priority},
      ...?dueAt == null ? null : {'due_at': dueAt.toIso8601String()},
      ...?assigneeUserIds == null
          ? null
          : {
              'task_assignees': assigneeUserIds
                  .map(
                    (id) => {
                      'user_id': id,
                      'users': {
                        'id': id,
                        'display_name':
                            _users
                                .firstWhere(
                                  (user) => user['userId'] == id,
                                  orElse: () => <String, dynamic>{},
                                )['displayName']
                                ?.toString() ??
                            id,
                      },
                    },
                  )
                  .toList(growable: false),
            },
    };
    _taskDetails[taskId] = Map<String, dynamic>.from(updated);
    _replaceTask(taskId, updated);
    return updated;
  }

  @override
  Future<Map<String, dynamic>> completeTask(String taskId) async {
    completedTaskIds.add(taskId);
    return updateTask(taskId: taskId, status: 'completed');
  }

  @override
  Future<void> deleteTaskById(String taskId) async {
    deletedTaskIds.add(taskId);
    _taskDetails.remove(taskId);
    _myTasks.removeWhere((task) => task['id'] == taskId);
    _createdTasks.removeWhere((task) => task['id'] == taskId);
    _allTasks.removeWhere((task) => task['id'] == taskId);
  }

  @override
  Future<List<Map<String, dynamic>>> listActiveUsers() async {
    return List<Map<String, dynamic>>.from(_users);
  }

  @override
  Future<Map<String, dynamic>> addNewMessage({
    required String title,
    required String body,
    String scope = 'shared',
    String? unitId,
    String? folderId,
    List<String>? recipientUserIds,
  }) async {
    final message = <String, dynamic>{
      'id': 'message-created-${sentMessages.length + 1}',
      'organization_id': 'org-1',
      'title': title,
      'body': body,
      'folder_id': folderId,
      'unit_id': unitId,
      'message_scope': scope,
      'recipientUserIds': recipientUserIds ?? const <String>[],
    };
    sentMessages.add(message);
    _messages.insert(0, Map<String, dynamic>.from(message));
    return message;
  }

  @override
  Future<List<Map<String, dynamic>>> listJoinRequests() async {
    return List<Map<String, dynamic>>.from(_joinRequests);
  }

  @override
  Future<Map<String, dynamic>> approveJoinRequest(String joinRequestId) async {
    approvedJoinRequestIds.add(joinRequestId);
    final index = _joinRequests.indexWhere((row) => row['id'] == joinRequestId);
    if (index >= 0) {
      _joinRequests[index] = {..._joinRequests[index], 'status': 'active'};
      return _joinRequests[index];
    }
    return {'id': joinRequestId, 'status': 'active'};
  }

  @override
  Future<Map<String, dynamic>> rejectJoinRequest(String joinRequestId) async {
    rejectedJoinRequestIds.add(joinRequestId);
    final index = _joinRequests.indexWhere((row) => row['id'] == joinRequestId);
    if (index >= 0) {
      _joinRequests[index] = {..._joinRequests[index], 'status': 'revoked'};
      return _joinRequests[index];
    }
    return {'id': joinRequestId, 'status': 'revoked'};
  }

  @override
  Future<List<Map<String, dynamic>>> listUnits() async {
    return List<Map<String, dynamic>>.from(_units);
  }

  @override
  Future<Map<String, dynamic>> createUnit({
    required String name,
    String? parentUnitId,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    createdUnitNames.add(name);
    final unit = <String, dynamic>{
      'id': 'unit-created-${_units.length + 1}',
      'name': name,
      'parent_unit_id': parentUnitId,
      'path_text': parentUnitId == null ? name : '${parentUnitId}_$name',
      'is_active': isActive,
    };
    _units.add(unit);
    return unit;
  }

  @override
  Future<Map<String, dynamic>> updateUnit({
    required String unitId,
    String? name,
    String? parentUnitId,
    int? sortOrder,
    bool? isActive,
  }) async {
    updatedUnitIds.add(unitId);
    final index = _units.indexWhere((row) => row['id'] == unitId);
    if (index >= 0) {
      _units[index] = {
        ..._units[index],
        ...?name == null ? null : {'name': name},
        ...?parentUnitId == null ? null : {'parent_unit_id': parentUnitId},
        ...?isActive == null ? null : {'is_active': isActive},
      };
      return _units[index];
    }
    return {'id': unitId};
  }

  @override
  Future<Map<String, dynamic>> assignUnitMember({
    required String unitId,
    required String userId,
    String role = 'member',
    String status = 'active',
  }) async {
    assignedUnitMembers.add({
      'unitId': unitId,
      'userId': userId,
      'role': role,
      'status': status,
    });
    final members = _unitMembershipsByUnit[unitId] ?? <Map<String, dynamic>>[];
    members.add({
      'id': 'unit-membership-${members.length + 1}',
      'unitId': unitId,
      'userId': userId,
      'role': role,
      'status': status,
      'displayName': _users.firstWhere(
        (user) => user['userId'] == userId,
        orElse: () => <String, dynamic>{},
      )['displayName'],
      'email': _users.firstWhere(
        (user) => user['userId'] == userId,
        orElse: () => <String, dynamic>{},
      )['email'],
    });
    _unitMembershipsByUnit[unitId] = members;
    return members.last;
  }

  @override
  Future<List<Map<String, dynamic>>> listUnitMemberships(String unitId) async {
    return List<Map<String, dynamic>>.from(
      _unitMembershipsByUnit[unitId] ?? const <Map<String, dynamic>>[],
    );
  }

  @override
  Future<Map<String, dynamic>> createOrganizationInvite({
    String? unitId,
    String? inviteLabel,
    String role = 'member',
    DateTime? expiresAt,
  }) async {
    createdInviteLabels.add(inviteLabel ?? '');
    final invite = <String, dynamic>{
      'id': 'invite-${_invites.length + 1}',
      'invite_label': inviteLabel,
      'role': role,
      'unit_id': unitId,
      'invite_token': 'token-${_invites.length + 1}',
      'expires_at': expiresAt?.toIso8601String(),
      'accepted_at': null,
    };
    _invites.insert(0, invite);
    return invite;
  }

  @override
  Future<List<Map<String, dynamic>>> listOrganizationInvites() async {
    return List<Map<String, dynamic>>.from(_invites);
  }

  @override
  Future<List<Map<String, dynamic>>> searchOrganizationsByCode(
    String keyword,
  ) async {
    return List<Map<String, dynamic>>.from(
      _searchResultsByKeyword[keyword] ?? const <Map<String, dynamic>>[],
    );
  }

  @override
  Future<Map<String, dynamic>> requestOrganizationJoin({
    required String organizationId,
    String? organizationCode,
    String? requestMessage,
  }) async {
    requestedJoinPayloads.add({
      'organizationId': organizationId,
      'organizationCode': organizationCode,
      'requestMessage': requestMessage,
    });
    return {
      'organization_id': organizationId,
      'requested_code': organizationCode,
      'request_message': requestMessage,
      'status': 'pending',
    };
  }

  @override
  Future<Map<String, dynamic>> acceptOrganizationInvite(
    String inviteToken,
  ) async {
    acceptedInviteTokens.add(inviteToken);
    return {'invite_token': inviteToken, 'status': 'active'};
  }

  @override
  Future<Map<String, dynamic>> changeCurrentUnit(String unitId) async {
    changedCurrentUnitIds.add(unitId);
    return {'success': true, 'unitId': unitId};
  }

  @override
  Future<List<Map<String, dynamic>>> listTemplates(String folderId) async {
    return List<Map<String, dynamic>>.from(
      _templatesByFolder[folderId] ?? const <Map<String, dynamic>>[],
    );
  }

  @override
  Future<Map<String, dynamic>> updateTemplate({
    required String templateId,
    String? name,
    String? titleFormat,
    String? bodyFormat,
  }) async {
    updatedTemplateIds.add(templateId);
    for (final entry in _templatesByFolder.entries) {
      final index = entry.value.indexWhere(
        (template) => template['id'] == templateId,
      );
      if (index >= 0) {
        entry.value[index] = {
          ...entry.value[index],
          ...?name == null ? null : {'name': name},
          ...?titleFormat == null ? null : {'title_format': titleFormat},
          ...?bodyFormat == null ? null : {'body_format': bodyFormat},
        };
        return entry.value[index];
      }
    }
    return <String, dynamic>{'id': templateId};
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    deletedTemplateIds.add(templateId);
    for (final entry in _templatesByFolder.entries) {
      entry.value.removeWhere((template) => template['id'] == templateId);
    }
  }

  @override
  Future<Map<String, dynamic>> getBootstrapData() async => bootstrapData;

  void _replaceTask(String taskId, Map<String, dynamic> updated) {
    for (final list in [_myTasks, _createdTasks, _allTasks]) {
      final index = list.indexWhere((task) => task['id'] == taskId);
      if (index >= 0) {
        list[index] = {...list[index], ...updated};
      }
    }
  }

  void _replaceMessage(String messageId, Map<String, dynamic> updated) {
    final index = _messages.indexWhere((message) => message['id'] == messageId);
    if (index >= 0) {
      _messages[index] = {..._messages[index], ...updated};
    }
    if (_messageDetails.containsKey(messageId)) {
      _messageDetails[messageId] = {..._messageDetails[messageId]!, ...updated};
    }
  }
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
        supportedLocales: const [Locale('ja'), Locale('en')],
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
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
        userSettingsProvider.overrideWith((ref) async => repo.userSettings),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container: container, child: const HomeScreen());
    await tester.pumpAndSettle();

    expect(find.text('対応中のタスク'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.text('未読メッセージ'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('承認待ち'), findsWidgets);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('HomeScreen shows current organization, unit and admin summary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _FakeRouteDataRepository(
      homeContent: const {
        'overview': {
          'openTaskCount': 3,
          'unreadMessageCount': 5,
          'pendingUserCount': 2,
        },
        'blocks': {
          'tasks': [
            {'id': 'task-1', 'title': '朝会準備', 'priority': 'high'},
          ],
          'messages': [
            {'id': 'msg-1', 'title': '本日の連絡', 'body': '確認お願いします'},
          ],
          'folders': [
            {'id': 'folder-1', 'name': '全体', 'is_public': true},
          ],
          'units': [
            {'id': 'unit-1', 'name': '本部', 'path_text': '本部'},
          ],
          'adminSummary': {
            'openTaskCount': 3,
            'unreadMessageCount': 5,
            'pendingUserCount': 2,
          },
        },
      },
      userSettings: const {
        'name': 'Tester',
        'imageUrl': '',
        'role': 'admin',
        'organizationRole': 'admin',
        'theme': 'system',
        'language': 'ja',
        'email': 'tester@example.com',
      },
      bootstrapData: const {
        'participation': {
          'status': 'active',
          'canUseApp': true,
          'organizationRole': 'admin',
          'unitRole': 'manager',
        },
        'currentOrganization': {'id': 'org-1', 'name': 'ShiftFlow Cafe'},
        'currentUnit': {'id': 'unit-1', 'name': '本部'},
      },
    );
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container: container, child: const HomeScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('現在の組織: ShiftFlow Cafe'), findsOneWidget);
    expect(find.textContaining('現在地ユニット: 本部'), findsOneWidget);
    expect(find.text('管理要約'), findsOneWidget);
    expect(find.text('承認待ち'), findsWidgets);
  });

  testWidgets('MessagesScreen updates read icon after toggle action', (
    tester,
  ) async {
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
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
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

  testWidgets('MessagesScreen filters by folder', (
    tester,
  ) async {
    final repo = _FakeRouteDataRepository(
      bootstrapData: const {
        'currentUnit': {'id': 'unit-1', 'name': '新宿店'},
        'availableUnits': [
          {'id': 'unit-1', 'name': '新宿店', 'pathText': '本部 / 新宿店'},
        ],
      },
      folders: const [
        {'id': 'folder-1', 'name': '連絡', 'unit_id': 'unit-1'},
        {'id': 'folder-2', 'name': '運用', 'unit_id': 'unit-1'},
      ],
      messages: const [
        {
          'id': 'message-1',
          'title': '未読メッセージ',
          'body': '未読',
          'isRead': false,
          'message_scope': 'shared',
          'folder_id': 'folder-1',
        },
        {
          'id': 'message-2',
          'title': '既読メッセージ',
          'body': '既読',
          'isRead': true,
          'message_scope': 'shared',
          'folder_id': 'folder-1',
        },
        {
          'id': 'message-3',
          'title': '別フォルダ',
          'body': '未読',
          'isRead': false,
          'message_scope': 'shared',
          'folder_id': 'folder-2',
        },
      ],
    );
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container: container,
      child: const MessagesScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('未読メッセージ'), findsOneWidget);
    expect(find.text('既読メッセージ'), findsOneWidget);
    expect(find.text('別フォルダ'), findsOneWidget);

    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('連絡').last);
    await tester.pumpAndSettle();

    expect(find.text('未読メッセージ'), findsOneWidget);
    expect(find.text('既読メッセージ'), findsOneWidget);
    expect(find.text('別フォルダ'), findsNothing);

  });

  testWidgets('TasksScreen switches scope between My, Created, All', (
    tester,
  ) async {
    final repo = _FakeRouteDataRepository(
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
        routeDataRepositoryProvider.overrideWithValue(repo),
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container: container, child: const TasksScreen());
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

  testWidgets('TasksScreen edits and deletes tasks from the list', (
    tester,
  ) async {
    final repo = _FakeRouteDataRepository(
      myTasks: const [
        {
          'id': 'task-1',
          'title': 'Old task',
          'description': 'before',
          'status': 'open',
          'priority': 'medium',
        },
      ],
      taskDetails: const {
        'task-1': {
          'id': 'task-1',
          'title': 'Old task',
          'description': 'before',
          'status': 'open',
          'priority': 'medium',
          'task_assignees': [
            {
              'user_id': 'user-1',
              'users': {'id': 'user-1', 'display_name': '担当者A'},
            },
          ],
        },
      },
      users: const [
        {'userId': 'user-1', 'displayName': '担当者A'},
      ],
    );
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container: container, child: const TasksScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Updated task');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();

    expect(repo.updatedTaskIds, ['task-1']);
    expect(find.text('Updated task'), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除').last);
    await tester.pumpAndSettle();

    expect(repo.deletedTaskIds, ['task-1']);
    expect(find.text('Updated task'), findsNothing);
  });

  testWidgets('TasksScreen opens detail and downloads attachments', (
    tester,
  ) async {
    final repo = _FakeRouteDataRepository(
      myTasks: const [
        {
          'id': 'task-1',
          'title': 'Task with detail',
          'description': 'card body',
          'status': 'open',
          'priority': 'medium',
        },
      ],
      taskDetails: const {
        'task-1': {
          'id': 'task-1',
          'title': 'Task with detail',
          'description': 'detail body',
          'status': 'open',
          'priority': 'medium',
          'task_assignees': [
            {
              'user_id': 'user-1',
              'users': {'id': 'user-1', 'display_name': '担当者A'},
            },
          ],
          'task_attachments': [
            {
              'attachment_id': 'attachment-1',
              'attachments': {'id': 'attachment-1', 'file_name': 'guide.pdf'},
            },
          ],
        },
      },
    );
    final launcher = _FakeExternalUrlLauncher();
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        externalUrlLauncherProvider.overrideWithValue(launcher),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container: container, child: const TasksScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Task with detail'));
    await tester.pumpAndSettle();

    expect(find.text('detail body'), findsOneWidget);
    expect(find.text('担当者A'), findsOneWidget);

    await tester.tap(find.text('guide.pdf'));
    await tester.pumpAndSettle();

    expect(repo.downloadAttachmentIds, ['attachment-1']);
    expect(
      launcher.launchedUris.single.toString(),
      'https://example.com/attachment-1',
    );
  });

  testWidgets('SettingsScreen saves profile, language and theme', (
    tester,
  ) async {
    final repo = _FakeRouteDataRepository(
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

    await _pumpScreen(
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

  testWidgets('MessagesScreen marks selected messages as read', (tester) async {
    final repo = _FakeRouteDataRepository(
      messages: const [
        {'id': 'message-1', 'title': '未読1', 'body': 'body', 'isRead': false},
        {'id': 'message-2', 'title': '未読2', 'body': 'body', 'isRead': false},
      ],
    );
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container: container,
      child: const MessagesScreen(),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('未読1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('未読2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('選択分を既読'));
    await tester.pumpAndSettle();

    expect(repo.bulkReadRequests, [
      ['message-1', 'message-2'],
    ]);
  });

  testWidgets('Message detail downloads attachments and deletes message', (
    tester,
  ) async {
    final repo = _FakeRouteDataRepository(
      messages: const [
        {'id': 'message-1', 'title': '連絡', 'body': '一覧本文', 'isRead': false},
      ],
      messageDetails: const {
        'message-1': {
          'id': 'message-1',
          'title': '連絡',
          'body': '詳細本文',
          'comments': [],
          'message_attachments': [
            {
              'attachment_id': 'attachment-2',
              'attachments': {'id': 'attachment-2', 'file_name': 'memo.pdf'},
            },
          ],
        },
      },
    );
    final launcher = _FakeExternalUrlLauncher();
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        externalUrlLauncherProvider.overrideWithValue(launcher),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container: container,
      child: const MessagesScreen(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('連絡'));
    await tester.pumpAndSettle();

    expect(find.text('詳細本文'), findsOneWidget);

    await tester.tap(find.text('memo.pdf'));
    await tester.pumpAndSettle();
    expect(repo.downloadAttachmentIds, ['attachment-2']);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除').last);
    await tester.pumpAndSettle();

    expect(repo.deletedMessageIds, ['message-1']);
    expect(find.text('連絡'), findsNothing);
  });

  testWidgets('AdminScreen edits and deletes templates', (tester) async {
    final repo = _FakeRouteDataRepository(
      folders: const [
        {'id': 'folder-1', 'name': '連絡'},
      ],
      templatesByFolder: {
        'folder-1': [
          {
            'id': 'template-1',
            'name': '朝会',
            'title_format': '朝会テンプレ',
            'body_format': '本文',
          },
        ],
      },
    );
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        isManagerOrAdminProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container: container, child: const AdminScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('定型文'));
    await tester.pumpAndSettle();
    expect(find.text('朝会'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '更新後テンプレ');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();

    expect(repo.updatedTemplateIds, ['template-1']);
    expect(find.text('更新後テンプレ'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除').last);
    await tester.pumpAndSettle();

    expect(repo.deletedTemplateIds, ['template-1']);
    expect(find.text('更新後テンプレ'), findsNothing);
  });

  testWidgets('AdminScreen shows permission denied for non managers', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [isManagerOrAdminProvider.overrideWith((ref) => false)],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container: container, child: const AdminScreen());
    await tester.pumpAndSettle();

    expect(find.text('権限がありません。'), findsOneWidget);
  });

  testWidgets('AdminScreen approves join requests and creates invites', (
    tester,
  ) async {
    final repo = _FakeRouteDataRepository(
      joinRequests: const [
        {
          'id': 'jr-1',
          'status': 'pending',
          'requested_code': 'SHIFT-001',
          'request_message': '参加したいです',
          'users': {'email': 'staff@example.com', 'display_name': 'スタッフ'},
        },
      ],
      units: const [
        {'id': 'unit-1', 'name': '本部', 'path_text': '本部', 'is_active': true},
      ],
    );
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        isManagerOrAdminProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(tester, container: container, child: const AdminScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('参加申請'));
    await tester.pumpAndSettle();
    expect(find.text('スタッフ'), findsOneWidget);
    await tester.tap(find.text('承認'));
    await tester.pumpAndSettle();
    expect(repo.approvedJoinRequestIds, ['jr-1']);

    await tester.ensureVisible(find.text('招待'));
    await tester.tap(find.text('招待'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('招待を作成'));
    await tester.pumpAndSettle();
    final inviteDialog = find.byType(AlertDialog).last;
    final inviteFields = find.descendant(
      of: inviteDialog,
      matching: find.byType(TextField),
    );
    await tester.enterText(inviteFields.first, '店舗マネージャー向け');
    await tester.tap(find.text('作成').last);
    await tester.pumpAndSettle();

    expect(repo.createdInviteLabels, ['店舗マネージャー向け']);
  });

  testWidgets('ParticipationScreen searches organizations and requests join', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _FakeRouteDataRepository(
      bootstrapData: const {
        'participation': {
          'status': 'unaffiliated',
          'canUseApp': false,
          'organizationRole': 'guest',
          'unitRole': 'none',
        },
        'availableOrganizations': [],
        'availableUnits': [],
      },
      searchResultsByKeyword: const {
        'SHIFT': [
          {
            'id': 'org-1',
            'name': 'ShiftFlow Cafe',
            'organization_code': 'SHIFT',
          },
        ],
      },
    );
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container: container,
      child: const ParticipationScreen(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'SHIFT');
    await tester.enterText(find.byType(TextField).at(1), 'よろしくお願いします');
    await tester.ensureVisible(find.text('組織を検索'));
    await tester.tap(find.text('組織を検索'));
    await tester.pumpAndSettle();

    expect(find.text('ShiftFlow Cafe'), findsOneWidget);

    await tester.tap(find.text('参加申請'));
    await tester.pumpAndSettle();

    expect(repo.requestedJoinPayloads, hasLength(1));
    expect(repo.requestedJoinPayloads.first['organizationId'], 'org-1');
    expect(repo.requestedJoinPayloads.first['organizationCode'], 'SHIFT');
  });

  testWidgets('ParticipationScreen accepts invite token', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _FakeRouteDataRepository(
      bootstrapData: const {
        'participation': {
          'status': 'revoked',
          'canUseApp': false,
          'organizationRole': 'member',
          'unitRole': 'none',
        },
        'availableOrganizations': [],
        'availableUnits': [],
      },
    );
    final container = ProviderContainer(
      overrides: [
        routeDataRepositoryProvider.overrideWithValue(repo),
        bootstrapDataProvider.overrideWith((ref) async => repo.bootstrapData),
      ],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container: container,
      child: const ParticipationScreen(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'invite-token-123');
    await tester.ensureVisible(find.text('招待を受諾'));
    await tester.tap(find.text('招待を受諾'));
    await tester.pumpAndSettle();

    expect(repo.acceptedInviteTokens, ['invite-token-123']);
  });

  testWidgets('MessagesScreen confirms DM send with multiple recipients', (
    tester,
  ) async {
    final repo = _FakeRouteDataRepository(
      bootstrapData: const {
        'participation': {
          'status': 'active',
          'canUseApp': true,
          'organizationRole': 'member',
          'unitRole': 'member',
        },
        'currentOrganization': {'id': 'org-1', 'name': 'ShiftFlow Demo Org'},
        'currentUnit': {'id': 'unit-1', 'name': '本部'},
        'availableUnits': [
          {
            'id': 'unit-1',
            'name': '本部',
            'pathText': '本部',
            'isCurrent': true,
            'role': 'member',
          },
        ],
      },
      users: const [
        {
          'userId': 'user-1',
          'displayName': '田中',
          'email': 'tanaka@example.com',
        },
        {'userId': 'user-2', 'displayName': '佐藤', 'email': 'sato@example.com'},
      ],
    );
    final container = ProviderContainer(
      overrides: [routeDataRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await _pumpScreen(
      tester,
      container: container,
      child: const MessagesScreen(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('DM'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final createDialog = find.byType(AlertDialog).last;
    await tester.tap(
      find.descendant(of: createDialog, matching: find.text('田中')),
    );
    await tester.tap(
      find.descendant(of: createDialog, matching: find.text('佐藤')),
    );
    final dialogFields = find.descendant(
      of: createDialog,
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.first, 'DM確認');
    await tester.enterText(dialogFields.last, '複数宛先テスト');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(find.text('送信内容の確認'), findsOneWidget);
    await tester.tap(find.text('送信する'));
    await tester.pumpAndSettle();

    expect(repo.sentMessages, hasLength(1));
    expect(repo.sentMessages.first['message_scope'], 'direct');
    expect(repo.sentMessages.first['recipientUserIds'], ['user-1', 'user-2']);
  });
}
