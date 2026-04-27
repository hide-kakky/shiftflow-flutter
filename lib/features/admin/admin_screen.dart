import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/session_providers.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedIndex = 0;

  static const _sections = <({String title, IconData icon})>[
    (title: '管理トップ', icon: Icons.space_dashboard_outlined),
    (title: '参加申請', icon: Icons.how_to_reg_outlined),
    (title: 'ユニット', icon: Icons.account_tree_outlined),
    (title: '招待', icon: Icons.mail_outline),
    (title: 'ユーザー', icon: Icons.group_outlined),
    (title: 'フォルダ', icon: Icons.folder_outlined),
    (title: '定型文', icon: Icons.article_outlined),
    (title: '組織', icon: Icons.apartment_outlined),
    (title: '監査', icon: Icons.fact_check_outlined),
  ];

  Widget _buildSection(int index) {
    switch (index) {
      case 0:
        return const _AdminDashboardTab();
      case 1:
        return const _AdminJoinRequestsTab();
      case 2:
        return const _AdminUnitsTab();
      case 3:
        return const _AdminInvitesTab();
      case 4:
        return const _AdminUsersTab();
      case 5:
        return const _AdminFoldersTab();
      case 6:
        return const _AdminTemplatesTab();
      case 7:
        return const _AdminOrganizationsTab();
      case 8:
        return const _AdminAuditTab();
      default:
        return const _AdminDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allowed = ref.watch(isManagerOrAdminProvider);

    if (!allowed) {
      return Center(child: Text(l10n.permissionDenied));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        if (isDesktop) {
          return Row(
            children: [
              SizedBox(
                width: 250,
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return ListTile(
                        leading: Icon(section.icon),
                        title: Text(section.title),
                        selected: _selectedIndex == index,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sections[_selectedIndex].title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              const Text('PC では検索・集計・編集を分割して扱います。'),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(child: _buildSection(_selectedIndex)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '管理',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_sections.length, (index) {
                    final section = _sections[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == _sections.length - 1 ? 0 : 8,
                      ),
                      child: ChoiceChip(
                        avatar: Icon(section.icon, size: 18),
                        label: Text(section.title),
                        selected: _selectedIndex == index,
                        onSelected: (_) =>
                            setState(() => _selectedIndex = index),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_iphone_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'スマホでは 1 画面 1 役割で段階表示します。今は「${_sections[_selectedIndex].title}」を表示中です。',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: _buildSection(_selectedIndex)),
          ],
        );
      },
    );
  }
}

class _AdminDashboardTab extends ConsumerWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getBootstrapData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final data = snapshot.data ?? {};
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: const Text('Summary'),
                subtitle: Text(data.toString()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminJoinRequestsTab extends ConsumerStatefulWidget {
  const _AdminJoinRequestsTab();

  @override
  ConsumerState<_AdminJoinRequestsTab> createState() =>
      _AdminJoinRequestsTabState();
}

class _AdminJoinRequestsTabState extends ConsumerState<_AdminJoinRequestsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(routeDataRepositoryProvider).listJoinRequests();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _reviewRequest({
    required String joinRequestId,
    required bool approve,
  }) async {
    if (approve) {
      await ref
          .read(routeDataRepositoryProvider)
          .approveJoinRequest(joinRequestId);
    } else {
      await ref
          .read(routeDataRepositoryProvider)
          .rejectJoinRequest(joinRequestId);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? '参加申請を承認しました。' : '参加申請を却下しました。')),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
                Center(child: Text('参加申請の取得に失敗しました: ${snapshot.error}')),
              ],
            );
          }
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('承認待ちの参加申請はありません。')),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = rows[index];
              final status = row['status']?.toString() ?? '-';
              final email = (row['users'] is Map)
                  ? (row['users'] as Map)['email']?.toString() ?? ''
                  : '';
              final displayName = (row['users'] is Map)
                  ? (row['users'] as Map)['display_name']?.toString() ?? email
                  : email;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isEmpty ? email : displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(email),
                      const SizedBox(height: 6),
                      Text('状態: $status'),
                      Text(
                        '組織コード: ${row['requested_code']?.toString() ?? '-'}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '申請メモ: ${row['request_message']?.toString().trim().isEmpty ?? true ? 'なし' : row['request_message']}',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: status == 'pending'
                                ? () => _reviewRequest(
                                    joinRequestId: row['id']?.toString() ?? '',
                                    approve: true,
                                  )
                                : null,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('承認'),
                          ),
                          OutlinedButton.icon(
                            onPressed: status == 'pending'
                                ? () => _reviewRequest(
                                    joinRequestId: row['id']?.toString() ?? '',
                                    approve: false,
                                  )
                                : null,
                            icon: const Icon(Icons.block_outlined),
                            label: const Text('却下'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminUnitsTab extends ConsumerStatefulWidget {
  const _AdminUnitsTab();

  @override
  ConsumerState<_AdminUnitsTab> createState() => _AdminUnitsTabState();
}

class _AdminUnitsTabState extends ConsumerState<_AdminUnitsTab> {
  late Future<List<Map<String, dynamic>>> _unitsFuture;
  Future<List<Map<String, dynamic>>>? _membershipsFuture;
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _unitsFuture = _loadUnits();
  }

  Future<List<Map<String, dynamic>>> _loadUnits() async {
    final units = await ref.read(routeDataRepositoryProvider).listUnits();
    if (units.isNotEmpty && _selectedUnitId == null) {
      _selectedUnitId = units.first['id']?.toString();
      _membershipsFuture = _loadMemberships();
    }
    return units;
  }

  Future<List<Map<String, dynamic>>> _loadMemberships() {
    final unitId = _selectedUnitId ?? '';
    if (unitId.isEmpty) return Future.value(const []);
    return ref.read(routeDataRepositoryProvider).listUnitMemberships(unitId);
  }

  Future<void> _refresh() async {
    setState(() {
      _unitsFuture = _loadUnits();
      _membershipsFuture = _loadMemberships();
    });
    await _unitsFuture;
    await _membershipsFuture;
  }

  Future<void> _openCreateUnitDialog(List<Map<String, dynamic>> units) async {
    final nameController = TextEditingController();
    String? parentUnitId;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ユニット作成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ユニット名'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: parentUnitId,
                decoration: const InputDecoration(labelText: '親ユニット'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('最上位ユニット'),
                  ),
                  for (final unit in units)
                    DropdownMenuItem<String?>(
                      value: unit['id']?.toString(),
                      child: Text(
                        unit['path_text']?.toString() ??
                            unit['name']?.toString() ??
                            '-',
                      ),
                    ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    parentUnitId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave != true) return;
    await ref
        .read(routeDataRepositoryProvider)
        .createUnit(
          name: nameController.text.trim(),
          parentUnitId: parentUnitId,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ユニットを作成しました。')));
    await _refresh();
  }

  Future<void> _openEditUnitDialog(
    Map<String, dynamic> unit,
    List<Map<String, dynamic>> units,
  ) async {
    final unitId = unit['id']?.toString() ?? '';
    if (unitId.isEmpty) return;
    final nameController = TextEditingController(
      text: unit['name']?.toString() ?? '',
    );
    String? parentUnitId = unit['parent_unit_id']?.toString();
    bool isActive = unit['is_active'] != false;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ユニット編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ユニット名'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: parentUnitId,
                decoration: const InputDecoration(labelText: '親ユニット'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('最上位ユニット'),
                  ),
                  for (final item in units.where(
                    (item) => item['id']?.toString() != unitId,
                  ))
                    DropdownMenuItem<String?>(
                      value: item['id']?.toString(),
                      child: Text(
                        item['path_text']?.toString() ??
                            item['name']?.toString() ??
                            '-',
                      ),
                    ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    parentUnitId = value;
                  });
                },
              ),
              SwitchListTile(
                value: isActive,
                onChanged: (value) {
                  setDialogState(() {
                    isActive = value;
                  });
                },
                title: const Text('有効'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave != true) return;
    await ref
        .read(routeDataRepositoryProvider)
        .updateUnit(
          unitId: unitId,
          name: nameController.text.trim(),
          parentUnitId: parentUnitId,
          isActive: isActive,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ユニットを更新しました。')));
    await _refresh();
  }

  Future<void> _openAssignMemberDialog() async {
    final unitId = _selectedUnitId ?? '';
    if (unitId.isEmpty) return;
    final users = await ref.read(routeDataRepositoryProvider).listActiveUsers();
    if (!mounted) return;
    String? selectedUserId;
    String role = 'member';
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ユニット所属を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: selectedUserId,
                decoration: const InputDecoration(labelText: '対象ユーザー'),
                items: users
                    .map(
                      (user) => DropdownMenuItem<String?>(
                        value: user['userId']?.toString(),
                        child: Text(
                          user['displayName']?.toString() ??
                              user['email']?.toString() ??
                              '-',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setDialogState(() {
                    selectedUserId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'ユニットロール'),
                items: const [
                  DropdownMenuItem(value: 'member', child: Text('member')),
                  DropdownMenuItem(value: 'manager', child: Text('manager')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() {
                    role = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('割り当て'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave != true || selectedUserId == null) return;
    await ref
        .read(routeDataRepositoryProvider)
        .assignUnitMember(unitId: unitId, userId: selectedUserId!, role: role);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ユニット所属を更新しました。')));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _unitsFuture,
      builder: (context, unitSnapshot) {
        if (unitSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (unitSnapshot.hasError) {
          return Center(child: Text('ユニット一覧の取得に失敗しました: ${unitSnapshot.error}'));
        }
        final units = unitSnapshot.data ?? const [];
        _membershipsFuture ??= _loadMemberships();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final unitList = ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _openCreateUnitDialog(units),
                      icon: const Icon(Icons.add),
                      label: const Text('ユニット作成'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (units.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(child: Text('ユニットはまだありません。')),
                    )
                  else
                    ...units.map((unit) {
                      final unitId = unit['id']?.toString();
                      return Card(
                        child: ListTile(
                          selected: _selectedUnitId == unitId,
                          leading: const Icon(Icons.account_tree_outlined),
                          title: Text(unit['name']?.toString() ?? '-'),
                          subtitle: Text(unit['path_text']?.toString() ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openEditUnitDialog(unit, units),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedUnitId = unitId;
                              _membershipsFuture = _loadMemberships();
                            });
                          },
                        ),
                      );
                    }),
                ],
              );

              final detail = FutureBuilder<List<Map<String, dynamic>>>(
                future: _membershipsFuture,
                builder: (context, membershipSnapshot) {
                  if (_selectedUnitId == null) {
                    return const Center(child: Text('ユニットを選択してください。'));
                  }
                  if (membershipSnapshot.connectionState !=
                      ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (membershipSnapshot.hasError) {
                    return Center(
                      child: Text(
                        '所属一覧の取得に失敗しました: ${membershipSnapshot.error}',
                      ),
                    );
                  }
                  final memberships = membershipSnapshot.data ?? const [];
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _openAssignMemberDialog,
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('所属を追加'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (memberships.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: Center(child: Text('このユニットに所属中のユーザーはいません。')),
                        )
                      else
                        ...memberships.map(
                          (row) => Card(
                            child: ListTile(
                              leading: Icon(
                                row['role'] == 'manager'
                                    ? Icons.admin_panel_settings_outlined
                                    : Icons.person_outline,
                              ),
                              title: Text(
                                row['displayName']?.toString() ??
                                    row['email']?.toString() ??
                                    '-',
                              ),
                              subtitle: Text(
                                '${row['role']} / ${row['status']}',
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(child: unitList),
                    const VerticalDivider(width: 1),
                    Expanded(child: detail),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: unitList),
                  const Divider(height: 1),
                  SizedBox(height: 280, child: detail),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AdminInvitesTab extends ConsumerStatefulWidget {
  const _AdminInvitesTab();

  @override
  ConsumerState<_AdminInvitesTab> createState() => _AdminInvitesTabState();
}

class _AdminInvitesTabState extends ConsumerState<_AdminInvitesTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(routeDataRepositoryProvider).listOrganizationInvites();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openCreateInviteDialog() async {
    final units = await ref.read(routeDataRepositoryProvider).listUnits();
    if (!mounted) return;
    final labelController = TextEditingController();
    String role = 'member';
    String? unitId;
    final expiresAtController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('招待を作成'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: '招待ラベル'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: '組織ロール'),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('member')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      role = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: unitId,
                  decoration: const InputDecoration(labelText: '初期ユニット'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('未指定'),
                    ),
                    for (final unit in units)
                      DropdownMenuItem<String?>(
                        value: unit['id']?.toString(),
                        child: Text(
                          unit['path_text']?.toString() ??
                              unit['name']?.toString() ??
                              '-',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      unitId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: expiresAtController,
                  decoration: const InputDecoration(
                    labelText: '有効期限 (例: 2026-05-01T09:00:00+09:00)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave != true) return;
    await ref
        .read(routeDataRepositoryProvider)
        .createOrganizationInvite(
          unitId: unitId,
          inviteLabel: labelController.text.trim(),
          role: role,
          expiresAt: expiresAtController.text.trim().isEmpty
              ? null
              : DateTime.tryParse(expiresAtController.text.trim()),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('招待を作成しました。')));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
                Center(child: Text('招待一覧の取得に失敗しました: ${snapshot.error}')),
              ],
            );
          }
          final rows = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _openCreateInviteDialog,
                  icon: const Icon(Icons.add_link_outlined),
                  label: const Text('招待を作成'),
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: Text('招待はまだ発行されていません。')),
                )
              else
                ...rows.map(
                  (row) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['invite_label']?.toString().isNotEmpty == true
                                ? row['invite_label'].toString()
                                : '招待リンク',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            'token: ${row['invite_token']?.toString() ?? '-'}',
                          ),
                          const SizedBox(height: 8),
                          Text('role: ${row['role']?.toString() ?? '-'}'),
                          Text(
                            'unitId: ${row['unit_id']?.toString() ?? '未指定'}',
                          ),
                          Text(
                            'expiresAt: ${row['expires_at']?.toString() ?? '未指定'}',
                          ),
                          Text(
                            'acceptedAt: ${row['accepted_at']?.toString() ?? '未使用'}',
                          ),
                        ],
                      ),
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

class _AdminUsersTab extends ConsumerStatefulWidget {
  const _AdminUsersTab();

  @override
  ConsumerState<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab> {
  static const _roles = <String>['owner', 'admin', 'member'];
  static const _statuses = <String>[
    'active',
    'pending',
    'suspended',
    'revoked',
  ];

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return ref.read(routeDataRepositoryProvider).adminListUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openUpdateDialog(Map row) async {
    final l10n = AppLocalizations.of(context);
    final email = row['email']?.toString() ?? '';
    if (email.isEmpty) return;

    String role = row['role']?.toString() ?? 'member';
    String status = row['status']?.toString() ?? 'active';

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.adminEditUser),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(email),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _roles.contains(role) ? role : 'member',
                    decoration: InputDecoration(labelText: l10n.role),
                    items: _roles
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => role = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _statuses.contains(status)
                        ? status
                        : 'active',
                    decoration: InputDecoration(
                      labelText: l10n.adminUserStatus,
                    ),
                    items: _statuses
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => status = value);
                    },
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
            );
          },
        );
      },
    );

    if (shouldSave != true) return;

    await ref
        .read(routeDataRepositoryProvider)
        .adminUpdateUser(email: email, role: role, status: status);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminUserUpdated)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<Map<String, dynamic>>(
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
          final rows = (snapshot.data?['rows'] is List)
              ? (snapshot.data!['rows'] as List).whereType<Map>().toList(
                  growable: false,
                )
              : <Map>[];
          if (rows.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(l10n.noData)),
              ],
            );
          }

          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return ListTile(
                title: Text(
                  row['displayName']?.toString() ??
                      row['email']?.toString() ??
                      '-',
                ),
                subtitle: Text('${row['role']} / ${row['status']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.adminEditUser,
                  onPressed: () => _openUpdateDialog(row),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminFoldersTab extends ConsumerStatefulWidget {
  const _AdminFoldersTab();

  @override
  ConsumerState<_AdminFoldersTab> createState() => _AdminFoldersTabState();
}

class _AdminFoldersTabState extends ConsumerState<_AdminFoldersTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(routeDataRepositoryProvider).listFolders();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openCreateDialog() async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final colorController = TextEditingController(text: '#3B82F6');
    bool isPublic = true;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.adminCreateFolder),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.adminFolderName),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: colorController,
                decoration: InputDecoration(labelText: l10n.adminFolderColor),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text(l10n.adminIsPublic),
                value: isPublic,
                onChanged: (value) => setDialogState(() => isPublic = value),
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
      ),
    );
    if (shouldSave != true) return;
    await ref
        .read(routeDataRepositoryProvider)
        .createFolder(
          name: nameController.text.trim(),
          color: colorController.text.trim(),
          isPublic: isPublic,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminFolderCreated)));
    await _refresh();
  }

  Future<void> _openEditDialog(Map<String, dynamic> row) async {
    final l10n = AppLocalizations.of(context);
    final folderId = row['id']?.toString() ?? '';
    if (folderId.isEmpty) return;

    final nameController = TextEditingController(
      text: row['name']?.toString() ?? '',
    );
    final colorController = TextEditingController(
      text: row['color']?.toString() ?? '',
    );
    bool isPublic = row['is_public'] == true || row['isPublic'] == true;
    bool isActive = !(row['is_active'] == false || row['isActive'] == false);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.adminEditFolder),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.adminFolderName),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: colorController,
                decoration: InputDecoration(labelText: l10n.adminFolderColor),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text(l10n.adminIsPublic),
                value: isPublic,
                onChanged: (value) => setDialogState(() => isPublic = value),
              ),
              SwitchListTile(
                title: Text(l10n.adminIsActive),
                value: isActive,
                onChanged: (value) => setDialogState(() => isActive = value),
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
      ),
    );
    if (shouldSave != true) return;
    await ref
        .read(routeDataRepositoryProvider)
        .updateFolder(
          folderId: folderId,
          name: nameController.text.trim(),
          color: colorController.text.trim(),
          isPublic: isPublic,
          isActive: isActive,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminFolderUpdated)));
    await _refresh();
  }

  Future<void> _archiveFolder(Map<String, dynamic> row) async {
    final l10n = AppLocalizations.of(context);
    final folderId = row['id']?.toString() ?? '';
    if (folderId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminArchiveFolder),
        content: Text(row['name']?.toString() ?? folderId),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.adminArchiveFolder),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(routeDataRepositoryProvider).archiveFolder(folderId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminFolderArchived)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l10n.apiError}: ${snapshot.error}'));
          }
          final rows = snapshot.data ?? const [];
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: Text(l10n.adminCreateFolder),
                  ),
                ),
              ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 120, 16, 16),
                  child: Center(child: Text('フォルダはまだありません')),
                )
              else
                ...rows.map((row) {
                  return ListTile(
                    title: Text(row['name']?.toString() ?? '-'),
                    subtitle: Text(
                      'public=${row['is_public'] ?? row['isPublic']} active=${row['is_active'] ?? row['isActive']}',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.adminEditFolder,
                          onPressed: () => _openEditDialog(row),
                        ),
                        IconButton(
                          icon: const Icon(Icons.archive_outlined),
                          tooltip: l10n.adminArchiveFolder,
                          onPressed: () => _archiveFolder(row),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _AdminTemplatesTab extends ConsumerStatefulWidget {
  const _AdminTemplatesTab();

  @override
  ConsumerState<_AdminTemplatesTab> createState() => _AdminTemplatesTabState();
}

class _AdminTemplatesTabState extends ConsumerState<_AdminTemplatesTab> {
  late Future<List<Map<String, dynamic>>> _foldersFuture;
  Future<List<Map<String, dynamic>>>? _templatesFuture;
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _foldersFuture = _loadFolders();
  }

  Future<List<Map<String, dynamic>>> _loadFolders() async {
    final folders = await ref.read(routeDataRepositoryProvider).listFolders();
    if (folders.isNotEmpty && _selectedFolderId == null) {
      _selectedFolderId = folders.first['id']?.toString();
      _templatesFuture = _loadTemplates();
    }
    return folders;
  }

  Future<List<Map<String, dynamic>>> _loadTemplates() {
    final folderId = _selectedFolderId ?? '';
    if (folderId.isEmpty) return Future.value(const []);
    return ref.read(routeDataRepositoryProvider).listTemplates(folderId);
  }

  Future<void> _refreshAll() async {
    setState(() {
      _foldersFuture = _loadFolders();
      _templatesFuture = _loadTemplates();
    });
    await _foldersFuture;
    await _templatesFuture;
  }

  Future<void> _createTemplate() async {
    final l10n = AppLocalizations.of(context);
    final folderId = _selectedFolderId ?? '';
    if (folderId.isEmpty) return;

    final nameController = TextEditingController();
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminCreateTemplate),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.adminTemplateName,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.adminTitleFormat),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(labelText: l10n.adminBodyFormat),
                ),
              ],
            ),
          ),
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

    await ref
        .read(routeDataRepositoryProvider)
        .createTemplate(
          folderId: folderId,
          name: nameController.text.trim(),
          titleFormat: titleController.text.trim(),
          bodyFormat: bodyController.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminTemplateCreated)));
    await _refreshAll();
  }

  Future<void> _editTemplate(Map<String, dynamic> template) async {
    final l10n = AppLocalizations.of(context);
    final templateId = template['id']?.toString() ?? '';
    if (templateId.isEmpty) return;

    final nameController = TextEditingController(
      text: template['name']?.toString() ?? '',
    );
    final titleController = TextEditingController(
      text: template['title_format']?.toString() ?? '',
    );
    final bodyController = TextEditingController(
      text: template['body_format']?.toString() ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.edit),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.adminTemplateName,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.adminTitleFormat),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(labelText: l10n.adminBodyFormat),
                ),
              ],
            ),
          ),
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

    await ref
        .read(routeDataRepositoryProvider)
        .updateTemplate(
          templateId: templateId,
          name: nameController.text.trim(),
          titleFormat: titleController.text.trim(),
          bodyFormat: bodyController.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminTemplateUpdated)));
    await _refreshAll();
  }

  Future<void> _deleteTemplate(Map<String, dynamic> template) async {
    final l10n = AppLocalizations.of(context);
    final templateId = template['id']?.toString() ?? '';
    if (templateId.isEmpty) return;
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
    if (confirmed != true) return;

    await ref.read(routeDataRepositoryProvider).deleteTemplate(templateId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminTemplateDeleted)));
    await _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _foldersFuture,
        builder: (context, folderSnapshot) {
          if (folderSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (folderSnapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text('${l10n.apiError}: ${folderSnapshot.error}'),
                ),
              ],
            );
          }
          final folders = folderSnapshot.data ?? const [];
          if (folders.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(l10n.adminNoFoldersForTemplates)),
              ],
            );
          }

          _templatesFuture ??= _loadTemplates();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedFolderId,
                      decoration: InputDecoration(
                        labelText: l10n.adminSelectFolder,
                      ),
                      items: folders
                          .map(
                            (folder) => DropdownMenuItem(
                              value: folder['id']?.toString() ?? '',
                              child: Text(folder['name']?.toString() ?? '-'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedFolderId = value;
                          _templatesFuture = _loadTemplates();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _createTemplate,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.adminCreateTemplate),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _templatesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('${l10n.apiError}: ${snapshot.error}');
                  }
                  final templates = snapshot.data ?? const [];
                  if (templates.isEmpty) return Text(l10n.noData);
                  return Column(
                    children: templates
                        .map(
                          (template) => ListTile(
                            title: Text(template['name']?.toString() ?? '-'),
                            subtitle: Text(
                              template['title_format']?.toString() ?? '',
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: l10n.edit,
                                  onPressed: () => _editTemplate(template),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: l10n.delete,
                                  onPressed: () => _deleteTemplate(template),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminOrganizationsTab extends ConsumerStatefulWidget {
  const _AdminOrganizationsTab();

  @override
  ConsumerState<_AdminOrganizationsTab> createState() =>
      _AdminOrganizationsTabState();
}

class _AdminOrganizationsTabState
    extends ConsumerState<_AdminOrganizationsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(routeDataRepositoryProvider).adminListOrganizations();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openUpdateDialog(Map row) async {
    final l10n = AppLocalizations.of(context);
    final detail = await ref
        .read(routeDataRepositoryProvider)
        .adminGetOrganization(
          orgId: row['id']?.toString() ?? row['orgId']?.toString(),
        );
    if (!mounted) return;

    final nameController = TextEditingController(
      text: detail['name']?.toString() ?? '',
    );
    final shortNameController = TextEditingController(
      text: detail['short_name']?.toString() ?? '',
    );
    final colorController = TextEditingController(
      text: detail['display_color']?.toString() ?? '',
    );
    final timezoneController = TextEditingController(
      text: detail['timezone']?.toString() ?? 'Asia/Tokyo',
    );
    final mailController = TextEditingController(
      text: detail['notification_email']?.toString() ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.adminEditOrganization),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: l10n.title),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: shortNameController,
                    decoration: InputDecoration(
                      labelText: l10n.adminOrgShortName,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: colorController,
                    decoration: InputDecoration(labelText: l10n.adminOrgColor),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: timezoneController,
                    decoration: InputDecoration(
                      labelText: l10n.adminOrgTimezone,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: mailController,
                    decoration: InputDecoration(labelText: l10n.email),
                  ),
                ],
              ),
            ),
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
        );
      },
    );

    if (shouldSave != true) return;

    await ref
        .read(routeDataRepositoryProvider)
        .adminUpdateOrganization(
          name: nameController.text.trim(),
          shortName: shortNameController.text.trim(),
          displayColor: colorController.text.trim(),
          timezone: timezoneController.text.trim(),
          notificationEmail: mailController.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminOrganizationUpdated)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
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
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return ListTile(
                title: Text(row['name']?.toString() ?? '-'),
                subtitle: Text(
                  row['id']?.toString() ?? row['orgId']?.toString() ?? '',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.adminEditOrganization,
                  onPressed: () => _openUpdateDialog(row),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminAuditTab extends ConsumerStatefulWidget {
  const _AdminAuditTab();

  @override
  ConsumerState<_AdminAuditTab> createState() => _AdminAuditTabState();
}

class _AdminAuditTabState extends ConsumerState<_AdminAuditTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return ref.read(routeDataRepositoryProvider).getAuditLogs();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<Map<String, dynamic>>(
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
          final rows = (snapshot.data?['rows'] is List)
              ? (snapshot.data!['rows'] as List).whereType<Map>().toList(
                  growable: false,
                )
              : <Map>[];
          if (rows.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(l10n.noData)),
              ],
            );
          }
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return ListTile(
                title: Text(
                  row['action']?.toString() ?? row['event']?.toString() ?? '-',
                ),
                subtitle: Text(row['created_at']?.toString() ?? row.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
