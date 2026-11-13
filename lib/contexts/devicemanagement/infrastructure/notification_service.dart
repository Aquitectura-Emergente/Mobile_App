import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../services/app_i18n.dart';

/// Local notifications (no Firebase): the app raises a device notification
/// when a DANGER-level reading arrives over the WebSocket, respecting the
/// "Push alerts" switch in Settings.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> showDangerAlert(String deviceName, double? value) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'emsafe_alerts',
        'Radiation alerts',
        channelDescription: 'DANGER-level radiation notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: tr('notif_dangerTitle'),
      body: '$deviceName: ${value?.toStringAsFixed(1) ?? '--'} µT',
      notificationDetails: details,
    );
  }
}
