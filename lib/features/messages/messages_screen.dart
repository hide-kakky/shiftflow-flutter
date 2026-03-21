import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

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

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createMessage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: l10n.title),
            ),
            TextField(
              controller: bodyController,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.body),
            ),
          ],
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

    if (created == true && titleController.text.trim().isNotEmpty) {
      await ref.read(routeDataRepositoryProvider).addNewMessage(
            title: titleController.text.trim(),
            body: bodyController.text.trim(),
          );
      await _refresh();
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
                final isRead = message['isRead'] == true;
                final messageId = message['id']?.toString() ?? '';
                return Card(
                  child: ListTile(
                    title: Text(message['title']?.toString() ?? '-'),
                    subtitle: Text(message['body']?.toString() ?? ''),
                    leading: Icon(
                      isRead
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.done_all),
                      onPressed: messageId.isEmpty
                          ? null
                          : () async {
                              await ref
                                  .read(routeDataRepositoryProvider)
                                  .toggleMemoRead(messageId);
                              await _refresh();
                            },
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
