import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );
  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );
  static const String firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '',
  );
  static const String firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );
  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: '',
  );

  static String get firebasePlatformAppId {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        firebaseIosAppId.isNotEmpty) {
      return firebaseIosAppId;
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        firebaseAndroidAppId.isNotEmpty) {
      return firebaseAndroidAppId;
    }
    return firebaseAppId;
  }

  static bool get hasFirebaseMessagingConfig =>
      firebaseApiKey.isNotEmpty &&
      firebasePlatformAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebasePlatformAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
    iosBundleId: firebaseIosBundleId.isEmpty ? null : firebaseIosBundleId,
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
