import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/session_providers.dart';

const _homeMaxWidth = 1120.0;
const _warmWhite = Color(0xFFF6F5F4);
const _warmGray = Color(0xFF615D59);
const _notionBlue = Color(0xFF0075DE);
const _notionBlueDark = Color(0xFF005BAB);
const _badgeBlueBg = Color(0xFFF2F9FF);
const _badgeBlueText = Color(0xFF097FE8);
const _successTeal = Color(0xFF2A9D99);
const _warningOrange = Color(0xFFDD5B00);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(routeDataRepositoryProvider);
    final l10n = AppLocalizations.of(context);
    final canAdmin = ref.watch(isManagerOrAdminProvider);

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

        final openTaskCount = _toInt(overview['openTaskCount']);
        final unreadMessageCount = _toInt(overview['unreadMessageCount']);
        final pendingUserCount = _toInt(overview['pendingUserCount']);
        final focusItems = _buildFocusItems(
          l10n: l10n,
          openTaskCount: openTaskCount,
          unreadMessageCount: unreadMessageCount,
          pendingUserCount: pendingUserCount,
          canAdmin: canAdmin,
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(routeDataRepositoryProvider);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _homeMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeHero(
                            openTaskCount: openTaskCount,
                            unreadMessageCount: unreadMessageCount,
                            pendingUserCount: pendingUserCount,
                          ),
                          const SizedBox(height: 24),
                          _SectionHeading(
                            badge: l10n.homeSectionOverviewBadge,
                            title: l10n.homeSectionOverviewTitle,
                            description: l10n.homeSectionOverviewDescription,
                          ),
                          const SizedBox(height: 16),
                          _MetricGrid(
                            items: [
                              _MetricItem(
                                label: l10n.homeOpenTasks,
                                value: '$openTaskCount',
                                accentColor: _notionBlue,
                                helper: l10n.homeOpenTasksHint,
                              ),
                              _MetricItem(
                                label: l10n.homeUnreadMessages,
                                value: '$unreadMessageCount',
                                accentColor: _successTeal,
                                helper: l10n.homeUnreadMessagesHint,
                              ),
                              _MetricItem(
                                label: l10n.homePendingUsers,
                                value: '$pendingUserCount',
                                accentColor: _warningOrange,
                                helper: canAdmin
                                    ? l10n.homePendingUsersHint
                                    : l10n.homePendingUsersHintMember,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: _surfaceTint(context),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _QuickActionsCard(
                                          canAdmin: canAdmin,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _FocusCard(items: focusItems),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _QuickActionsCard(canAdmin: canAdmin),
                                      const SizedBox(height: 16),
                                      _FocusCard(items: focusItems),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

List<_FocusItem> _buildFocusItems({
  required AppLocalizations l10n,
  required int openTaskCount,
  required int unreadMessageCount,
  required int pendingUserCount,
  required bool canAdmin,
}) {
  final items = <_FocusItem>[
    if (openTaskCount > 0)
      _FocusItem(
        title: l10n.homeFocusTasksTitle(openTaskCount),
        description: l10n.homeFocusTasksDescription,
        icon: Icons.check_circle_outline,
      ),
    if (unreadMessageCount > 0)
      _FocusItem(
        title: l10n.homeFocusMessagesTitle(unreadMessageCount),
        description: l10n.homeFocusMessagesDescription,
        icon: Icons.mark_email_unread_outlined,
      ),
    if (canAdmin && pendingUserCount > 0)
      _FocusItem(
        title: l10n.homeFocusPendingUsersTitle(pendingUserCount),
        description: l10n.homeFocusPendingUsersDescription,
        icon: Icons.admin_panel_settings_outlined,
      ),
  ];

  if (items.isNotEmpty) {
    return items;
  }

  return [
    _FocusItem(
      title: l10n.homeFocusStableTitle,
      description: l10n.homeFocusStableDescription,
      icon: Icons.auto_awesome_outlined,
    ),
  ];
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Color _panelColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF181715)
      : Colors.white;
}

Color _surfaceTint(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF22211F)
      : _warmWhite;
}

Color _primaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF6F3EE)
      : const Color(0xFF000000);
}

Color _secondaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFD0CAC2)
      : _warmGray;
}

Color _borderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0x26FFFFFF)
      : const Color(0x1A000000);
}

List<BoxShadow> _softShadow(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ];
  }
  return const [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 18,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x07000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.openTaskCount,
    required this.unreadMessageCount,
    required this.pendingUserCount,
  });

  final int openTaskCount;
  final int unreadMessageCount;
  final int pendingUserCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primaryText = _primaryTextColor(context);
    final secondaryText = _secondaryTextColor(context);

    return Container(
      decoration: BoxDecoration(
        color: _panelColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor(context)),
        boxShadow: _softShadow(context),
      ),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final summary = <_HeroSummaryChip>[
            _HeroSummaryChip(
              label: l10n.homeOpenTasks,
              value: '$openTaskCount',
            ),
            _HeroSummaryChip(
              label: l10n.homeUnreadMessages,
              value: '$unreadMessageCount',
            ),
            _HeroSummaryChip(
              label: l10n.homePendingUsers,
              value: '$pendingUserCount',
            ),
          ];

          final leading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BlueBadge(label: l10n.homeHeroBadge),
              const SizedBox(height: 16),
              Text(
                l10n.homeHeroTitle,
                style: TextStyle(
                  fontSize: constraints.maxWidth >= 760 ? 38 : 30,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: constraints.maxWidth >= 760 ? -1.2 : -0.6,
                  color: primaryText.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.homeHeroDescription,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => context.go('/tasks'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _notionBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(l10n.navTasks),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go('/messages'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(color: _borderColor(context)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(l10n.navMessages),
                  ),
                ],
              ),
            ],
          );

          final trailing = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surfaceTint(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeHeroPanelTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in summary) ...[
                  _HeroSummaryTile(item: item),
                  if (item != summary.last) const SizedBox(height: 10),
                ],
              ],
            ),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(height: 20),
                trailing,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: leading),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: trailing),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.badge,
    required this.title,
    required this.description,
  });

  final String badge;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BlueBadge(label: badge),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            height: 1.1,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w700,
            color: _primaryTextColor(context).withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            height: 1.55,
            color: _secondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items
          .map(
            (item) => SizedBox(
              width: 320,
              child: _MetricCard(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panelColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: item.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _secondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 42,
              height: 1,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor(context).withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.helper,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _secondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.canAdmin});

  final bool canAdmin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <_ActionItem>[
      _ActionItem(
        title: l10n.navTasks,
        description: l10n.homeActionTasksDescription,
        icon: Icons.check_box_outlined,
        path: '/tasks',
      ),
      _ActionItem(
        title: l10n.navMessages,
        description: l10n.homeActionMessagesDescription,
        icon: Icons.mail_outline,
        path: '/messages',
      ),
      _ActionItem(
        title: l10n.navSettings,
        description: l10n.homeActionSettingsDescription,
        icon: Icons.settings_outlined,
        path: '/settings',
      ),
      if (canAdmin)
        _ActionItem(
          title: l10n.navAdmin,
          description: l10n.homeActionAdminDescription,
          icon: Icons.shield_outlined,
          path: '/admin',
        ),
    ];

    return _SectionCard(
      title: l10n.homeQuickActionsTitle,
      description: l10n.homeQuickActionsDescription,
      child: Column(
        children: [
          for (final action in actions) ...[
            _ActionRow(action: action),
            if (action != actions.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.items});

  final List<_FocusItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.homeFocusTitle,
      description: l10n.homeFocusDescription,
      child: Column(
        children: [
          for (final item in items) ...[
            _FocusRow(item: item),
            if (item != items.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panelColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              height: 1.2,
              letterSpacing: -0.25,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor(context).withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: _secondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final _ActionItem action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(action.path),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceTint(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2B2A27)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor(context)),
                ),
                child: Icon(action.icon, color: _notionBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _primaryTextColor(context).withValues(
                          alpha: 0.95,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: _secondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _secondaryTextColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({required this.item});

  final _FocusItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceTint(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2B2A27)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor(context)),
            ),
            child: Icon(item.icon, size: 20, color: _notionBlueDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor(context).withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: _secondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryTile extends StatelessWidget {
  const _HeroSummaryTile({required this.item});

  final _HeroSummaryChip item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panelColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _secondaryTextColor(context),
              ),
            ),
          ),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: _primaryTextColor(context).withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueBadge extends StatelessWidget {
  const _BlueBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17324A) : _badgeBlueBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.12,
          color: isDark ? const Color(0xFF7EC2FF) : _badgeBlueText,
        ),
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.helper,
  });

  final String label;
  final String value;
  final Color accentColor;
  final String helper;
}

class _ActionItem {
  const _ActionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.path,
  });

  final String title;
  final String description;
  final IconData icon;
  final String path;
}

class _FocusItem {
  const _FocusItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _HeroSummaryChip {
  const _HeroSummaryChip({required this.label, required this.value});

  final String label;
  final String value;
}
