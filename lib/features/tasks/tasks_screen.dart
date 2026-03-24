import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final repository = ref.read(routeDataRepositoryProvider);

    List<Map<String, dynamic>> users = const [];
    try {
      users = await repository.listActiveUsers();
    } catch (_) {
      users = const [];
    }

    if (!mounted) return;

    DateTime? dueDate;
    var priority = 'medium';
    final selectedAssignees = <String>{};

    final draft = await showDialog<_TaskDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.createTask),
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
                          DropdownMenuItem(value: 'low', child: Text(l10n.priorityLow)),
                          DropdownMenuItem(value: 'medium', child: Text(l10n.priorityMedium)),
                          DropdownMenuItem(value: 'high', child: Text(l10n.priorityHigh)),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            priority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.taskDueDate, style: Theme.of(context).textTheme.labelLarge),
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
                                firstDate: now.subtract(const Duration(days: 365)),
                                lastDate: now.add(const Duration(days: 3650)),
                                initialDate: dueDate ?? now,
                              );
                              if (picked == null) return;
                              setDialogState(() {
                                dueDate = DateTime(picked.year, picked.month, picked.day, 18);
                              });
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              dueDate == null
                                  ? l10n.selectDueDate
                                  : DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
                                      .format(dueDate!),
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
                      Text(l10n.taskAssignees, style: Theme.of(context).textTheme.labelLarge),
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
                              final userId = user['id']?.toString() ?? '';
                              if (userId.isEmpty) return const SizedBox.shrink();
                              final name = user['display_name']?.toString() ??
                                  user['name']?.toString() ??
                                  user['email']?.toString() ??
                                  userId;
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
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
                              assigneeUserIds: selectedAssignees.toList(growable: false),
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

    if (draft == null) {
      titleController.dispose();
      bodyController.dispose();
      return;
    }

    if (draft.title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskTitleRequired)),
      );
      titleController.dispose();
      bodyController.dispose();
      return;
    }

    try {
      await repository.addNewTask(
        title: draft.title,
        description: draft.description,
        dueAt: draft.dueDate,
        priority: draft.priority,
        assigneeUserIds: draft.assigneeUserIds,
      );
      await _refresh();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      titleController.dispose();
      bodyController.dispose();
    }
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
                final priority = task['priority']?.toString() ?? 'medium';
                final dueAtRaw = task['due_at']?.toString();
                final dueAt = dueAtRaw == null ? null : DateTime.tryParse(dueAtRaw);
                final dueText = dueAt == null
                    ? '-'
                    : DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(dueAt);
                final description = task['description']?.toString() ?? '';

                return Card(
                  child: ListTile(
                    title: Text(task['title']?.toString() ?? '-'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (description.isNotEmpty) Text(description),
                        Text('${l10n.taskDueDate}: $dueText'),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(status)),
                        Chip(
                          label: Text(_priorityLabel(l10n, priority)),
                          backgroundColor: _priorityColor(context, priority),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          tooltip: l10n.markComplete,
                          onPressed: taskId.isEmpty || status == 'completed'
                              ? null
                              : () async {
                                  await ref.read(routeDataRepositoryProvider).completeTask(taskId);
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

class _TaskDraft {
  const _TaskDraft({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.assigneeUserIds,
  });

  final String title;
  final String description;
  final DateTime? dueDate;
  final String priority;
  final List<String> assigneeUserIds;
}
