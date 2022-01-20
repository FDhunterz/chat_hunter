import 'dart:async';
import 'dart:convert';
import 'package:chat_prototype/chat.dart';
import 'package:chat_prototype/helper/enum_to_string.dart';
import 'package:chat_prototype/storage/database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:request_api_helper/request.dart' as req;
import 'package:request_api_helper/request_api_helper.dart';

import 'data/static.dart';
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
          'timezone': DateTime.now().timeZoneOffset.inMicroseconds,
          'file_type': enumFileTypeParse(chatData.chatType.file),
          'chat_type': enumChatTypeParse(chatData.chatType.type),
          'date': DateTime.now().toString(),
          'types': 'chat',
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

Future<Map<String, dynamic>> typingSend(token, otherToken, bool isTipeUp) async {
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
          'token': token,
          'types': isTipeUp ? 'typeup' : 'typedown',
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

Future<Map<String, dynamic>> readSend(token, otherToken) async {
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
          'token': token,
          'types': 'read',
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

Future<bool> notificationHandler(RemoteMessage message) async {
  bool stat = false;
  if (message.data['types'] == 'typeup') {
  } else if (message.data['types'] == 'typedown') {
  } else if (message.data['types'] == 'chat') {
    await chatInputGlobal(message);
  } else if (message.data['types'] == 'read') {
    await chatRead(message);
  }
  return stat;
}

Future<bool> chatRead(RemoteMessage message) async {
  bool stat = false;
  try {
    final dataList = await ChatDatabase.getDataListChat();
    List list = dataList.where((element) => element['groupToken'] == message.data['token']).toList();
    await ChatDatabase.updateStatus(idList: list.first['id'], status: Status.read);

    final data = await ChatDatabase.getData(
      idList: list.isNotEmpty ? list.first['id'] : 0,
    );
  } catch (_) {
    print(_);
  }
  return stat;
}

Future<bool> chatInputGlobal(RemoteMessage message) async {
  bool stat = false;
  final dataList = await ChatDatabase.getDataListChat();
  List list = dataList.where((element) => element['groupToken'] == message.data['token']).toList();
  if (list.isEmpty) {
    await StaticData.addListChat(
      ListChat(
        id: dataList.length + 1,
        person: Profile(name: 'Testing ${dataList.length + 1}', pathImage: 'assets/p.png'),
        read: 1,
        updated: DateTime.now(),
        lastMessage: message.data['message'],
        groupToken: message.data['token'],
        token: message.data['token'],
        chatType: ChatTypes(type: chatType.text),
      ),
    );
    final dataLists = await ChatDatabase.getDataListChat();
    list = dataLists.where((element) => element['groupToken'] == message.data['token']).toList();
  }
  final data = await ChatDatabase.getData(
    idList: list.isNotEmpty ? list.first['id'] : 0,
  );
  bool label = false;
  if (data.isEmpty) {
    label = true;
  } else if (data.where((element) => DateTime.parse(element['date'].toString().split(' ').first).difference(DateTime.parse(message.data['date'].toString().split(' ').first)).inDays == 0 && element['isLabel'] == 'true').isEmpty) {
    label = true;
  }

  final person = PersonChat(
    type: Person.other,
    id: data.isEmpty ? 0 : data.first['id'] + 1,
    message: message.data['message'],
    date: DateTime.parse(message.data['date']),
    listId: list.first['id'],
    person: Profile(
      name: message.data['person'],
      pathImage: message.data['person_name'],
    ),
    timezone: int.parse(message.data['timezone']),
    isLabel: label,
    chatType: ChatTypes(
      type: enumChatTypeParse(int.parse(message.data['chat_type'])),
      file: enumFileTypeParse(int.parse(message.data['file_type'])),
      path: '',
    ),
  );
  await StaticData.addChatBackground(person, list);
  if (isInChat) {
    ++incrementId;
  }
  return stat;
}
