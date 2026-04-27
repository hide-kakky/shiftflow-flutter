import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/core_providers.dart';

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});

final bootstrapDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const {
      'participation': {'status': 'unauthenticated', 'canUseApp': false},
      'availableOrganizations': [],
      'availableUnits': [],
      'navigation': {
        'home': false,
        'tasks': false,
        'messages': false,
        'admin': false,
        'settings': true,
      },
      'badges': {
        'allUnreadMessages': 0,
        'currentUnitUnreadMessages': 0,
        'openTasks': 0,
        'pendingJoinRequests': 0,
      },
    };
  }
  final repo = ref.watch(routeDataRepositoryProvider);
  return repo.getBootstrapData();
});

final userSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return {
      'name': 'Guest',
      'role': 'guest',
      'theme': 'system',
      'language': 'ja',
      'email': '',
    };
  }
  final repo = ref.watch(routeDataRepositoryProvider);
  final result = await repo.getUserSettings();
  return {
    'userId': result['userId'],
    'name': result['name'] ?? user.email ?? 'User',
    'imageUrl': result['imageUrl'] ?? '',
    'role': result['role'] ?? 'member',
    'theme': result['theme'] ?? 'system',
    'language': result['language'] ?? 'ja',
    'email': result['email'] ?? user.email ?? '',
  };
});

final userRoleProvider = Provider<String>((ref) {
  final settings = ref.watch(userSettingsProvider).valueOrNull;
  return settings?['organizationRole']?.toString() ??
      settings?['role']?.toString() ??
      'guest';
});

final currentAppUserIdProvider = Provider<String?>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.valueOrNull?['userId']?.toString();
});

final participationStatusProvider = Provider<String>((ref) {
  final bootstrap = ref.watch(bootstrapDataProvider).valueOrNull;
  final participation = bootstrap?['participation'];
  if (participation is Map) {
    return participation['status']?.toString() ?? 'unaffiliated';
  }
  return 'unaffiliated';
});

final currentOrganizationProvider = Provider<Map<String, dynamic>?>((ref) {
  final bootstrap = ref.watch(bootstrapDataProvider).valueOrNull;
  final currentOrganization = bootstrap?['currentOrganization'];
  if (currentOrganization is Map<String, dynamic>) {
    return currentOrganization;
  }
  if (currentOrganization is Map) {
    return currentOrganization.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return null;
});

final currentUnitProvider = Provider<Map<String, dynamic>?>((ref) {
  final bootstrap = ref.watch(bootstrapDataProvider).valueOrNull;
  final currentUnit = bootstrap?['currentUnit'];
  if (currentUnit is Map<String, dynamic>) {
    return currentUnit;
  }
  if (currentUnit is Map) {
    return currentUnit.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
});

final availableOrganizationsProvider = Provider<List<Map<String, dynamic>>>((
  ref,
) {
  final bootstrap = ref.watch(bootstrapDataProvider).valueOrNull;
  final items = bootstrap?['availableOrganizations'];
  if (items is! List) return const [];
  return items
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
});

final availableUnitsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final bootstrap = ref.watch(bootstrapDataProvider).valueOrNull;
  final items = bootstrap?['availableUnits'];
  if (items is! List) return const [];
  return items
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
});

final isManagerOrAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  final bootstrap = ref.watch(bootstrapDataProvider).valueOrNull;
  final participation = bootstrap?['participation'];
  final unitRole = participation is Map
      ? participation['unitRole']?.toString()
      : null;
  return role == 'owner' || role == 'admin' || unitRole == 'manager';
});
