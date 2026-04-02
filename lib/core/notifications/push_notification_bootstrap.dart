import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/shared/session_providers.dart';
import '../providers/core_providers.dart';
import 'push_notification_service.dart';

class PushNotificationBootstrap extends ConsumerStatefulWidget {
  const PushNotificationBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PushNotificationBootstrap> createState() =>
      _PushNotificationBootstrapState();
}

class _PushNotificationBootstrapState
    extends ConsumerState<PushNotificationBootstrap> {
  ProviderSubscription<User?>? _userSubscription;
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>?
  _userSettingsSubscription;

  @override
  void initState() {
    super.initState();
    final client = ref.read(supabaseClientProvider);

    PushNotificationService.ensureInitialized(client);

    _userSubscription = ref.listenManual<User?>(currentUserProvider, (_, next) {
      if (next == null) {
        PushNotificationService.syncUserSession(client, null);
      }
    }, fireImmediately: true);

    _userSettingsSubscription = ref
        .listenManual<AsyncValue<Map<String, dynamic>>>(userSettingsProvider, (
          _,
          next,
        ) {
          next.whenData((settings) {
            PushNotificationService.syncUserSession(
              client,
              settings['userId']?.toString(),
            );
          });
        }, fireImmediately: true);
  }

  @override
  void dispose() {
    _userSubscription?.close();
    _userSettingsSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
