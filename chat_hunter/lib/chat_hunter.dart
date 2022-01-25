import 'dart:typed_data';

import 'package:chat_hunter/notif_setting.dart';
import 'package:chat_hunter/storage/database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notification;
import 'package:video_thumbnail/video_thumbnail.dart';

import 'data/static.dart';
import 'helper/downloader.dart';
import 'helper/enum_to_string.dart';
import 'list.dart';
import 'model/chat.dart';
import 'notification.dart';
export 'package:chat_hunter/model/chat.dart';

class ChatHunter {
  static BuildContext? context;
  static late String tokenApp;
  static bool ifNoPagemore = false;
  static int incrementId = 0;
  static int page = 0;
  static DateTime? newest;
  static ChatSnackBarMessage? _messageSetting;
  static Template? _templateSetting;
  static StyleColor? _styleListSetting;
  static StyleChatColor? _styleChatSetting;
  static String? listTitle;
  static FirebaseChatSetting? _firebaseSetting;
  static notification.FlutterLocalNotificationsPlugin notificationHunter = notification.FlutterLocalNotificationsPlugin();

  static ChatSnackBarMessage? get messageSetting => _messageSetting;
  static Template? get templateSetting => _templateSetting;
  static StyleColor? get styleListSetting => _styleListSetting;
  static StyleChatColor? get styleChatSetting => _styleChatSetting;
  static FirebaseChatSetting? get firebaseSetting => _firebaseSetting;

  /// After runApp() in main.dart
  static Future<void> mainInit({ChatSnackBarMessage? message, Template? template, StyleColor? styleListChat, StyleChatColor? styleChat, String? titleListChat, FirebaseChatSetting? firebaseSetting}) async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(notificationHandler);
    WidgetsFlutterBinding.ensureInitialized();
    FlutterDownloader.initialize(debug: false);

    await initNotif();

    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    token = await FirebaseMessaging.instance.getToken();
    tokenApp = token ?? '';
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await notificationHandler(message);
    });
    _messageSetting = message ??
        ChatSnackBarMessage(
          noConnected: '',
          nullMessage: '',
          textCopy: '',
        );

    _templateSetting = template ?? Template.standart;
    _styleListSetting = styleListChat;
    _styleChatSetting = styleChat;
    _styleListSetting = styleListChat;
    listTitle = titleListChat;
    _firebaseSetting = firebaseSetting;
  }

  static Widget chat() {
    return const ListChatView();
  }

  static initChat() {
    incrementId = 0;
    page = 0;
    newest = null;
  }

  static Future<List<ListChat>> getListChat() async {
    StaticData.list.clear();
    final list = await ChatDatabase.getDataListChat();
    counter = list.length;
    for (var i in list) {
      StaticData.list.add(
        ListChat(
          id: i['id'],
          person: Profile(name: i['person_name'], pathImage: i['person_image']),
          read: i['read'] ?? 0,
          updated: DateTime.fromMillisecondsSinceEpoch(i['updated']),
          lastMessage: i['message'] == 'null' ? null : i['message'],
          chatType: ChatTypes(type: enumChatTypeParse(i['chatType']) ?? chatType.text),
          token: i['token'],
          groupToken: i['groupToken'],
        ),
      );
    }
    StaticData.baseList = StaticData.list;
    return StaticData.list;
  }

  static Future<List<PersonChat>> getChat({required int listChatId}) async {
    String dir = await getPhoneDirectory(path: '', platform: 'android');
    final data = await ChatDatabase.getData(
      idList: listChatId,
    );
    if (data.isEmpty) {
      ifNoPagemore = true;
      return [];
    }
    StaticData.allChat = [];
    StaticData.allChatInit(data);
    Iterable<Map<dynamic, dynamic>> getListData = data.skip(page * 20).take(20).toList().reversed;
    try {
      newest = DateTime.parse(getListData.last['date']);
    } catch (_) {}
    for (var i in getListData) {
      incrementId = i['id'];
      List<DownloadTask>? task = [];
      Uint8List? uint8list;
      if (enumChatTypeParse(i['chatType']) == chatType.file) {
        task = await FlutterDownloader.loadTasksWithRawQuery(query: 'SELECT * FROM task WHERE task_id="${i['idFile']}"');
        if (enumFileTypeParse(i['fileType']) == Files.video) {
          try {
            uint8list = await VideoThumbnail.thumbnailData(
              video: dir + (task!.isNotEmpty ? (task.first.filename ?? '') : ''),
              imageFormat: ImageFormat.JPEG,
              maxWidth: 100, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            );
          } catch (_) {}
        }
      }

      final person = PersonChat(
        type: enumPersonParse(i['type']),
        message: i['message'].replaceAll('{|||}', "'").replaceAll('{|-|}', '"'),
        date: DateTime.parse(i['date']),
        id: i['id'],
        isLabel: i['isLabel'] == 'true' ? true : false,
        listId: listChatId,
        status: enumStatusParse(i['status']),
        person: i['person_name'] != 'null' && i['person_image'] != 'null'
            ? Profile(
                name: i['person_name'],
                pathImage: i['person_image'],
              )
            : null,
        timezone: i['time_zone'],
        chatType: ChatTypes(
          type: enumChatTypeParse(i['chatType']),
          file: enumFileTypeParse(i['fileType']),
          thumnailMemory: uint8list,
          status: task!.isNotEmpty
              ? task.first.progress == 100
                  ? 1
                  : 0
              : 0,
          progress: task.isNotEmpty
              ? task.first.progress == 100
                  ? 1
                  : 0
              : 0,
          path: dir + (task.isNotEmpty ? (task.first.filename ?? '') : ''),
        ),
      );

      StaticData.addFromDatabase(person);
    }
    return StaticData.chat;
  }

  static Future<MessageStatus> sendMessage({message, required ListChat data}) async {
    if (message == '') {
      return MessageStatus.empty;
    }
    ++incrementId;
    final person = PersonChat(
      type: Person.me,
      message: message,
      date: DateTime.now(),
      timezone: DateTime.now().timeZoneOffset.inMicroseconds,
      id: incrementId,
      listId: data.id,
      chatType: ChatTypes(
        type: chatType.text,
      ),
    );
    StaticData.addChat(
      person,
      lastestData: newest,
    );
    person.message = person.message.replaceAll("'", '{|||}').replaceAll('"', '{|-|}');
    await sendNotification(person, token, data.token);
    await ChatDatabase.updateStatus(idList: data.id, status: Status.send);
    StaticData.chat.where((element) => element.id == incrementId).first.status = Status.send;
    return MessageStatus.sended;
  }

  static addListChat({required ListChat data}) async {
    await StaticData.addListChat(data);
  }
}
