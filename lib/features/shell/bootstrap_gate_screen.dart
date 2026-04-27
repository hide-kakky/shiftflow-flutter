import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../shared/session_providers.dart';

class BootstrapGateScreen extends ConsumerWidget {
  const BootstrapGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapAsync = ref.watch(bootstrapDataProvider);

    return bootstrapAsync.when(
      data: (bootstrap) {
        final participation = bootstrap['participation'];
        final canUseApp =
            participation is Map && participation['canUseApp'] == true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (canUseApp) {
            context.go('/home');
            return;
          }
          context.go('/participation');
        });

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('初期状態の取得に失敗しました: $error'),
          ),
        ),
      ),
    );
  }
}

class ParticipationScreen extends ConsumerStatefulWidget {
  const ParticipationScreen({super.key});

  @override
  ConsumerState<ParticipationScreen> createState() =>
      _ParticipationScreenState();
}

class _ParticipationScreenState extends ConsumerState<ParticipationScreen> {
  final TextEditingController _organizationCodeController =
      TextEditingController();
  final TextEditingController _requestMessageController =
      TextEditingController();
  final TextEditingController _inviteTokenController = TextEditingController();

  bool _searchingOrganizations = false;
  bool _requestingJoin = false;
  bool _acceptingInvite = false;
  List<Map<String, dynamic>> _searchResults = const [];

  @override
  void dispose() {
    _organizationCodeController.dispose();
    _requestMessageController.dispose();
    _inviteTokenController.dispose();
    super.dispose();
  }

  Future<void> _searchOrganizations() async {
    final keyword = _organizationCodeController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = const [];
      });
      return;
    }

    setState(() {
      _searchingOrganizations = true;
    });

    try {
      final results = await ref
          .read(routeDataRepositoryProvider)
          .searchOrganizationsByCode(keyword);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('組織検索に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _searchingOrganizations = false;
        });
      }
    }
  }

  Future<void> _requestJoin(Map<String, dynamic> organization) async {
    final organizationId = organization['id']?.toString() ?? '';
    if (organizationId.isEmpty) return;

    setState(() {
      _requestingJoin = true;
    });
    try {
      await ref
          .read(routeDataRepositoryProvider)
          .requestOrganizationJoin(
            organizationId: organizationId,
            organizationCode: organization['organization_code']?.toString(),
            requestMessage: _requestMessageController.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(bootstrapDataProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('参加申請を送信しました。')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('参加申請に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _requestingJoin = false;
        });
      }
    }
  }

  Future<void> _acceptInvite() async {
    final inviteToken = _inviteTokenController.text.trim();
    if (inviteToken.isEmpty) return;

    setState(() {
      _acceptingInvite = true;
    });
    try {
      await ref
          .read(routeDataRepositoryProvider)
          .acceptOrganizationInvite(inviteToken);
      if (!mounted) return;
      ref.invalidate(bootstrapDataProvider);
      await ref.read(bootstrapDataProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('招待を受諾しました。')));
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.go('/bootstrap');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('招待受諾に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _acceptingInvite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(bootstrapDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('参加状態の確認')),
      body: bootstrapAsync.when(
        data: (bootstrap) {
          final participation = bootstrap['participation'];
          final status = participation is Map
              ? participation['status']?.toString() ?? 'unaffiliated'
              : 'unaffiliated';
          final organizations = bootstrap['availableOrganizations'];
          final currentOrganization = bootstrap['currentOrganization'];
          final currentOrganizationName = currentOrganization is Map
              ? currentOrganization['name']?.toString() ?? '未選択'
              : '未選択';

          final title = switch (status) {
            'pending' => '参加申請の承認待ちです',
            'suspended' => '利用が一時停止されています',
            'revoked' => '参加権限が無効化されています',
            'active' => '利用可能です',
            _ => '組織への参加が必要です',
          };
          final description = switch (status) {
            'pending' => '管理者が承認するとホームへ進めます。',
            'suspended' => '管理者による再開が必要です。',
            'revoked' => '参加申請の再実行か、管理者からの招待が必要です。',
            'active' => '現在の組織とユニットが使える状態です。',
            _ => '組織コードで参加申請するか、招待リンクから参加してください。',
          };

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bootstrapDataProvider);
              await ref.read(bootstrapDataProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(description),
                        const SizedBox(height: 16),
                        Text('現在の組織: $currentOrganizationName'),
                        const SizedBox(height: 8),
                        Text('状態: $status'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: status == 'active'
                              ? () => context.go('/home')
                              : null,
                          child: const Text('ホームへ進む'),
                        ),
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
                          '組織コードで参加申請',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('組織コードや組織名で検索して、参加申請を送れます。'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _organizationCodeController,
                          decoration: const InputDecoration(
                            labelText: '組織コード / 組織名',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _requestMessageController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: '申請メッセージ',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _searchingOrganizations
                              ? null
                              : _searchOrganizations,
                          icon: _searchingOrganizations
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: const Text('組織を検索'),
                        ),
                        const SizedBox(height: 12),
                        if (_searchResults.isEmpty)
                          const Text('検索結果はまだありません。')
                        else
                          ..._searchResults.map(
                            (organization) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Theme.of(context).colorScheme.surface,
                              child: ListTile(
                                title: Text(
                                  organization['name']?.toString() ?? '-',
                                ),
                                subtitle: Text(
                                  'コード: ${organization['organization_code'] ?? '-'}',
                                ),
                                trailing: FilledButton(
                                  onPressed: _requestingJoin
                                      ? null
                                      : () => _requestJoin(organization),
                                  child: const Text('参加申請'),
                                ),
                              ),
                            ),
                          ),
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
                          '招待リンクを受諾',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('招待トークンを受け取っている場合は、ここから組織へ参加できます。'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _inviteTokenController,
                          decoration: const InputDecoration(
                            labelText: '招待トークン',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _acceptingInvite ? null : _acceptInvite,
                          icon: _acceptingInvite
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.mail_outline),
                          label: const Text('招待を受諾'),
                        ),
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
                          '参加中または申請済みの組織',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (organizations is List && organizations.isNotEmpty)
                          ...organizations.whereType<Map>().map(
                            (item) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                (item['organization'] is Map)
                                    ? item['organization']['name']
                                              ?.toString() ??
                                          '-'
                                    : '-',
                              ),
                              subtitle: Text(
                                '状態: ${item['status'] ?? '-'} / 権限: ${item['role'] ?? '-'}',
                              ),
                            ),
                          )
                        else
                          const Text('まだ対象の組織はありません。'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('状態取得に失敗しました: $error')),
      ),
    );
  }
}
