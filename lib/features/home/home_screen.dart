import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getHomeContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.apiError}: ${snapshot.error}'));
        }
        final data = snapshot.data ?? {};
        final overview = (data['overview'] is Map)
            ? Map<String, dynamic>.from(data['overview'] as Map)
            : <String, dynamic>{};

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(routeDataRepositoryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MetricCard(
                title: 'Open Tasks',
                value: '${overview['openTaskCount'] ?? 0}',
              ),
              _MetricCard(
                title: 'Unread Messages',
                value: '${overview['unreadMessageCount'] ?? 0}',
              ),
              _MetricCard(
                title: 'Pending Users',
                value: '${overview['pendingUserCount'] ?? 0}',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
