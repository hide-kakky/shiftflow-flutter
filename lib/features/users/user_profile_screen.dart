import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../shared/session_providers.dart';

List<Map<String, dynamic>> _asListOfMap(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    final currentAppUserId = ref.watch(currentAppUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ユーザープロフィール')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: repo.getUserProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('プロフィールの取得に失敗しました: ${snapshot.error}'));
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final memberships = _asListOfMap(data['unitMemberships']);
          final displayName = data['displayName']?.toString() ?? '-';
          final isSelf = currentAppUserId == userId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            child: Icon(Icons.person_outline),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(data['email']?.toString() ?? ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '組織ロール: ${data['organizationRole']?.toString() ?? '-'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '現在地ユニット: ${data['currentUnitPathText']?.toString() ?? data['currentUnitName']?.toString() ?? '-'}',
                      ),
                      if (!isSelf) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              context.push('/messages/direct/$userId'),
                          icon: const Icon(Icons.mail_outline),
                          label: const Text('DMを送る'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '所属ユニット',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (memberships.isEmpty)
                        const Text('所属ユニットはありません。')
                      else
                        ...memberships.map(
                          (row) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.account_tree_outlined),
                            title: Text(row['unitPathText']?.toString() ?? '-'),
                            subtitle: Text(row['role']?.toString() ?? 'member'),
                            trailing: row['isCurrent'] == true
                                ? const Chip(label: Text('現在地'))
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DirectChatScreen extends ConsumerStatefulWidget {
  const DirectChatScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<Map<String, dynamic>>> _messagesFuture;
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(routeDataRepositoryProvider);
    _profileFuture = repo.getUserProfile(widget.userId);
    _messagesFuture = _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadMessages() async {
    final repo = ref.read(routeDataRepositoryProvider);
    final rows = await repo.getMessages(scope: 'direct');
    final currentUserId = ref.read(currentAppUserIdProvider);
    return rows
        .where((row) {
          final authorUserId = row['author_user_id']?.toString() ?? '';
          final recipientUserId = row['recipient_user_id']?.toString() ?? '';
          return (authorUserId == widget.userId &&
                  recipientUserId == currentUserId) ||
              (authorUserId == currentUserId &&
                  recipientUserId == widget.userId);
        })
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    setState(() {
      _messagesFuture = _loadMessages();
    });
    await _messagesFuture;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
    });
    try {
      await ref
          .read(routeDataRepositoryProvider)
          .addNewMessage(
            title: text,
            body: text,
            scope: 'direct',
            recipientUserIds: [widget.userId],
            unitId: ref.read(currentUnitProvider)?['id']?.toString(),
          );
      _controller.clear();
      await _refresh();
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Text('個人チャット');
            }
            return Text(snapshot.data?['displayName']?.toString() ?? '個人チャット');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('DMの取得に失敗しました: ${snapshot.error}'));
                }
                final rows = snapshot.data ?? const [];
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('まだDMはありません。最初のメッセージを送ってください。'),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final isMine =
                        row['author_user_id']?.toString() ==
                        ref.read(currentAppUserIdProvider);
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Card(
                          color: isMine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(row['body']?.toString() ?? ''),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'メッセージを入力'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
