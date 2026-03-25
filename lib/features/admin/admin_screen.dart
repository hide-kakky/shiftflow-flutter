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

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allowed = ref.watch(isManagerOrAdminProvider);

    if (!allowed) {
      return Center(child: Text(l10n.permissionDenied));
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.adminDashboard),
            Tab(text: l10n.users),
            Tab(text: l10n.folders),
            Tab(text: l10n.templates),
            Tab(text: l10n.organizations),
            Tab(text: l10n.auditLogs),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _AdminDashboardTab(),
              _AdminUsersTab(),
              _AdminFoldersTab(),
              _AdminTemplatesTab(),
              _AdminOrganizationsTab(),
              _AdminAuditTab(),
            ],
          ),
        ),
      ],
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

class _AdminUsersTab extends ConsumerStatefulWidget {
  const _AdminUsersTab();

  @override
  ConsumerState<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab> {
  static const _roles = <String>['admin', 'manager', 'member', 'guest'];
  static const _statuses = <String>['active', 'pending', 'suspended', 'revoked'];

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
                    initialValue: _statuses.contains(status) ? status : 'active',
                    decoration: InputDecoration(labelText: l10n.adminUserStatus),
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

    await ref.read(routeDataRepositoryProvider).adminUpdateUser(
          email: email,
          role: role,
          status: status,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminUserUpdated)),
    );
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
              ? (snapshot.data!['rows'] as List).whereType<Map>().toList(growable: false)
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
                title: Text(row['displayName']?.toString() ?? row['email']?.toString() ?? '-'),
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
    await ref.read(routeDataRepositoryProvider).createFolder(
          name: nameController.text.trim(),
          color: colorController.text.trim(),
          isPublic: isPublic,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminFolderCreated)),
    );
    await _refresh();
  }

  Future<void> _openEditDialog(Map<String, dynamic> row) async {
    final l10n = AppLocalizations.of(context);
    final folderId = row['id']?.toString() ?? '';
    if (folderId.isEmpty) return;

    final nameController = TextEditingController(text: row['name']?.toString() ?? '');
    final colorController = TextEditingController(text: row['color']?.toString() ?? '');
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
    await ref.read(routeDataRepositoryProvider).updateFolder(
          folderId: folderId,
          name: nameController.text.trim(),
          color: colorController.text.trim(),
          isPublic: isPublic,
          isActive: isActive,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminFolderUpdated)),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminFolderArchived)),
    );
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
                  decoration: InputDecoration(labelText: l10n.adminTemplateName),
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

    await ref.read(routeDataRepositoryProvider).createTemplate(
          folderId: folderId,
          name: nameController.text.trim(),
          titleFormat: titleController.text.trim(),
          bodyFormat: bodyController.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminTemplateCreated)),
    );
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
                Center(child: Text('${l10n.apiError}: ${folderSnapshot.error}')),
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
                      decoration: InputDecoration(labelText: l10n.adminSelectFolder),
                      items: folders
                          .map((folder) => DropdownMenuItem(
                                value: folder['id']?.toString() ?? '',
                                child: Text(folder['name']?.toString() ?? '-'),
                              ))
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
                        .map((template) => ListTile(
                              title: Text(template['name']?.toString() ?? '-'),
                              subtitle: Text(template['title_format']?.toString() ?? ''),
                            ))
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
  ConsumerState<_AdminOrganizationsTab> createState() => _AdminOrganizationsTabState();
}

class _AdminOrganizationsTabState extends ConsumerState<_AdminOrganizationsTab> {
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
        .adminGetOrganization(orgId: row['id']?.toString() ?? row['orgId']?.toString());
    if (!mounted) return;

    final nameController = TextEditingController(text: detail['name']?.toString() ?? '');
    final shortNameController = TextEditingController(text: detail['short_name']?.toString() ?? '');
    final colorController = TextEditingController(text: detail['display_color']?.toString() ?? '');
    final timezoneController = TextEditingController(text: detail['timezone']?.toString() ?? 'Asia/Tokyo');
    final mailController = TextEditingController(text: detail['notification_email']?.toString() ?? '');

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
                    decoration: InputDecoration(labelText: l10n.adminOrgShortName),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: colorController,
                    decoration: InputDecoration(labelText: l10n.adminOrgColor),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: timezoneController,
                    decoration: InputDecoration(labelText: l10n.adminOrgTimezone),
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

    await ref.read(routeDataRepositoryProvider).adminUpdateOrganization(
          name: nameController.text.trim(),
          shortName: shortNameController.text.trim(),
          displayColor: colorController.text.trim(),
          timezone: timezoneController.text.trim(),
          notificationEmail: mailController.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminOrganizationUpdated)),
    );
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
                subtitle: Text(row['id']?.toString() ?? row['orgId']?.toString() ?? ''),
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
              ? (snapshot.data!['rows'] as List).whereType<Map>().toList(growable: false)
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
                title: Text(row['action']?.toString() ?? row['event']?.toString() ?? '-'),
                subtitle: Text(row['created_at']?.toString() ?? row.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
