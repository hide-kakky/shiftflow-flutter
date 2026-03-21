import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(routeDataRepositoryProvider).listMyTasks();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _createTask() async {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createTask),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: l10n.title),
            ),
            TextField(
              controller: bodyController,
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
      try {
        await ref.read(routeDataRepositoryProvider).addNewTask(
              title: titleController.text.trim(),
              description: bodyController.text.trim(),
            );
        await _refresh();
      } catch (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$err')));
      }
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
                final task = rows[index];
                final taskId = task['id']?.toString() ?? '';
                final status = task['status']?.toString() ?? 'open';
                return Card(
                  child: ListTile(
                    title: Text(task['title']?.toString() ?? '-'),
                    subtitle: Text(task['description']?.toString() ?? ''),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(status)),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          tooltip: l10n.markComplete,
                          onPressed: taskId.isEmpty || status == 'completed'
                              ? null
                              : () async {
                                  await ref
                                      .read(routeDataRepositoryProvider)
                                      .completeTask(taskId);
                                  await _refresh();
                                },
                        ),
                      ],
                    ),
                  ),
                );
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
}
