import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

initNotif() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: (String? payload) async {
      if (payload != null) {}
    },
  );
}

Future<void> showNotification({id, title, body, token}) async {
  AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails('$id', 'max', channelDescription: 'Max', importance: Importance.max, priority: Priority.high, ticker: 'ticker');
  NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(id, title, body, platformChannelSpecifics, payload: token);
}
