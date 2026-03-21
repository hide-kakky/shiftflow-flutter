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
    'name': result['name'] ?? user.email ?? 'User',
    'role': result['role'] ?? 'member',
    'theme': result['theme'] ?? 'system',
    'language': result['language'] ?? 'ja',
    'email': result['email'] ?? user.email ?? '',
  };
});

final userRoleProvider = Provider<String>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.valueOrNull?['role']?.toString() ?? 'guest';
});

final isManagerOrAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'admin' || role == 'manager';
});
