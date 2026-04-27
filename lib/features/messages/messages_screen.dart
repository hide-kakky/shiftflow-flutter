import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/session_providers.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  ProviderSubscription<Map<String, dynamic>?>? _currentUnitSubscription;
  bool _loadingFolders = false;
  List<Map<String, dynamic>> _folders = const [];
  Map<String, int> _folderUnreadCounts = const {};
  String? _selectedFolderId;
  String _selectedScope = 'all';
  String _selectedTab = 'current';
  String? _selectedUnitId;
  final Map<String, bool> _readOverrides = <String, bool>{};
  final Set<String> _selectedMessageIds = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedUnitId = ref.read(currentUnitProvider)?['id']?.toString();
    _currentUnitSubscription = ref.listenManual(currentUnitProvider, (
      _,
      next,
    ) async {
      final nextUnitId = next?['id']?.toString();
      if (!mounted || nextUnitId == null || nextUnitId == _selectedUnitId) {
        return;
      }
      setState(() {
        _selectedUnitId = nextUnitId;
        _selectedTab = 'current';
        _selectedFolderId = null;
      });
      await _loadFolders();
      await _refresh();
    });
    _loadFolders();
    _future = _load();
  }

  @override
  void dispose() {
    _currentUnitSubscription?.close();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final repository = ref.read(routeDataRepositoryProvider);
    if (_selectedScope == 'all') {
      final results = await Future.wait([
        repository.getMessages(
          currentUnitId: _selectedUnitId,
          tab: _selectedTab,
          folderId: _selectedFolderId,
          scope: 'shared',
        ),
        repository.getMessages(
          currentUnitId: _selectedUnitId,
          tab: _selectedTab,
          scope: 'direct',
        ),
      ]);
      final merged = [...results[0], ...results[1]];
      merged.sort((a, b) {
        final left =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final right =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return merged;
    }
    return repository.getMessages(
      currentUnitId: _selectedUnitId,
      tab: _selectedTab,
      folderId: _selectedScope == 'shared' ? _selectedFolderId : null,
      scope: _selectedScope == 'dm' ? 'direct' : 'shared',
    );
  }

  Future<void> _loadFolders() async {
    setState(() {
      _loadingFolders = true;
    });
    try {
      final repository = ref.read(routeDataRepositoryProvider);
      final result = await repository.listActiveFolders();
      final sharedMessages = await repository.getMessages(
        currentUnitId: _selectedUnitId,
        tab: 'current',
        scope: 'shared',
      );
      final unreadCounts = <String, int>{};
      for (final message in sharedMessages) {
        final folderId = message['folder_id']?.toString() ?? '';
        if (folderId.isEmpty) continue;
        final isRead =
            _readOverrides[message['id']?.toString() ?? ''] ??
            (message['isRead'] == true);
        if (!isRead) {
          unreadCounts.update(folderId, (value) => value + 1, ifAbsent: () => 1);
        }
      }
      if (!mounted) return;
      setState(() {
        _folders = result
            .where(
              (row) =>
                  _selectedUnitId == null ||
                  _selectedUnitId!.isEmpty ||
                  row['unit_id']?.toString() == _selectedUnitId,
            )
            .toList(growable: false);
        _folderUnreadCounts = unreadCounts;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _folders = const [];
        _folderUnreadCounts = const {};
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingFolders = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadFolders();
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _createMessage() async {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final repository = ref.read(routeDataRepositoryProvider);
    List<Map<String, dynamic>> folders = const [];
    List<Map<String, dynamic>> users = const [];
    try {
      folders = await repository.listActiveFolders();
      users = await repository.listActiveUsers();
    } catch (_) {
      folders = const [];
      users = const [];
    }
    if (!mounted) return;

    String? selectedFolderId;
    String? selectedTemplateId;
    final selectedRecipientUserIds = <String>{};
    var templates = <Map<String, dynamic>>[];
    var loadingTemplates = false;
    final selectedFiles = <PlatformFile>[];

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.createMessage),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedScope == 'shared')
                      DropdownButtonFormField<String?>(
                        initialValue: selectedFolderId,
                        decoration: InputDecoration(
                          labelText: l10n.adminSelectFolder,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.noFolderSelected),
                          ),
                          for (final folder in folders)
                            DropdownMenuItem<String?>(
                              value: folder['id']?.toString(),
                              child: Text(folder['name']?.toString() ?? '-'),
                            ),
                        ],
                        onChanged: (value) async {
                          setDialogState(() {
                            selectedFolderId = value;
                            selectedTemplateId = null;
                            templates = <Map<String, dynamic>>[];
                            loadingTemplates =
                                value != null && value.isNotEmpty;
                          });
                          if (value == null || value.isEmpty) return;

                          try {
                            final loaded = await repository.listTemplates(
                              value,
                            );
                            setDialogState(() {
                              templates = loaded;
                              loadingTemplates = false;
                            });
                          } catch (_) {
                            setDialogState(() {
                              templates = <Map<String, dynamic>>[];
                              loadingTemplates = false;
                            });
                          }
                        },
                      ),
                    if (_selectedScope == 'dm') ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '送信先ユーザー',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final user in users)
                            FilterChip(
                              label: Text(
                                user['displayName']?.toString() ??
                                    user['email']?.toString() ??
                                    '-',
                              ),
                              selected: selectedRecipientUserIds.contains(
                                user['userId']?.toString(),
                              ),
                              onSelected: (selected) {
                                final userId = user['userId']?.toString();
                                if (userId == null || userId.isEmpty) return;
                                setDialogState(() {
                                  if (selected) {
                                    selectedRecipientUserIds.add(userId);
                                  } else {
                                    selectedRecipientUserIds.remove(userId);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_selectedScope == 'shared')
                      if (loadingTemplates)
                        const LinearProgressIndicator()
                      else
                        DropdownButtonFormField<String?>(
                          initialValue: selectedTemplateId,
                          decoration: InputDecoration(
                            labelText: l10n.templates,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.noTemplateSelected),
                            ),
                            for (final template in templates)
                              DropdownMenuItem<String?>(
                                value: template['id']?.toString(),
                                child: Text(
                                  template['name']?.toString() ?? '-',
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedTemplateId = value;
                            });
                            if (value == null || value.isEmpty) return;
                            final selected = templates.firstWhere(
                              (item) => item['id']?.toString() == value,
                              orElse: () => const <String, dynamic>{},
                            );
                            final templateTitle =
                                selected['title_format']?.toString() ?? '';
                            final templateBody =
                                selected['body_format']?.toString() ?? '';
                            setDialogState(() {
                              if (templateTitle.isNotEmpty) {
                                titleController.text = templateTitle;
                              }
                              if (templateBody.isNotEmpty) {
                                bodyController.text = templateBody;
                              }
                            });
                          },
                        )
                    else
                      const Text('個人メッセージではフォルダと定型文は使いません。'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: l10n.title),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(labelText: l10n.body),
                    ),
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
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );

    if (created == true) {
      final title = titleController.text.trim();
      if (title.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.messageTitleRequired)));
        return;
      }

      if (_selectedScope == 'dm' && selectedRecipientUserIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('個人メッセージの送信先を選択してください。')));
        return;
      }

      if (!mounted) return;
      final confirmation = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('送信内容の確認'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '送信先種別: ${_selectedScope == 'dm' ? '個人メッセージ' : '共有メッセージ'}',
              ),
              Text('対象ユニット: ${_selectedUnitId ?? '未指定'}'),
              Text(
                'フォルダ: ${_selectedScope == 'dm' ? '対象外' : (selectedFolderId ?? '未指定')}',
              ),
              Text(
                '宛先人数: ${_selectedScope == 'dm' ? selectedRecipientUserIds.length : 0}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('戻る'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('送信する'),
            ),
          ],
        ),
      );
      if (confirmation != true) return;

      final createdMessage = await repository.addNewMessage(
        title: title,
        body: bodyController.text.trim(),
        scope: _selectedScope == 'dm' ? 'direct' : 'shared',
        unitId: _selectedUnitId,
        folderId: _selectedScope == 'dm' ? null : selectedFolderId,
        recipientUserIds: _selectedScope == 'dm'
            ? selectedRecipientUserIds.toList(growable: false)
            : null,
      );
      if (selectedFiles.isNotEmpty) {
        final messageId = createdMessage['id']?.toString() ?? '';
        final orgId = createdMessage['organization_id']?.toString() ?? '';
        if (messageId.isNotEmpty && orgId.isNotEmpty) {
          final result = await _uploadMessageAttachments(
            messageId: messageId,
            organizationId: orgId,
            files: selectedFiles,
          );
          if (!mounted) return;
          if (result.failedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${l10n.messageAttachmentPartialUpload}: ${result.successCount}/${selectedFiles.length}',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.messageAttachmentUploadSuccess)),
            );
          }
        }
      }
      await _refresh();
    }
  }

  Future<_UploadResult> _uploadMessageAttachments({
    required String messageId,
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
          'orgs/$organizationId/messages/$messageId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      final storagePath = 'attachments/$objectPath';

      try {
        await supabase.storage
            .from('attachments')
            .uploadBinary(
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

        await supabase.from('message_attachments').insert({
          'message_id': messageId,
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

  Future<void> _toggleRead(String messageId) async {
    final result = await ref
        .read(routeDataRepositoryProvider)
        .toggleMemoRead(messageId);
    if (!mounted) return;
    setState(() {
      _readOverrides[messageId] = result['isRead'] == true;
    });
    await _loadFolders();
  }

  Future<void> _markSelectedRead() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedMessageIds.isEmpty) return;
    await ref
        .read(routeDataRepositoryProvider)
        .markMemosReadBulk(_selectedMessageIds.toList(growable: false));
    if (!mounted) return;
    setState(() {
      for (final messageId in _selectedMessageIds) {
        _readOverrides[messageId] = true;
      }
      _selectedMessageIds.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.messagesMarkedRead)));
    await _refresh();
  }

  void _toggleSelection(String messageId) {
    if (messageId.isEmpty) return;
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  void _setFolderFilter(String? folderId) {
    setState(() {
      _selectedFolderId = folderId;
      _future = _load();
    });
  }

  void _setScope(String scope) {
    setState(() {
      _selectedScope = scope;
      if (scope == 'dm' || scope == 'all') {
        _selectedFolderId = null;
      }
      _future = _load();
    });
  }

  void _setTab(String tab) {
    setState(() {
      _selectedTab = tab;
      _future = _load();
    });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.attachmentOpenFailed)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.attachmentOpenFailed)));
    }
  }

  Future<void> _changeCurrentUnit(String? unitId) async {
    if (unitId == null || unitId.isEmpty) return;
    await ref.read(routeDataRepositoryProvider).changeCurrentUnit(unitId);
    ref.invalidate(bootstrapDataProvider);
    setState(() {
      _selectedUnitId = unitId;
      _selectedTab = 'current';
      _selectedFolderId = null;
    });
    await _loadFolders();
    await _refresh();
  }

  Widget _buildFilters(AppLocalizations l10n) {
    final currentUnit = ref.watch(currentUnitProvider);
    final availableUnits = ref.watch(availableUnitsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('ALL'),
                selected: _selectedScope == 'all',
                onSelected: (_) => _setScope('all'),
              ),
              ChoiceChip(
                label: const Text('Message'),
                selected: _selectedScope == 'shared',
                onSelected: (_) => _setScope('shared'),
              ),
              ChoiceChip(
                label: const Text('DM'),
                selected: _selectedScope == 'dm',
                onSelected: (_) => _setScope('dm'),
              ),
            ],
          ),
          if (_selectedScope == 'shared') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(
                    '現在地ユニット: ${currentUnit?['name']?.toString() ?? '未設定'}',
                  ),
                  selected: _selectedTab == 'current',
                  onSelected: (_) => _setTab('current'),
                ),
                ChoiceChip(
                  label: const Text('他ユニット'),
                  selected: _selectedTab == 'other',
                  onSelected: (_) => _setTab('other'),
                ),
              ],
            ),
            if (_selectedTab == 'current' && _selectedFolderId != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _setFolderFilter(null),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('フォルダ一覧へ戻る'),
                ),
              ),
            ],
            if (_selectedTab == 'other') ...[
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final unit in availableUnits)
                      if (unit['id']?.toString() != _selectedUnitId)
                        ListTile(
                          leading: const Icon(Icons.account_tree_outlined),
                          title: Text(
                            unit['pathText']?.toString() ??
                                unit['name']?.toString() ??
                                '-',
                          ),
                          onTap: () =>
                              _changeCurrentUnit(unit['id']?.toString()),
                        ),
                  ],
                ),
              ),
            ],
          ],
          if (_selectedMessageIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.selectedMessages(_selectedMessageIds.length),
                  ),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  child: Text(l10n.clearSelection),
                ),
                FilledButton(
                  onPressed: _markSelectedRead,
                  child: Text(l10n.markSelectedRead),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    AppLocalizations l10n,
    Map<String, dynamic> message,
  ) {
    final messageId = message['id']?.toString() ?? '';
    final fallbackRead = message['isRead'] == true;
    final isRead = _readOverrides[messageId] ?? fallbackRead;
    final isPinned = message['is_pinned'] == true;
    final title = message['title']?.toString() ?? '-';
    final body = message['body']?.toString() ?? '';
    final isDirect =
        message['isDirect'] == true ||
        message['message_scope']?.toString() == 'direct';
    final selecting = _selectedMessageIds.isNotEmpty;
    final selected = _selectedMessageIds.contains(messageId);

    return Card(
      color: isRead
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isRead
              ? Theme.of(context).dividerColor.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
          width: isRead ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: messageId.isEmpty
            ? null
            : selecting
            ? () => _toggleSelection(messageId)
            : () => _openDetails(messageId: messageId, title: title),
        onLongPress: messageId.isEmpty
            ? null
            : () => _toggleSelection(messageId),
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(child: Text(title)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isRead ? '既読' : '未読',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isRead
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isDirect)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.mail_outline, size: 18),
              ),
            if (isPinned)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.push_pin, size: 18),
              ),
          ],
        ),
        subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
        leading: selecting
            ? Checkbox(
                value: selected,
                onChanged: (_) => _toggleSelection(messageId),
              )
            : Icon(
                isRead
                    ? Icons.mark_email_read_outlined
                    : Icons.mark_email_unread_outlined,
              ),
        trailing: IconButton(
          tooltip: l10n.toggleRead,
          icon: const Icon(Icons.done_all),
          onPressed: messageId.isEmpty ? null : () => _toggleRead(messageId),
        ),
      ),
    );
  }

  Future<void> _openDetails({
    required String messageId,
    required String title,
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: _MessageDetailSheet(
            messageId: messageId,
            fallbackTitle: title,
            onDeleteMessage: _deleteMessage,
            onOpenAttachment: _openAttachment,
          ),
        );
      },
    );
    if (changed == true) {
      await _refresh();
    }
  }

  Future<bool> _deleteMessage(String messageId) async {
    final l10n = AppLocalizations.of(context);
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

    await ref.read(routeDataRepositoryProvider).deleteMessageById(messageId);
    if (!mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.messageDeleted)));
    await _refresh();
    return true;
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
                  _buildFilters(l10n),
                  const SizedBox(height: 120),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  _buildFilters(l10n),
                  const SizedBox(height: 120),
                  Center(child: Text('${l10n.apiError}: ${snapshot.error}')),
                ],
              );
            }

            final rows = snapshot.data ?? const [];
            if (_selectedScope == 'shared' &&
                _selectedTab == 'current' &&
                _selectedFolderId == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                children: [
                  _buildFilters(l10n),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '現在地ユニットのフォルダ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_loadingFolders)
                            const Center(child: CircularProgressIndicator())
                          else if (_folders.isEmpty)
                            const Text('表示できるフォルダはありません。')
                          else
                            ..._folders.map(
                              (folder) {
                                final folderId = folder['id']?.toString() ?? '';
                                final unreadCount =
                                    _folderUnreadCounts[folderId] ?? 0;
                                return ListTile(
                                  leading: const Icon(Icons.folder_outlined),
                                  title: Text(folder['name']?.toString() ?? '-'),
                                  subtitle: Text(
                                    folder['is_public'] == true ? '公開' : '限定',
                                  ),
                                  trailing: unreadCount > 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            unreadCount.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onError,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        )
                                      : null,
                                  onTap: () =>
                                      _setFolderFilter(folder['id']?.toString()),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (rows.isEmpty) {
              return ListView(
                children: [
                  _buildFilters(l10n),
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
                      _buildFilters(l10n),
                      const SizedBox(height: 4),
                      _buildMessageCard(l10n, rows[index]),
                    ],
                  );
                }
                return _buildMessageCard(l10n, rows[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createMessage,
        icon: const Icon(Icons.add),
        label: Text(l10n.createMessage),
      ),
    );
  }
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

class _MessageDetailSheet extends ConsumerStatefulWidget {
  const _MessageDetailSheet({
    required this.messageId,
    required this.fallbackTitle,
    required this.onDeleteMessage,
    required this.onOpenAttachment,
  });

  final String messageId;
  final String fallbackTitle;
  final Future<bool> Function(String messageId) onDeleteMessage;
  final Future<void> Function(String attachmentId) onOpenAttachment;

  @override
  ConsumerState<_MessageDetailSheet> createState() =>
      _MessageDetailSheetState();
}

class _MessageDetailSheetState extends ConsumerState<_MessageDetailSheet> {
  late Future<Map<String, dynamic>> _detailFuture;
  Future<Map<String, dynamic>>? _readStatusFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<Map<String, dynamic>> _loadDetail() {
    return ref
        .read(routeDataRepositoryProvider)
        .getMessageById(widget.messageId);
  }

  Future<void> _refreshDetail() async {
    setState(() {
      _detailFuture = _loadDetail();
    });
    await _detailFuture;
  }

  List<_AttachmentInfo> _extractAttachments(Map<String, dynamic> message) {
    final rows = message['message_attachments'];
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

  Future<void> _togglePin() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(routeDataRepositoryProvider).pinMessage(widget.messageId);
      await _refreshDetail();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pinActionDenied)));
    }
  }

  Future<void> _toggleRead() async {
    await ref
        .read(routeDataRepositoryProvider)
        .toggleMemoRead(widget.messageId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).readStateUpdated)),
    );
  }

  Future<void> _loadReadStatus() async {
    setState(() {
      _readStatusFuture = ref
          .read(routeDataRepositoryProvider)
          .messageReadStatus(widget.messageId);
    });
  }

  Future<void> _openCommentDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addComment),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(labelText: l10n.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;
    final body = controller.text.trim();
    if (body.isEmpty) return;

    await ref
        .read(routeDataRepositoryProvider)
        .addNewComment(messageId: widget.messageId, body: body);
    await _refreshDetail();
  }

  Future<void> _handleDelete() async {
    final deleted = await widget.onDeleteMessage(widget.messageId);
    if (deleted && mounted) {
      Navigator.of(context).pop(true);
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

          final message = snapshot.data ?? const <String, dynamic>{};
          final title = message['title']?.toString() ?? widget.fallbackTitle;
          final body = message['body']?.toString() ?? '';
          final isPinned = message['is_pinned'] == true;
          final comments = (message['comments'] is List)
              ? (message['comments'] as List).whereType<Map>().toList(
                  growable: false,
                )
              : const <Map>[];
          final attachments = _extractAttachments(message);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.pinMessage,
                      onPressed: _togglePin,
                      icon: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.toggleRead,
                      onPressed: _toggleRead,
                      icon: const Icon(Icons.done_all),
                    ),
                    IconButton(
                      tooltip: l10n.delete,
                      onPressed: _handleDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(body),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      l10n.readStatus,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _loadReadStatus,
                      child: Text(l10n.load),
                    ),
                  ],
                ),
                if (_readStatusFuture != null)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _readStatusFuture,
                    builder: (context, readSnapshot) {
                      if (readSnapshot.connectionState !=
                          ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        );
                      }
                      if (readSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(l10n.readStatusLimited),
                        );
                      }
                      final status =
                          readSnapshot.data ?? const <String, dynamic>{};
                      final readUsers =
                          (status['readUsers'] as List?) ?? const [];
                      final unreadUsers =
                          (status['unreadUsers'] as List?) ?? const [];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l10n.readUsers} (${readUsers.length})'),
                            Wrap(
                              spacing: 6,
                              children: readUsers
                                  .map((entry) {
                                    final map = entry as Map;
                                    final name =
                                        (map['displayName'] ??
                                                map['email'] ??
                                                '-')
                                            .toString();
                                    return Chip(label: Text(name));
                                  })
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 4),
                            Text('${l10n.unreadUsers} (${unreadUsers.length})'),
                            Wrap(
                              spacing: 6,
                              children: unreadUsers
                                  .map((entry) {
                                    final map = entry as Map;
                                    final name =
                                        (map['displayName'] ??
                                                map['email'] ??
                                                '-')
                                            .toString();
                                    return Chip(label: Text(name));
                                  })
                                  .toList(growable: false),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.comments,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _openCommentDialog,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: Text(l10n.addComment),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: comments.isEmpty
                      ? Center(child: Text(l10n.noComments))
                      : ListView.separated(
                          itemCount: comments.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final author = comment['author_display_name']
                                ?.toString();
                            final fallback =
                                comment['author_email']?.toString() ?? '-';
                            final createdAt =
                                comment['created_at']?.toString() ?? '';
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                author?.isNotEmpty == true ? author! : fallback,
                              ),
                              subtitle: Text(comment['body']?.toString() ?? ''),
                              trailing: createdAt.isEmpty
                                  ? null
                                  : Text(
                                      createdAt,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
