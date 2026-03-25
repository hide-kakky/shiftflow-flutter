import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final Map<String, bool> _readOverrides = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(routeDataRepositoryProvider).getMessages();
  }

  Future<void> _refresh() async {
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
    try {
      folders = await repository.listActiveFolders();
    } catch (_) {
      folders = const [];
    }
    if (!mounted) return;

    String? selectedFolderId;
    String? selectedTemplateId;
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
                          loadingTemplates = value != null && value.isNotEmpty;
                        });
                        if (value == null || value.isEmpty) return;

                        try {
                          final loaded = await repository.listTemplates(value);
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
                    const SizedBox(height: 12),
                    if (loadingTemplates)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<String?>(
                        initialValue: selectedTemplateId,
                        decoration: InputDecoration(labelText: l10n.templates),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.noTemplateSelected),
                          ),
                          for (final template in templates)
                            DropdownMenuItem<String?>(
                              value: template['id']?.toString(),
                              child: Text(template['name']?.toString() ?? '-'),
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
                      ),
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

      final createdMessage = await repository.addNewMessage(
        title: title,
        body: bodyController.text.trim(),
        folderId: selectedFolderId,
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
  }

  Future<void> _openDetails({
    required String messageId,
    required String title,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: _MessageDetailSheet(
            messageId: messageId,
            fallbackTitle: title,
          ),
        );
      },
    );
    await _refresh();
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
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('${l10n.apiError}: ${snapshot.error}')),
                ],
              );
            }

            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(l10n.noData)),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final message = rows[index];
                final messageId = message['id']?.toString() ?? '';
                final fallbackRead = message['isRead'] == true;
                final isRead = _readOverrides[messageId] ?? fallbackRead;
                final isPinned = message['is_pinned'] == true;
                final title = message['title']?.toString() ?? '-';
                final body = message['body']?.toString() ?? '';

                return Card(
                  child: ListTile(
                    onTap: messageId.isEmpty
                        ? null
                        : () =>
                              _openDetails(messageId: messageId, title: title),
                    title: Row(
                      children: [
                        Expanded(child: Text(title)),
                        if (isPinned)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.push_pin, size: 18),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Icon(
                      isRead
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                    ),
                    trailing: IconButton(
                      tooltip: l10n.toggleRead,
                      icon: const Icon(Icons.done_all),
                      onPressed: messageId.isEmpty
                          ? null
                          : () => _toggleRead(messageId),
                    ),
                  ),
                );
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

class _MessageDetailSheet extends ConsumerStatefulWidget {
  const _MessageDetailSheet({
    required this.messageId,
    required this.fallbackTitle,
  });

  final String messageId;
  final String fallbackTitle;

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
                  ],
                ),
                const SizedBox(height: 8),
                Text(body),
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
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                author?.isNotEmpty == true ? author! : fallback,
                              ),
                              subtitle: Text(comment['body']?.toString() ?? ''),
                              trailing: Text(
                                createdAt.length >= 16
                                    ? createdAt.substring(0, 16)
                                    : createdAt,
                                style: Theme.of(context).textTheme.bodySmall,
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
