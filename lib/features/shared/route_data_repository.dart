import '../../core/api/api_client.dart';

class RouteDataRepository {
  RouteDataRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getBootstrapData() async {
    final result = await _apiClient.invokeRoute('getBootstrapData');
    return _asMap(result);
  }

  Future<Map<String, dynamic>> getHomeContent() async {
    final result = await _apiClient.invokeRoute('getHomeContent');
    return _asMap(result);
  }

  Future<List<Map<String, dynamic>>> listMyTasks() async {
    final result = await _apiClient.invokeRoute('listMyTasks');
    return _asListOfMap(result);
  }

  Future<List<Map<String, dynamic>>> listCreatedTasks() async {
    final result = await _apiClient.invokeRoute('listCreatedTasks');
    return _asListOfMap(result);
  }

  Future<List<Map<String, dynamic>>> listAllTasks() async {
    final result = await _apiClient.invokeRoute('listAllTasks');
    return _asListOfMap(result);
  }

  Future<Map<String, dynamic>> getTaskById(String taskId) async {
    final result = await _apiClient.invokeRoute('getTaskById', args: [taskId]);
    return _asMap(result);
  }

  Future<Map<String, dynamic>> addNewTask({
    required String title,
    String? description,
    DateTime? dueAt,
    String? priority,
    List<String>? assigneeUserIds,
  }) async {
    final result = await _apiClient.invokeRoute(
      'addNewTask',
      args: [
        {
          'title': title,
          'description': description,
          'dueAtMs': dueAt?.millisecondsSinceEpoch,
          'priority': priority,
          'assigneeUserIds': assigneeUserIds,
        },
      ],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? status,
    DateTime? dueAt,
    String? priority,
    List<String>? assigneeUserIds,
  }) async {
    final result = await _apiClient.invokeRoute(
      'updateTask',
      args: [
        {
          'taskId': taskId,
          'title': title,
          'description': description,
          'status': status,
          'dueAtMs': dueAt?.millisecondsSinceEpoch,
          'priority': priority,
          'assigneeUserIds': assigneeUserIds,
        },
      ],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> completeTask(String taskId) async {
    final result = await _apiClient.invokeRoute('completeTask', args: [taskId]);
    return _asMap(result);
  }

  Future<void> deleteTaskById(String taskId) async {
    await _apiClient.invokeRoute('deleteTaskById', args: [taskId]);
  }

  Future<List<Map<String, dynamic>>> getMessages({
    String? folderId,
    bool unreadOnly = false,
  }) async {
    final result = await _apiClient.invokeRoute(
      'getMessages',
      args: [
        {'folderId': folderId, 'unreadOnly': unreadOnly},
      ],
    );
    return _asListOfMap(result);
  }

  Future<Map<String, dynamic>> getMessageById(String messageId) async {
    final result = await _apiClient.invokeRoute(
      'getMessageById',
      args: [messageId],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> addNewMessage({
    required String title,
    required String body,
    String? folderId,
  }) async {
    final result = await _apiClient.invokeRoute(
      'addNewMessage',
      args: [
        {'title': title, 'body': body, 'folderId': folderId},
      ],
    );
    return _asMap(result);
  }

  Future<void> deleteMessageById(String messageId) async {
    await _apiClient.invokeRoute('deleteMessageById', args: [messageId]);
  }

  Future<Map<String, dynamic>> addNewComment({
    required String messageId,
    required String body,
  }) async {
    final result = await _apiClient.invokeRoute(
      'addNewComment',
      args: [
        {'messageId': messageId, 'body': body},
      ],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> toggleMemoRead(String messageId) async {
    final result = await _apiClient.invokeRoute(
      'toggleMemoRead',
      args: [messageId],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> markMemoAsRead(String messageId) async {
    final result = await _apiClient.invokeRoute(
      'markMemoAsRead',
      args: [messageId],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> markMemosReadBulk(
    List<String> messageIds,
  ) async {
    final result = await _apiClient.invokeRoute(
      'markMemosReadBulk',
      args: [messageIds],
    );
    return _asMap(result);
  }

  Future<List<Map<String, dynamic>>> listActiveFolders() async {
    final result = await _apiClient.invokeRoute('listActiveFolders');
    return _asListOfMap(result);
  }

  Future<List<Map<String, dynamic>>> listFolders() async {
    final result = await _apiClient.invokeRoute('folders');
    return _asListOfMap(result);
  }

  Future<Map<String, dynamic>> createFolder({
    required String name,
    String? color,
    bool isPublic = true,
  }) async {
    final result = await _apiClient.invokeRoute(
      'folders',
      extra: {
        'method': 'POST',
        'name': name,
        'color': color,
        'isPublic': isPublic,
      },
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> updateFolder({
    required String folderId,
    String? name,
    String? color,
    bool? isPublic,
    bool? isActive,
  }) async {
    final result = await _apiClient.invokeRoute(
      'folders/$folderId',
      extra: {
        'method': 'PATCH',
        ...?name == null ? null : {'name': name},
        ...?color == null ? null : {'color': color},
        ...?isPublic == null ? null : {'isPublic': isPublic},
        ...?isActive == null ? null : {'isActive': isActive},
      },
    );
    return _asMap(result);
  }

  Future<void> archiveFolder(String folderId) async {
    await _apiClient.invokeRoute(
      'folders/$folderId',
      extra: {'method': 'DELETE'},
    );
  }

  Future<List<Map<String, dynamic>>> listTemplates(String folderId) async {
    final result = await _apiClient.invokeRoute(
      'templates',
      extra: {'folderId': folderId},
    );
    return _asListOfMap(result);
  }

  Future<Map<String, dynamic>> createTemplate({
    required String folderId,
    required String name,
    String titleFormat = '',
    String bodyFormat = '',
  }) async {
    final result = await _apiClient.invokeRoute(
      'templates',
      extra: {
        'method': 'POST',
        'folderId': folderId,
        'name': name,
        'titleFormat': titleFormat,
        'bodyFormat': bodyFormat,
      },
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> updateTemplate({
    required String templateId,
    String? name,
    String? titleFormat,
    String? bodyFormat,
  }) async {
    final result = await _apiClient.invokeRoute(
      'templates/$templateId',
      extra: {
        'method': 'PATCH',
        ...?name == null ? null : {'name': name},
        ...?titleFormat == null ? null : {'titleFormat': titleFormat},
        ...?bodyFormat == null ? null : {'bodyFormat': bodyFormat},
      },
    );
    return _asMap(result);
  }

  Future<void> deleteTemplate(String templateId) async {
    await _apiClient.invokeRoute(
      'templates/$templateId',
      extra: {'method': 'DELETE'},
    );
  }

  Future<Map<String, dynamic>> getUserSettings() async {
    final result = await _apiClient.invokeRoute('getUserSettings');
    return _asMap(result);
  }

  Future<Map<String, dynamic>> saveUserSettings({
    String? name,
    String? theme,
    String? language,
    String? imageUrl,
  }) async {
    final result = await _apiClient.invokeRoute(
      'saveUserSettings',
      args: [
        {
          ...?name == null ? null : {'name': name},
          ...?theme == null ? null : {'theme': theme},
          ...?language == null ? null : {'language': language},
          ...?imageUrl == null ? null : {'imageUrl': imageUrl},
        },
      ],
    );
    return _asMap(result);
  }

  Future<List<Map<String, dynamic>>> listActiveUsers() async {
    final result = await _apiClient.invokeRoute('listActiveUsers');
    return _asListOfMap(result);
  }

  Future<Map<String, dynamic>> adminListUsers() async {
    final result = await _apiClient.invokeRoute('adminListUsers', args: [{}]);
    return _asMap(result);
  }

  Future<Map<String, dynamic>> adminUpdateUser({
    required String email,
    String? role,
    String? status,
  }) async {
    final result = await _apiClient.invokeRoute(
      'adminUpdateUser',
      args: [
        {
          'email': email,
          ...?role == null ? null : {'role': role},
          ...?status == null ? null : {'status': status},
        },
      ],
    );
    return _asMap(result);
  }

  Future<List<Map<String, dynamic>>> adminListOrganizations() async {
    final result = await _apiClient.invokeRoute('adminListOrganizations');
    return _asListOfMap(result);
  }

  Future<Map<String, dynamic>> adminGetOrganization({String? orgId}) async {
    final result = await _apiClient.invokeRoute(
      'adminGetOrganization',
      args: [
        {
          ...?orgId == null ? null : {'orgId': orgId},
        },
      ],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> adminUpdateOrganization({
    required String name,
    String? shortName,
    String? displayColor,
    String? timezone,
    String? notificationEmail,
  }) async {
    final result = await _apiClient.invokeRoute(
      'adminUpdateOrganization',
      args: [
        {
          'name': name,
          ...?shortName == null ? null : {'shortName': shortName},
          ...?displayColor == null ? null : {'displayColor': displayColor},
          ...?timezone == null ? null : {'timezone': timezone},
          ...?notificationEmail == null
              ? null
              : {'notificationEmail': notificationEmail},
        },
      ],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> getAuditLogs({
    String range = '24h',
    String eventType = 'all',
    int limit = 100,
  }) async {
    final result = await _apiClient.invokeRoute(
      'getAuditLogs',
      args: [
        {'range': range, 'eventType': eventType, 'limit': limit},
      ],
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> pinMessage(String messageId) async {
    final result = await _apiClient.invokeRoute(
      'messages/$messageId/pin',
      extra: {'method': 'POST'},
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> messageReadStatus(String messageId) async {
    final result = await _apiClient.invokeRoute(
      'messages/$messageId/read_status',
      extra: {'method': 'GET'},
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> downloadAttachment(String attachmentId) async {
    final result = await _apiClient.invokeRoute(
      'downloadAttachment',
      args: [attachmentId],
    );
    return _asMap(result);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfMap(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((row) => row.map((key, val) => MapEntry(key.toString(), val)))
        .toList(growable: false);
  }
}
