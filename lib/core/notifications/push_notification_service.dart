import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';
import 'notification_permission_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static SupabaseClient? _client;
  static bool _initialized = false;
  // ignore: unused_field
  static StreamSubscription<String>? _tokenRefreshSubscription;
  // ignore: unused_field
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static String? _currentAppUserId;
  static String? _currentDeviceToken;

  static bool get isConfigured => AppEnv.hasFirebaseMessagingConfig;

  static Future<void> ensureInitialized(SupabaseClient client) async {
    _client = client;
    if (_initialized || !isConfigured || kIsWeb) {
      return;
    }

    await Firebase.initializeApp(options: AppEnv.firebaseOptions);
    await NotificationPermissionService.initialize();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) async {
      _currentDeviceToken = token;
      final activeClient = _client;
      final appUserId = _currentAppUserId;
      if (activeClient == null || appUserId == null || token.isEmpty) {
        return;
      }
      await _upsertSubscription(activeClient, appUserId, token);
    });

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      if (defaultTargetPlatform.name != 'android') {
        return;
      }

      await NotificationPermissionService.showForegroundNotification(
        title:
            message.notification?.title ??
            message.data['title']?.toString() ??
            '新規通知',
        body:
            message.notification?.body ??
            message.data['body']?.toString() ??
            '',
        payload: message.data['sourceId']?.toString(),
      );
    });

    _initialized = true;
  }

  static Future<void> syncUserSession(
    SupabaseClient client,
    String? appUserId,
  ) async {
    _client = client;
    if (!isConfigured || kIsWeb) {
      _currentAppUserId = appUserId;
      return;
    }

    await ensureInitialized(client);

    final token = await FirebaseMessaging.instance.getToken();
    final previousUserId = _currentAppUserId;
    final previousToken = _currentDeviceToken;

    if (previousUserId != null &&
        previousToken != null &&
        (appUserId == null ||
            previousUserId != appUserId ||
            (token != null && token != previousToken))) {
      await _revokeSubscription(client, previousUserId, previousToken);
    }

    _currentAppUserId = appUserId;
    _currentDeviceToken = token;

    if (appUserId == null || token == null || token.isEmpty) {
      return;
    }

    await _upsertSubscription(client, appUserId, token);
  }

  static Future<void> _upsertSubscription(
    SupabaseClient client,
    String appUserId,
    String token,
  ) async {
    await client.from('notification_subscriptions').upsert({
      'user_id': appUserId,
      'provider': 'fcm',
      'device_token': token,
      'platform': defaultTargetPlatform.name,
      'notification_opt_in': true,
      'revoked_at': null,
      'endpoint': null,
      'p256dh': null,
      'auth': null,
      'ua_hash': null,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,provider,device_token');
  }

  static Future<void> _revokeSubscription(
    SupabaseClient client,
    String appUserId,
    String token,
  ) async {
    await client
        .from('notification_subscriptions')
        .update({
          'notification_opt_in': false,
          'revoked_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', appUserId)
        .eq('provider', 'fcm')
        .eq('device_token', token);
  }
}
