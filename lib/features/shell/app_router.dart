import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../admin/admin_screen.dart';
import '../auth/presentation/auth_screen.dart';
import '../home/home_screen.dart';
import '../messages/messages_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../users/user_profile_screen.dart';
import 'bootstrap_gate_screen.dart';
import '../tasks/tasks_screen.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: '/bootstrap',
    refreshListenable: GoRouterRefreshStream(client.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = client.auth.currentSession != null;
      final onAuth = state.matchedLocation == '/auth';
      final onBootstrap = state.matchedLocation == '/bootstrap';

      if (!loggedIn && !onAuth) return '/auth';
      if (loggedIn && onAuth) return '/bootstrap';
      if (!loggedIn && onBootstrap) return '/auth';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/bootstrap',
        builder: (context, state) => const BootstrapGateScreen(),
      ),
      GoRoute(
        path: '/participation',
        builder: (context, state) => const ParticipationScreen(),
      ),
      GoRoute(
        path: '/users/:userId',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          opaque: true,
          transitionDuration: const Duration(milliseconds: 220),
          child: UserProfileScreen(
            userId: state.pathParameters['userId'] ?? '',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offset =
                Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
            return SlideTransition(position: offset, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/messages/direct/:userId',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          opaque: true,
          transitionDuration: const Duration(milliseconds: 220),
          child: DirectChatScreen(userId: state.pathParameters['userId'] ?? ''),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offset =
                Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
            return SlideTransition(position: offset, child: child);
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(currentLocation: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TasksScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MessagesScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AdminScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
