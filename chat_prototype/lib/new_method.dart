import 'package:flutter/services.dart';

const MethodChannel _methodChannel = MethodChannel('com.hunter.check');

class Notifications {
  static Future<void> send({required title, required message, required channel}) async {
    await _methodChannel.invokeMethod('notif', {'title': title, 'message': message, 'channel': channel});
  }
}
