import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../shared/session_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    final currentOrganization = ref.watch(currentOrganizationProvider);
    final currentUnit = ref.watch(currentUnitProvider);
    final canAdmin = ref.watch(isManagerOrAdminProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getHomeContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('ホーム情報の取得に失敗しました: ${snapshot.error}'));
        }

        final data = snapshot.data ?? const <String, dynamic>{};
        final overview = _asMap(data['overview']);
        final blocks = _asMap(data['blocks']);
        final tasks = _asListOfMap(blocks['tasks']);
        final messages = _asListOfMap(blocks['messages']);
        final folders = _asListOfMap(blocks['folders']);
        final units = _asListOfMap(blocks['units']);
        final adminSummary = _asMap(blocks['adminSummary']).isEmpty
            ? overview
            : _asMap(blocks['adminSummary']);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;
            final content = <Widget>[
              _HomeHeader(
                organizationName:
                    currentOrganization?['name']?.toString() ?? '組織未選択',
                unitName: currentUnit?['name']?.toString() ?? '現在地ユニット未設定',
              ),
              const SizedBox(height: 16),
              _MetricGrid(
                items: [
                  _MetricCardData(
                    title: '対応中のタスク',
                    value: _toInt(overview['openTaskCount']).toString(),
                    description: 'あなたが今動くべきタスク件数',
                    color: const Color(0xFF2160F3),
                  ),
                  _MetricCardData(
                    title: '未読メッセージ',
                    value: _toInt(overview['unreadMessageCount']).toString(),
                    description: '全体未読バッジの件数',
                    color: const Color(0xFF179268),
                  ),
                  _MetricCardData(
                    title: '承認待ち',
                    value: _toInt(overview['pendingUserCount']).toString(),
                    description: canAdmin ? '参加申請や承認待ちの確認' : '管理者向け情報',
                    color: const Color(0xFFE07A20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ];

            if (isDesktop) {
              content.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          _HomeBlockCard(
                            title: '直近のタスク',
                            description: 'すぐ着手すべきものを先頭で確認します。',
                            items: tasks,
                            emptyText: '現在表示できるタスクはありません。',
                            itemBuilder: (item) => _TaskTile(item: item),
                          ),
                          const SizedBox(height: 16),
                          _HomeBlockCard(
                            title: '新着メッセージ',
                            description: '現在地ユニット文脈に近いメッセージを先に出します。',
                            items: messages,
                            emptyText: '表示できるメッセージはありません。',
                            itemBuilder: (item) => _MessageTile(item: item),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _HomeBlockCard(
                            title: 'フォルダ',
                            description: '閲覧可能なフォルダを一覧で把握します。',
                            items: folders,
                            emptyText: 'フォルダはまだありません。',
                            itemBuilder: (item) => _SimpleTile(
                              title: item['name']?.toString() ?? '-',
                              subtitle: item['is_public'] == true ? '公開' : '限定',
                              leading: Icons.folder_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _HomeBlockCard(
                            title: 'ユニット',
                            description: '上位ユニット / 下位ユニットの構造を確認します。',
                            items: units,
                            emptyText: 'ユニットはまだありません。',
                            itemBuilder: (item) => _SimpleTile(
                              title: item['name']?.toString() ?? '-',
                              subtitle: item['path_text']?.toString() ?? '',
                              leading: Icons.account_tree_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AdminSummaryBlock(
                            canAdmin: canAdmin,
                            adminSummary: adminSummary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              content.addAll([
                _HomeBlockCard(
                  title: '直近のタスク',
                  description: 'スマホではまず行動に直結する情報を出します。',
                  items: tasks,
                  emptyText: '現在表示できるタスクはありません。',
                  itemBuilder: (item) => _TaskTile(item: item),
                ),
                const SizedBox(height: 16),
                _HomeBlockCard(
                  title: '新着メッセージ',
                  description: '未読や重要メッセージを優先して確認します。',
                  items: messages,
                  emptyText: '表示できるメッセージはありません。',
                  itemBuilder: (item) => _MessageTile(item: item),
                ),
                const SizedBox(height: 16),
                _HomeBlockCard(
                  title: 'フォルダとユニット',
                  description: '場所と投稿先を混ぜずに見分けます。',
                  items: [
                    ...folders
                        .take(3)
                        .map(
                          (item) => {
                            'title': item['name'],
                            'subtitle': item['is_public'] == true
                                ? 'フォルダ / 公開'
                                : 'フォルダ / 限定',
                            'leading': Icons.folder_outlined,
                          },
                        ),
                    ...units
                        .take(3)
                        .map(
                          (item) => {
                            'title': item['name'],
                            'subtitle': 'ユニット / ${item['path_text'] ?? ''}',
                            'leading': Icons.account_tree_outlined,
                          },
                        ),
                  ],
                  emptyText: '表示できる項目はありません。',
                  itemBuilder: (item) => _SimpleTile(
                    title: item['title']?.toString() ?? '-',
                    subtitle: item['subtitle']?.toString() ?? '',
                    leading: item['leading'] as IconData? ?? Icons.info_outline,
                  ),
                ),
                const SizedBox(height: 16),
                _AdminSummaryBlock(
                  canAdmin: canAdmin,
                  adminSummary: adminSummary,
                ),
              ]);
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(bootstrapDataProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: content,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminSummaryBlock extends StatelessWidget {
  const _AdminSummaryBlock({
    required this.canAdmin,
    required this.adminSummary,
  });

  final bool canAdmin;
  final Map<String, dynamic> adminSummary;

  @override
  Widget build(BuildContext context) {
    return _HomeBlockCard(
      title: '管理要約',
      description: canAdmin
          ? '参加申請や管理対応の状況をここで把握します。'
          : '一般ユーザーにも全体の状況だけは見えるようにします。',
      items: [
        {
          'title': '承認待ち',
          'subtitle': '${_toInt(adminSummary['pendingUserCount'])} 件',
          'leading': Icons.pending_actions_outlined,
        },
        {
          'title': '未読メッセージ',
          'subtitle': '${_toInt(adminSummary['unreadMessageCount'])} 件',
          'leading': Icons.markunread_outlined,
        },
        {
          'title': '対応中タスク',
          'subtitle': '${_toInt(adminSummary['openTaskCount'])} 件',
          'leading': Icons.task_outlined,
        },
      ],
      emptyText: '管理要約はまだありません。',
      itemBuilder: (item) => _SimpleTile(
        title: item['title']?.toString() ?? '-',
        subtitle: item['subtitle']?.toString() ?? '',
        leading: item['leading'] as IconData? ?? Icons.info_outline,
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.organizationName, required this.unitName});

  final String organizationName;
  final String unitName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ホーム', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Notion の整理感は残しつつ、スマホでは行動優先、PC では俯瞰優先で表示します。',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.apartment_outlined, size: 18),
                  label: Text('現在の組織: $organizationName'),
                ),
                Chip(
                  avatar: const Icon(Icons.account_tree_outlined, size: 18),
                  label: Text('現在地ユニット: $unitName'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricCardData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _MetricCard(item: items[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricCardData item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Spacer(),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(item.value, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(item.description),
          ],
        ),
      ),
    );
  }
}

class _HomeBlockCard extends StatelessWidget {
  const _HomeBlockCard({
    required this.title,
    required this.description,
    required this.items,
    required this.emptyText,
    required this.itemBuilder,
  });

  final String title;
  final String description;
  final List<Map<String, dynamic>> items;
  final String emptyText;
  final Widget Function(Map<String, dynamic> item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(emptyText),
              )
            else
              ...items
                  .take(5)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: itemBuilder(item),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return _SimpleTile(
      title: item['title']?.toString() ?? '-',
      subtitle: '期限: ${item['due_at']?.toString() ?? '未設定'}',
      leading: Icons.task_alt_outlined,
      trailing: item['status']?.toString() ?? '',
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final scope = item['message_scope']?.toString() == 'direct' ? '個人' : '共有';
    final pinned = item['is_pinned'] == true ? ' / ピン' : '';
    return _SimpleTile(
      title: item['title']?.toString() ?? '-',
      subtitle: '$scope$pinned',
      leading: item['message_scope']?.toString() == 'direct'
          ? Icons.mail_outline
          : Icons.forum_outlined,
      description: item['body']?.toString() ?? '',
    );
  }
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    this.trailing,
    this.description,
  });

  final String title;
  final String subtitle;
  final IconData leading;
  final String? trailing;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(leading),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle),
                if ((description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if ((trailing ?? '').isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(trailing!),
          ],
        ],
      ),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    required this.description,
    required this.color,
  });

  final String title;
  final String value;
  final String description;
  final Color color;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _asListOfMap(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, val) => MapEntry(key.toString(), val)))
      .toList(growable: false);
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
