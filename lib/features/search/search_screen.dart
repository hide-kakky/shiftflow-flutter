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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  late final TabController _tabController;
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_queryController.text.trim().isEmpty) return;
      _search();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String get _selectedTab => switch (_tabController.index) {
    1 => 'tasks',
    2 => 'messages',
    3 => 'users',
    _ => 'all',
  };

  void _search() {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _future = null;
      });
      return;
    }
    final repo = ref.read(routeDataRepositoryProvider);
    final currentUnitId = ref.read(currentUnitProvider)?['id']?.toString();
    setState(() {
      _future = repo.searchContent(
        query: query,
        tab: _selectedTab,
        currentUnitId: currentUnitId,
      );
    });
  }

  Widget _buildUserTile(Map<String, dynamic> row) {
    final userId = row['userId']?.toString() ?? '';
    return ListTile(
      onTap: userId.isEmpty ? null : () => context.push('/users/$userId'),
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(row['displayName']?.toString() ?? '-'),
      subtitle: Text(
        [
          row['email']?.toString() ?? '',
          row['currentUnitName']?.toString() ?? '',
        ].where((value) => value.isNotEmpty).join(' / '),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> row) {
    return ListTile(
      leading: const Icon(Icons.task_alt_outlined),
      title: Text(row['title']?.toString() ?? '-'),
      subtitle: Text(
        [
          row['status']?.toString() ?? '',
          row['unitName']?.toString() ?? '',
        ].where((value) => value.isNotEmpty).join(' / '),
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> row) {
    final scope = row['scope']?.toString() == 'direct' ? 'DM' : 'Message';
    return ListTile(
      leading: Icon(
        row['scope']?.toString() == 'direct'
            ? Icons.mail_outline
            : Icons.message_outlined,
      ),
      title: Text(row['title']?.toString() ?? '-'),
      subtitle: Text(
        [
          scope,
          row['unitName']?.toString() ?? '',
          row['authorName']?.toString() ?? '',
        ].where((value) => value.isNotEmpty).join(' / '),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> rows,
    required Widget Function(Map<String, dynamic>) tileBuilder,
  }) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...rows.map(tileBuilder),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(Map<String, dynamic> result) {
    final tasks = _asListOfMap(result['tasks']);
    final messages = _asListOfMap(result['messages']);
    final users = _asListOfMap(result['users']);

    if (_selectedTab == 'tasks') {
      return _buildSection(
        title: 'タスク',
        rows: tasks,
        tileBuilder: _buildTaskTile,
      );
    }
    if (_selectedTab == 'messages') {
      return _buildSection(
        title: 'メッセージ',
        rows: messages,
        tileBuilder: _buildMessageTile,
      );
    }
    if (_selectedTab == 'users') {
      return _buildSection(
        title: 'ユーザー',
        rows: users,
        tileBuilder: _buildUserTile,
      );
    }

    if (tasks.isEmpty && messages.isEmpty && users.isEmpty) {
      return const Center(child: Text('検索結果はありません。'));
    }

    return Column(
      children: [
        _buildSection(title: 'タスク', rows: tasks, tileBuilder: _buildTaskTile),
        const SizedBox(height: 12),
        _buildSection(
          title: 'メッセージ',
          rows: messages,
          tileBuilder: _buildMessageTile,
        ),
        const SizedBox(height: 12),
        _buildSection(title: 'ユーザー', rows: users, tileBuilder: _buildUserTile),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'タスク メッセージ ユーザー を検索',
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'ALL'),
                  Tab(text: 'タスク'),
                  Tab(text: 'メッセージ'),
                  Tab(text: 'ユーザー'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _future == null
              ? const Center(child: Text('検索語を入力してください。'))
              : FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('検索に失敗しました: ${snapshot.error}'),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildResults(
                          snapshot.data ?? const <String, dynamic>{},
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
