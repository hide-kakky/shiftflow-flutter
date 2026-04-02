import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationPermissionService {
  NotificationPermissionService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const AndroidNotificationChannel _messagesChannel =
      AndroidNotificationChannel(
        'messages',
        'Messages',
        description: '新規メッセージ通知',
        importance: Importance.max,
      );

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings);
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_messagesChannel);
    _initialized = true;
  }

  static Future<void> showForegroundNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'messages',
        'Messages',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
