import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_env.dart';
import '../../core/providers/core_providers.dart';
import '../auth/application/auth_controller.dart';
import '../shared/session_providers.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  final String currentLocation;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _testAccounts = <String>[
    'admin@shiftflow.local',
    'manager@shiftflow.local',
    'member@shiftflow.local',
  ];

  bool _headerVisible = true;
  bool _switchingAccount = false;

  int _resolveCurrentIndex(List<_NavDestination> destinations) {
    for (var i = 0; i < destinations.length; i++) {
      if (widget.currentLocation == destinations[i].path) {
        return i;
      }
    }
    return widget.currentLocation.startsWith('/messages/direct/') ? 3 : 0;
  }

  String _resolveTitle(Map<String, dynamic>? currentUnit) {
    if (widget.currentLocation.startsWith('/messages')) {
      return currentUnit?['name']?.toString() ?? 'メッセージ';
    }
    if (widget.currentLocation.startsWith('/tasks')) return 'タスク';
    if (widget.currentLocation.startsWith('/search')) return '検索';
    if (widget.currentLocation.startsWith('/settings')) return '設定';
    if (widget.currentLocation.startsWith('/admin')) return '管理';
    return 'ホーム';
  }

  Future<void> _changeCurrentUnit() async {
    final units = ref.read(availableUnitsProvider);
    if (units.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('現在地ユニットを選択')),
            for (final unit in units)
              ListTile(
                title: Text(
                  unit['pathText']?.toString() ??
                      unit['name']?.toString() ??
                      '-',
                ),
                trailing: unit['isCurrent'] == true
                    ? const Icon(Icons.check)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(unit['id']?.toString() ?? ''),
              ),
          ],
        ),
      ),
    );
    if (selected == null || selected.isEmpty) return;
    await ref.read(routeDataRepositoryProvider).changeCurrentUnit(selected);
    ref.invalidate(bootstrapDataProvider);
  }

  Future<void> _switchToTestAccount(String email) async {
    if (_switchingAccount) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テストアカウントへ切替'),
        content: Text('$email へ切り替えます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('戻る'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('切替'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _switchingAccount = true;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signOut();
      await client.auth.signInWithPassword(
        email: email,
        password: AppEnv.qaDefaultPassword.isNotEmpty
            ? AppEnv.qaDefaultPassword
            : 'TestPass123!',
      );
      ref.invalidate(bootstrapDataProvider);
      ref.invalidate(userSettingsProvider);
      if (!mounted) return;
      context.go('/bootstrap');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('アカウント切替に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _switchingAccount = false;
        });
      }
    }
  }

  Widget _buildTitle() {
    final currentUnit = ref.watch(currentUnitProvider);
    final title = _resolveTitle(currentUnit);
    if (widget.currentLocation == '/messages') {
      return TextButton.icon(
        onPressed: _changeCurrentUnit,
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_drop_down),
        label: Text(title),
      );
    }
    return Text(title);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final headerHeight = topInset + kToolbarHeight;
    final canAdmin = ref.watch(isManagerOrAdminProvider);
    final settings = ref.watch(userSettingsProvider).valueOrNull;
    final email = settings?['email']?.toString() ?? '';
    final displayName = settings?['name']?.toString() ?? email;
    final showQaTools = kDebugMode && AppEnv.enableQaTools;

    final destinations = const <_NavDestination>[
      _NavDestination('ホーム', Icons.home_outlined, '/home'),
      _NavDestination('タスク', Icons.task_alt_outlined, '/tasks'),
      _NavDestination('検索', Icons.search, '/search'),
      _NavDestination('メッセージ', Icons.mail_outline, '/messages'),
    ];

    final selectedIndex = _resolveCurrentIndex(destinations);
    final isDesktop = MediaQuery.sizeOf(context).width >= 992;

    return Scaffold(
      drawerEnableOpenDragGesture: true,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(displayName.isEmpty ? 'アカウント' : displayName),
                subtitle: Text(email),
              ),
              if (showQaTools) ...[
                const SizedBox(height: 16),
                Text(
                  'テストアカウント切替',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final accountEmail in _testAccounts)
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text(accountEmail),
                    onTap: _switchingAccount
                        ? null
                        : () => _switchToTestAccount(accountEmail),
                  ),
              ],
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('設定'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/settings');
                },
              ),
              if (canAdmin)
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('管理'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/admin');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
                onTap: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_headerVisible ? headerHeight : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: _headerVisible ? headerHeight : 0,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: headerHeight,
              child: SizedBox(
                height: headerHeight,
                child: AppBar(
                  toolbarHeight: kToolbarHeight,
                  automaticallyImplyLeading: false,
                  centerTitle: true,
                  leading: Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.blur_on),
                      tooltip: 'メニュー',
                    ),
                  ),
                  title: _buildTitle(),
                ),
              ),
            ),
          ),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.depth > 0) return false;
          if (notification.direction == ScrollDirection.reverse &&
              _headerVisible) {
            setState(() {
              _headerVisible = false;
            });
          } else if (notification.direction == ScrollDirection.forward &&
              !_headerVisible) {
            setState(() {
              _headerVisible = true;
            });
          }
          return false;
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x52517CB2), Color(0x1F5E7AB8), Color(0x00FFFFFF)],
              stops: [0, 0.54, 1],
            ),
          ),
          child: SafeArea(
            top: false,
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 240,
                        child: Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                for (var i = 0; i < destinations.length; i++)
                                  _DesktopNavButton(
                                    destination: destinations[i],
                                    selected: i == selectedIndex,
                                  ),
                                const Divider(height: 24),
                                _DesktopUtilityButton(
                                  icon: Icons.settings_outlined,
                                  label: '設定',
                                  onTap: () => context.go('/settings'),
                                ),
                                if (canAdmin)
                                  _DesktopUtilityButton(
                                    icon: Icons.shield_outlined,
                                    label: '管理',
                                    onTap: () => context.go('/admin'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: widget.child),
                    ],
                  )
                : widget.child,
          ),
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

class _DesktopNavButton extends StatelessWidget {
  const _DesktopNavButton({required this.destination, required this.selected});

  final _NavDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      leading: Icon(destination.icon),
      title: Text(destination.label),
      onTap: () => context.go(destination.path),
    );
  }
}

class _DesktopUtilityButton extends StatelessWidget {
  const _DesktopUtilityButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.destinations, required this.selectedIndex});

  final List<_NavDestination> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 52 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      color: const Color(0xFF517CB2),
      child: Row(
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => context.go(destinations[i].path),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(destinations[i].icon, color: Colors.white),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: i == selectedIndex
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
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

class _NavDestination {
  const _NavDestination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
