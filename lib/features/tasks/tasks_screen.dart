import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _TaskListScope _scope = _TaskListScope.my;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    final repository = ref.read(routeDataRepositoryProvider);
    switch (_scope) {
      case _TaskListScope.my:
        return repository.listMyTasks();
      case _TaskListScope.created:
        return repository.listCreatedTasks();
      case _TaskListScope.all:
        return repository.listAllTasks();
    }
  }

  Future<List<Map<String, dynamic>>> _loadAssignableUsers() async {
    try {
      return await ref.read(routeDataRepositoryProvider).listActiveUsers();
    } catch (_) {
      return const [];
    }
  }

  void _updateScope(_TaskListScope scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Widget _buildScopeSelector(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: Text(l10n.taskScopeMy),
            selected: _scope == _TaskListScope.my,
            onSelected: (_) => _updateScope(_TaskListScope.my),
          ),
          ChoiceChip(
            label: Text(l10n.taskScopeCreated),
            selected: _scope == _TaskListScope.created,
            onSelected: (_) => _updateScope(_TaskListScope.created),
          ),
          ChoiceChip(
            label: Text(l10n.taskScopeAll),
            selected: _scope == _TaskListScope.all,
            onSelected: (_) => _updateScope(_TaskListScope.all),
          ),
        ],
      ),
    );
  }

  Future<_TaskDraft?> _showTaskDraftDialog({
    required String dialogTitle,
    required List<Map<String, dynamic>> users,
    _TaskDraft? initialDraft,
    bool enableAttachments = true,
  }) async {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController(text: initialDraft?.title ?? '');
    final bodyController = TextEditingController(
      text: initialDraft?.description ?? '',
    );
    var dueDate = initialDraft?.dueDate;
    var priority = initialDraft?.priority ?? 'medium';
    final selectedAssignees = <String>{
      ...?initialDraft?.assigneeUserIds,
    };
    final selectedFiles = <PlatformFile>[
      ...?initialDraft?.attachments,
    ];

    final draft = await showDialog<_TaskDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(dialogTitle),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(labelText: l10n.title),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bodyController,
                        decoration: InputDecoration(labelText: l10n.body),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: InputDecoration(labelText: l10n.taskPriority),
                        items: [
                          DropdownMenuItem(
                            value: 'low',
                            child: Text(l10n.priorityLow),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text(l10n.priorityMedium),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text(l10n.priorityHigh),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            priority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.taskDueDate,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: now.subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: now.add(const Duration(days: 3650)),
                                initialDate: dueDate ?? now,
                              );
                              if (picked == null) return;
                              setDialogState(() {
                                dueDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  18,
                                );
                              });
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              dueDate == null
                                  ? l10n.selectDueDate
                                  : DateFormat.yMd(
                                      Localizations.localeOf(
                                        context,
                                      ).toLanguageTag(),
                                    ).format(dueDate!),
                            ),
                          ),
                          if (dueDate != null)
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  dueDate = null;
                                });
                              },
                              child: Text(l10n.clearDueDate),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.taskAssignees,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      if (users.isEmpty)
                        Text(l10n.noAssigneesFound)
                      else
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final userId = _userIdFromRow(user);
                              if (userId.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final name =
                                  user['displayName']?.toString() ??
                                  user['display_name']?.toString() ??
                                  user['name']?.toString() ??
                                  user['email']?.toString() ??
                                  userId;
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: selectedAssignees.contains(userId),
                                title: Text(name),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selectedAssignees.add(userId);
                                    } else {
                                      selectedAssignees.remove(userId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      if (enableAttachments) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.taskAttachments,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                              withData: true,
                            );
                            if (picked == null) return;
                            final files = picked.files
                                .where((f) => f.bytes != null)
                                .toList(growable: false);
                            setDialogState(() {
                              selectedFiles
                                ..clear()
                                ..addAll(files);
                            });
                          },
                          icon: const Icon(Icons.attach_file),
                          label: Text(l10n.pickAttachments),
                        ),
                        if (selectedFiles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final file in selectedFiles)
                                InputChip(
                                  label: Text(file.name),
                                  onDeleted: () {
                                    setDialogState(() {
                                      selectedFiles.remove(file);
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: titleController.text.trim().isEmpty
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(
                            _TaskDraft(
                              title: titleController.text.trim(),
                              description: bodyController.text.trim(),
                              dueDate: dueDate,
                              priority: priority,
                              assigneeUserIds: selectedAssignees.toList(
                                growable: false,
                              ),
                              attachments: List<PlatformFile>.from(
                                selectedFiles,
                              ),
                            ),
                          );
                        },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    return draft;
  }

  Future<bool> _createTask() async {
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(routeDataRepositoryProvider);
    final users = await _loadAssignableUsers();
    if (!mounted) return false;

    final draft = await _showTaskDraftDialog(
      dialogTitle: l10n.createTask,
      users: users,
      enableAttachments: true,
    );
    if (draft == null) return false;

    try {
      final createdTask = await repository.addNewTask(
        title: draft.title,
        description: draft.description,
        dueAt: draft.dueDate,
        priority: draft.priority,
        assigneeUserIds: draft.assigneeUserIds,
      );
      if (draft.attachments.isNotEmpty) {
        final taskId = createdTask['id']?.toString() ?? '';
        final orgId = createdTask['organization_id']?.toString() ?? '';
        if (taskId.isNotEmpty && orgId.isNotEmpty) {
          final result = await _uploadTaskAttachments(
            taskId: taskId,
            organizationId: orgId,
            files: draft.attachments,
          );
          if (!mounted) return false;
          if (result.failedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${l10n.taskAttachmentPartialUpload}: ${result.successCount}/${draft.attachments.length}',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.taskAttachmentUploadSuccess)),
            );
          }
        }
      }
      await _refresh();
      return true;
    } catch (err) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$err')));
      return false;
    }
  }

  Future<bool> _editTask(Map<String, dynamic> task) async {
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(routeDataRepositoryProvider);
    final taskId = task['id']?.toString() ?? '';
    if (taskId.isEmpty) return false;

    final users = await _loadAssignableUsers();
    final detail = await repository.getTaskById(taskId);
    if (!mounted) return false;

    final draft = await _showTaskDraftDialog(
      dialogTitle: l10n.edit,
      users: users,
      enableAttachments: false,
      initialDraft: _TaskDraft(
        title: detail['title']?.toString() ?? task['title']?.toString() ?? '',
        description:
            detail['description']?.toString() ??
            task['description']?.toString() ??
            '',
        dueDate: _parseDateTime(detail['due_at']?.toString()),
        priority: detail['priority']?.toString() ?? 'medium',
        assigneeUserIds: _extractAssigneeIds(detail),
        attachments: const [],
      ),
    );
    if (draft == null) return false;

    await repository.updateTask(
      taskId: taskId,
      title: draft.title,
      description: draft.description,
      dueAt: draft.dueDate,
      priority: draft.priority,
      assigneeUserIds: draft.assigneeUserIds,
    );
    if (!mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.taskUpdated)));
    await _refresh();
    return true;
  }

  Future<bool> _deleteTask(String taskId) async {
    final l10n = AppLocalizations.of(context);
    if (taskId.isEmpty) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    await ref.read(routeDataRepositoryProvider).deleteTaskById(taskId);
    if (!mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.taskDeleted)));
    await _refresh();
    return true;
  }

  Future<bool> _markTaskComplete(String taskId) async {
    if (taskId.isEmpty) return false;
    await ref.read(routeDataRepositoryProvider).completeTask(taskId);
    await _refresh();
    return true;
  }

  Future<void> _openTaskDetails(String taskId) async {
    if (taskId.isEmpty) return;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: _TaskDetailSheet(
            taskId: taskId,
            onEditTask: _editTask,
            onDeleteTask: _deleteTask,
            onCompleteTask: _markTaskComplete,
            onOpenAttachment: _openAttachment,
          ),
        );
      },
    );
    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _openAttachment(String attachmentId) async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await ref
          .read(routeDataRepositoryProvider)
          .downloadAttachment(attachmentId);
      final url = result['url']?.toString() ?? '';
      if (url.isEmpty) throw Exception('empty_url');
      final uri = Uri.tryParse(url);
      if (uri == null) throw Exception('invalid_url');
      final launched = await ref.read(externalUrlLauncherProvider).launch(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.attachmentOpenFailed)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.attachmentOpenFailed)));
    }
  }

  Future<_UploadResult> _uploadTaskAttachments({
    required String taskId,
    required String organizationId,
    required List<PlatformFile> files,
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    var successCount = 0;
    var failedCount = 0;

    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        failedCount++;
        continue;
      }

      final safeFileName = _sanitizeFileName(file.name);
      final objectPath =
          'orgs/$organizationId/tasks/$taskId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      final storagePath = 'attachments/$objectPath';

      try {
        await supabase.storage.from('attachments').uploadBinary(
              objectPath,
              bytes,
              fileOptions: FileOptions(
                upsert: false,
                contentType: _guessContentType(file),
              ),
            );

        final inserted = await supabase
            .from('attachments')
            .insert({
              'organization_id': organizationId,
              'file_name': file.name,
              'content_type': _guessContentType(file),
              'size_bytes': file.size,
              'storage_path': storagePath,
            })
            .select('id')
            .single();

        final attachmentId = inserted['id']?.toString() ?? '';
        if (attachmentId.isEmpty) {
          failedCount++;
          continue;
        }

        await supabase.from('task_attachments').insert({
          'task_id': taskId,
          'attachment_id': attachmentId,
        });
        successCount++;
      } catch (_) {
        failedCount++;
      }
    }

    return _UploadResult(successCount: successCount, failedCount: failedCount);
  }

  String _guessContentType(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';
    if (extension == 'png') return 'image/png';
    if (extension == 'jpg' || extension == 'jpeg') return 'image/jpeg';
    if (extension == 'gif') return 'image/gif';
    if (extension == 'webp') return 'image/webp';
    if (extension == 'pdf') return 'application/pdf';
    if (extension == 'csv') return 'text/csv';
    if (extension == 'txt') return 'text/plain';
    if (extension == 'json') return 'application/json';
    if (extension == 'zip') return 'application/zip';
    if (extension == 'xlsx') {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (extension == 'docx') {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (extension == 'pptx') {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    return 'application/octet-stream';
  }

  String _sanitizeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (sanitized.isEmpty) return 'file.bin';
    return sanitized;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  List<_AttachmentInfo> _extractAttachments(Map<String, dynamic> task) {
    final rows = task['task_attachments'];
    if (rows is! List) return const [];

    return rows
        .whereType<Map>()
        .map((row) {
          final attachment = row['attachments'];
          final attachmentId =
              row['attachment_id']?.toString() ??
              (attachment is Map ? attachment['id']?.toString() : null) ??
              '';
          final name = attachment is Map
              ? attachment['file_name']?.toString() ?? ''
              : '';
          if (attachmentId.isEmpty || name.isEmpty) return null;
          return _AttachmentInfo(id: attachmentId, name: name);
        })
        .whereType<_AttachmentInfo>()
        .toList(growable: false);
  }

  List<String> _extractAssigneeIds(Map<String, dynamic> task) {
    final rows = task['task_assignees'];
    if (rows is! List) return const [];

    return rows
        .whereType<Map>()
        .map((row) => _userIdFromRow(row))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  String _userIdFromRow(Map<dynamic, dynamic> row) {
    return row['userId']?.toString() ??
        row['user_id']?.toString() ??
        (row['users'] is Map ? row['users']['id']?.toString() : null) ??
        row['id']?.toString() ??
        '';
  }

  Color _priorityColor(BuildContext context, String priority) {
    switch (priority) {
      case 'high':
        return Theme.of(context).colorScheme.errorContainer;
      case 'low':
        return Theme.of(context).colorScheme.secondaryContainer;
      case 'medium':
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  String _priorityLabel(AppLocalizations l10n, String priority) {
    switch (priority) {
      case 'high':
        return l10n.priorityHigh;
      case 'low':
        return l10n.priorityLow;
      case 'medium':
      default:
        return l10n.priorityMedium;
    }
  }

  Future<void> _handleTaskAction(
    _TaskAction action,
    Map<String, dynamic> task,
  ) async {
    final taskId = task['id']?.toString() ?? '';
    switch (action) {
      case _TaskAction.edit:
        await _editTask(task);
      case _TaskAction.delete:
        await _deleteTask(taskId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return ListView(
                children: [
                  _buildScopeSelector(l10n),
                  const SizedBox(height: 120),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  _buildScopeSelector(l10n),
                  const SizedBox(height: 120),
                  Center(child: Text('${l10n.apiError}: ${snapshot.error}')),
                ],
              );
            }

            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) {
              return ListView(
                children: [
                  _buildScopeSelector(l10n),
                  const SizedBox(height: 120),
                  Center(child: Text(l10n.noData)),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: rows.length,
              separatorBuilder: (context, index) => index == 0
                  ? const SizedBox.shrink()
                  : const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScopeSelector(l10n),
                      const SizedBox(height: 4),
                      _buildTaskCard(context, l10n, rows[index]),
                    ],
                  );
                }
                return _buildTaskCard(context, l10n, rows[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add),
        label: Text(l10n.createTask),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> task,
  ) {
    final taskId = task['id']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'open';
    final priority = task['priority']?.toString() ?? 'medium';
    final dueAt = _parseDateTime(task['due_at']?.toString());
    final dueText = dueAt == null
        ? '-'
        : DateFormat.yMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(dueAt);
    final description = task['description']?.toString() ?? '';
    final attachments = _extractAttachments(task);

    return Card(
      child: ListTile(
        onTap: taskId.isEmpty ? null : () => _openTaskDetails(taskId),
        title: Text(task['title']?.toString() ?? '-'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) Text(description),
            Text('${l10n.taskDueDate}: $dueText'),
            if (attachments.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final attachment in attachments)
                    ActionChip(
                      avatar: const Icon(Icons.attach_file, size: 16),
                      label: Text(attachment.name),
                      onPressed: () => _openAttachment(attachment.id),
                    ),
                ],
              ),
          ],
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Chip(
                  label: Text(
                    _priorityLabel(l10n, priority),
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: _priorityColor(context, priority),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: l10n.markComplete,
                onPressed: taskId.isEmpty || status == 'completed'
                    ? null
                    : () => _markTaskComplete(taskId),
              ),
              PopupMenuButton<_TaskAction>(
                onSelected: (action) => _handleTaskAction(action, task),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _TaskAction.edit,
                    child: Text(l10n.edit),
                  ),
                  PopupMenuItem(
                    value: _TaskAction.delete,
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskDetailSheet extends ConsumerStatefulWidget {
  const _TaskDetailSheet({
    required this.taskId,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onCompleteTask,
    required this.onOpenAttachment,
  });

  final String taskId;
  final Future<bool> Function(Map<String, dynamic> task) onEditTask;
  final Future<bool> Function(String taskId) onDeleteTask;
  final Future<bool> Function(String taskId) onCompleteTask;
  final Future<void> Function(String attachmentId) onOpenAttachment;

  @override
  ConsumerState<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<_TaskDetailSheet> {
  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<Map<String, dynamic>> _loadDetail() {
    return ref.read(routeDataRepositoryProvider).getTaskById(widget.taskId);
  }

  Future<void> _refreshDetail() async {
    setState(() {
      _detailFuture = _loadDetail();
    });
    await _detailFuture;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  List<_AttachmentInfo> _extractAttachments(Map<String, dynamic> task) {
    final rows = task['task_attachments'];
    if (rows is! List) return const [];

    return rows
        .whereType<Map>()
        .map((row) {
          final attachment = row['attachments'];
          final attachmentId =
              row['attachment_id']?.toString() ??
              (attachment is Map ? attachment['id']?.toString() : null) ??
              '';
          final name = attachment is Map
              ? attachment['file_name']?.toString() ?? ''
              : '';
          if (attachmentId.isEmpty || name.isEmpty) return null;
          return _AttachmentInfo(id: attachmentId, name: name);
        })
        .whereType<_AttachmentInfo>()
        .toList(growable: false);
  }

  List<String> _extractAssignees(Map<String, dynamic> task) {
    final rows = task['task_assignees'];
    if (rows is! List) return const [];

    return rows
        .whereType<Map>()
        .map((row) {
          final user = row['users'];
          if (user is Map) {
            return user['display_name']?.toString() ??
                user['email']?.toString() ??
                '';
          }
          return '';
        })
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  String _priorityLabel(AppLocalizations l10n, String priority) {
    switch (priority) {
      case 'high':
        return l10n.priorityHigh;
      case 'low':
        return l10n.priorityLow;
      case 'medium':
      default:
        return l10n.priorityMedium;
    }
  }

  Future<void> _handleEdit(Map<String, dynamic> task) async {
    final updated = await widget.onEditTask(task);
    if (updated) {
      await _refreshDetail();
    }
  }

  Future<void> _handleDelete() async {
    final deleted = await widget.onDeleteTask(widget.taskId);
    if (deleted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleComplete() async {
    final completed = await widget.onCompleteTask(widget.taskId);
    if (completed) {
      await _refreshDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l10n.apiError}: ${snapshot.error}'));
          }

          final task = snapshot.data ?? const <String, dynamic>{};
          final status = task['status']?.toString() ?? 'open';
          final dueAt = _parseDateTime(task['due_at']?.toString());
          final dueText = dueAt == null
              ? '-'
              : DateFormat.yMd(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(dueAt);
          final attachments = _extractAttachments(task);
          final assignees = _extractAssignees(task);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task['title']?.toString() ?? l10n.taskDetails,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.edit,
                      onPressed: () => _handleEdit(task),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: l10n.delete,
                      onPressed: _handleDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(task['description']?.toString() ?? ''),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(status)),
                    Chip(
                      label: Text(
                        _priorityLabel(
                          l10n,
                          task['priority']?.toString() ?? 'medium',
                        ),
                      ),
                    ),
                    Chip(label: Text('${l10n.taskDueDate}: $dueText')),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.taskAssignees,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (assignees.isEmpty)
                  Text(l10n.noAssigneesAssigned)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assignees
                        .map((name) => Chip(label: Text(name)))
                        .toList(growable: false),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.taskAttachments,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (attachments.isEmpty)
                  Text(l10n.noAttachments)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: attachments
                        .map(
                          (attachment) => ActionChip(
                            avatar: const Icon(Icons.attach_file, size: 16),
                            label: Text(attachment.name),
                            onPressed: () =>
                                widget.onOpenAttachment(attachment.id),
                          ),
                        )
                        .toList(growable: false),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: status == 'completed' ? null : _handleComplete,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.markComplete),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _TaskListScope { my, created, all }

enum _TaskAction { edit, delete }

class _TaskDraft {
  const _TaskDraft({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.assigneeUserIds,
    required this.attachments,
  });

  final String title;
  final String description;
  final DateTime? dueDate;
  final String priority;
  final List<String> assigneeUserIds;
  final List<PlatformFile> attachments;
}

class _UploadResult {
  const _UploadResult({required this.successCount, required this.failedCount});

  final int successCount;
  final int failedCount;
}

class _AttachmentInfo {
  const _AttachmentInfo({required this.id, required this.name});

  final String id;
  final String name;
}
