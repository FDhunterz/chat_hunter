import 'dart:async';
import 'dart:convert';
import 'package:chat_prototype/helper/enum_to_string.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:request_api_helper/request.dart' as req;
import 'package:request_api_helper/request_api_helper.dart';

import 'model/chat.dart';

// Replace with server token from firebase console settings.
const serverToken = 'AAAAWPtQC1Y:APA91bHqqDxXxIhDun9O0r5ioD3TvmPAm5LE0UAWdZBXpR_XqhEBRlYMWJTAQtDDIzWXcexG0UuCPhSMn7kmguoeTxa8BnKOnNqYZRsdpq7Pfaoad1f5t79JKlon4Bfifcxiugns92rB';

Future<Map<String, dynamic>> sendNotification(PersonChat chatData, token, otherToken) async {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );
  Map<String, dynamic> res = {};
  await req.send(
    type: RESTAPI.post,
    customData: CustomRequestData(
      url: 'https://fcm.googleapis.com/fcm/send',
      header: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      rawJson: json.encode(<String, dynamic>{
        'notification': {},
        'priority': 1,
        'registration_ids': [otherToken],
        'data': {
          'message': chatData.message,
          'person_name': chatData.person?.name ?? '',
          'id': chatData.id,
          'token': token,
          'person': enumChatTypeParse(Person.other),
          'timezone': chatData.timezone,
          'file_type': enumFileTypeParse(chatData.chatType.file),
          'chat_type': enumChatTypeParse(chatData.chatType.type),
        },
      }),
    ),
    changeConfig: RequestApiHelperConfigData(
      withLoading: Redirects(toogle: false),
      logResponse: false,
      onSuccess: (data) {
        res = data;
      },
    ),
  );
  return res;
}
