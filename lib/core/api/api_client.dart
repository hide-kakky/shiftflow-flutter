import 'package:supabase_flutter/supabase_flutter.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._supabase);

  final SupabaseClient _supabase;

  Future<dynamic> invokeRoute(
    String route, {
    List<dynamic> args = const [],
    Map<String, dynamic>? extra,
  }) async {
    final payload = <String, dynamic>{
      'route': route,
      if (args.isNotEmpty) 'args': args,
      if (extra != null) ...extra,
    };

    final response = await _supabase.functions.invoke(
      'api',
      body: payload,
    );

    if (response.status >= 400) {
      throw ApiException('HTTP ${response.status}: ${response.data}',
          statusCode: response.status);
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['ok'] == false) {
        throw ApiException('${data['code'] ?? 'api_error'}: ${data['reason'] ?? 'unknown'}');
      }
      return data['result'];
    }
    return data;
  }
}
