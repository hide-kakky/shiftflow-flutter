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
      _NavDestination(l10n.navTasks, Icons.send_outlined, '/tasks'),
      _NavDestination(l10n.navMessages, Icons.mail_outline, '/messages'),
      _NavDestination(l10n.navSettings, Icons.settings_outlined, '/settings'),
      if (canAdmin)
        _NavDestination(l10n.navAdmin, Icons.shield_outlined, '/admin'),
    ];

    final selectedIndex = _resolveCurrentIndex(destinations);
    final isDesktop = MediaQuery.sizeOf(context).width >= 992;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0x614B76C3),
                    Color(0x4D263A78),
                    Color(0xFF081326),
                  ]
                : const [
                    Color(0x52517CB2),
                    Color(0x1F5E7AB8),
                    Color(0x00FFFFFF),
                  ],
            stops: const [0, 0.54, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: isDesktop
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 220,
                        child: _DesktopNav(
                          destinations: destinations,
                          selectedIndex: selectedIndex,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: child),
                    ],
                  ),
                )
              : child,
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _MobileNav(
              destinations: destinations,
              selectedIndex: selectedIndex,
            ),
    );
  }
}

class _DesktopNav extends StatelessWidget {
  const _DesktopNav({required this.destinations, required this.selectedIndex});

  final List<_NavDestination> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < destinations.length; i++) ...[
              _DesktopNavButton(
                destination: destinations[i],
                selected: i == selectedIndex,
              ),
              if (i != destinations.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesktopNavButton extends StatelessWidget {
  const _DesktopNavButton({required this.destination, required this.selected});

  final _NavDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: selected
          ? (isDark ? const Color(0x2ED6E0FF) : Colors.white)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(destination.path),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                destination.icon,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.destinations, required this.selectedIndex});

  final List<_NavDestination> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0A1833)
        : const Color(0xFF517CB2);
    final indicator = isDark ? const Color(0xFF9DB6FF) : Colors.white;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const navContentHeight = 42.0;

    return Container(
      height: navContentHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: background,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x8C050C1C) : const Color(0x2E517CB2),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => context.go(destinations[i].path),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(
                    0,
                    i == selectedIndex ? -4 : 0,
                    0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        destinations[i].icon,
                        color: Colors.white.withValues(
                          alpha: i == selectedIndex ? 1 : 0.92,
                        ),
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 4,
                        width: 32,
                        decoration: BoxDecoration(
                          color: i == selectedIndex
                              ? indicator
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
