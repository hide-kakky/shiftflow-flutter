import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../../features/shared/route_data_repository.dart';

class ExternalUrlLauncher {
  const ExternalUrlLauncher();

  Future<bool> launch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(supabaseClientProvider));
});

final routeDataRepositoryProvider = Provider<RouteDataRepository>((ref) {
  return RouteDataRepository(ref.watch(apiClientProvider));
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>((ref) {
  return const ExternalUrlLauncher();
});
