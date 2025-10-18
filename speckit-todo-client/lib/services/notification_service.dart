import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_tray/system_tray.dart';

import '../models/todo.dart';

class NotificationService {
  NotificationService();

  static const _channelId = 'speckit_focus_channel';
  static const _notificationId = 101;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) async {
        if (Platform.isWindows) {
          final window = AppWindow();
          await window.show();
          await window.focus();
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      'Speckit Focus',
      description: 'Keep the most important todo visible',
      importance: Importance.max,
      playSound: false,
      showBadge: false,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(androidChannel);
    }
  }

  Future<void> updateTopTodo(Todo? top, List<Todo> todos) async {
    if (top == null) {
      await _plugin.cancel(_notificationId);
      return;
    }

    final lines = todos
        .where((todo) => todo.isActive)
        .take(15)
        .map((todo) => todo.title)
        .toList();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'Speckit Focus',
      channelDescription: 'Keep the most important todo visible',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      category: AndroidNotificationCategory.reminder,
      showWhen: false,
      styleInformation: InboxStyleInformation(
        lines,
        summaryText:
            lines.length > 1 ? '${lines.length} todos on deck' : 'Stay focused',
      ),
    );

    const windowsDetails = WindowsNotificationDetails();
    const linuxDetails = LinuxNotificationDetails(urgency: LinuxNotificationUrgency.critical);

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      windows: windowsDetails,
      linux: linuxDetails,
    );

    await _plugin.show(
      _notificationId,
      top.title,
      'Tap to review your list',
      notificationDetails,
    );
  }
}
