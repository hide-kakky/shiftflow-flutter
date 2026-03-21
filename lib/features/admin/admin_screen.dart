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

class _AdminUsersTab extends ConsumerWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.adminListUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final rows = (snapshot.data?['rows'] is List)
            ? (snapshot.data!['rows'] as List).whereType<Map>().toList()
            : <Map>[];
        if (rows.isEmpty) {
          return const Center(child: Text('No users'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              title: Text(row['displayName']?.toString() ?? row['email']?.toString() ?? '-'),
              subtitle: Text('${row['role']} / ${row['status']}'),
            );
          },
        );
      },
    );
  }
}

class _AdminFoldersTab extends ConsumerWidget {
  const _AdminFoldersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.listFolders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('No folders'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              title: Text(row['name']?.toString() ?? '-'),
              subtitle: Text('public=${row['isPublic']} active=${row['isActive']}'),
            );
          },
        );
      },
    );
  }
}

class _AdminTemplatesTab extends ConsumerWidget {
  const _AdminTemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Select folder from folder management to manage templates.'),
    );
  }
}

class _AdminOrganizationsTab extends ConsumerWidget {
  const _AdminOrganizationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.adminListOrganizations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('No organizations'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              title: Text(row['name']?.toString() ?? '-'),
              subtitle: Text(row['orgId']?.toString() ?? ''),
            );
          },
        );
      },
    );
  }
}

class _AdminAuditTab extends ConsumerWidget {
  const _AdminAuditTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getAuditLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final rows = (snapshot.data?['rows'] is List)
            ? (snapshot.data!['rows'] as List).whereType<Map>().toList()
            : <Map>[];
        if (rows.isEmpty) {
          return const Center(child: Text('No logs'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              title: Text(row['action']?.toString() ?? row['event']?.toString() ?? '-'),
              subtitle: Text(row['createdAtLabel']?.toString() ?? row.toString()),
            );
          },
        );
      },
    );
  }
}
