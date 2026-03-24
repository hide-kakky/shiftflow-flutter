class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String appFlavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'prod',
  );
  static const bool enableQaTools = bool.fromEnvironment(
    'ENABLE_QA_TOOLS',
    defaultValue: false,
  );
  static const String qaDefaultPassword = String.fromEnvironment(
    'QA_DEFAULT_PASSWORD',
    defaultValue: '',
  );

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY are required. '
        'Run with --dart-define for both values.',
      );
    }
  }
}
