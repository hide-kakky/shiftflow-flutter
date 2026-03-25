import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../auth/application/auth_controller.dart';
import '../shared/session_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  final String currentLocation;
  final Widget child;

  int _resolveCurrentIndex(List<_NavDestination> destinations) {
    for (var i = 0; i < destinations.length; i++) {
      if (currentLocation == destinations[i].path) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canAdmin = ref.watch(isManagerOrAdminProvider);
    final settings = ref.watch(userSettingsProvider).valueOrNull;
    final email = settings?['email']?.toString() ?? '';

    final destinations = <_NavDestination>[
      _NavDestination(l10n.navHome, Icons.home_outlined, '/home'),
      _NavDestination(l10n.navTasks, Icons.task_outlined, '/tasks'),
      _NavDestination(l10n.navMessages, Icons.chat_bubble_outline, '/messages'),
      _NavDestination(l10n.navSettings, Icons.settings_outlined, '/settings'),
      if (canAdmin)
        _NavDestination(
            l10n.navAdmin, Icons.admin_panel_settings_outlined, '/admin'),
    ];

    final normalizedIndex = _resolveCurrentIndex(destinations);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: normalizedIndex,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
        onDestinationSelected: (index) {
          context.go(destinations[index].path);
        },
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
