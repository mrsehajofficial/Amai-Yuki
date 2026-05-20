import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService - A high-performance singleton wrapper for local notifications.
/// Employs a stream-based tap listener so the app can react instantly to click events. - SV
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Stream to broadcast notification clicks back to the UI.
  // Using broadcast since multiple parts of the app may need to tap into this lifecycle hook. - SV
  final StreamController<String> _onNotificationTapController = StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _onNotificationTapController.stream;

  /// Initializes local notification settings. Must be called on main thread start. - SV
  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // Initializing the plugin with a native callback listener that pipes paylods straight into our stream.
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onNotificationTapController.add(payload);
        }
      },
    );
    
    // Request permissions for Android 13+ devices to ensure visual alert compliance.
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
        
    _isInitialized = true;
  }

  /// Checks if the app was originally cold-started by a user clicking a notification.
  /// Extremely crucial for navigating straight into the correct chat when starting up. - SV
  Future<String?> getAppLaunchPayload() async {
    final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      return details.notificationResponse?.payload;
    }
    return null;
  }

  /// Displays a premium push notification banner. Supports optional router payloads. - SV
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'direct_messages',
      'Direct Messages',
      channelDescription: 'Notifications for new direct messages',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Clears a specific active notification by its unique ID (like otherUserId.hashCode).
  /// Used to dismiss active notification bubbles when opening a targeted chat screen. - SV
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) await init();
    await _notificationsPlugin.cancel(id);
  }

  /// Clears all existing notification banners currently displaying in the status bar. - SV
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await init();
    await _notificationsPlugin.cancelAll();
  }
}
