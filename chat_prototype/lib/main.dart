import 'package:chat_prototype/chat_hunter.dart';
import 'package:chat_prototype/helper/enum_to_string.dart';
import 'package:chat_prototype/list.dart';
import 'package:chat_prototype/storage/database.dart';
import 'package:chat_prototype/template/list/1/list_1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'data/static.dart';
import 'model/chat.dart';
import 'notification.dart';

void main() async {
  runApp(const MyApp());
  await Firebase.initializeApp();
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  token = await FirebaseMessaging.instance.getToken();
  FirebaseMessaging.onBackgroundMessage(notificationHandler);
  WidgetsFlutterBinding.ensureInitialized();

  FlutterDownloader.initialize(debug: false);
  StaticData.setChat();
  ChatHunter.mainInit(
    styleListChat: StyleColor(
      backContainerIconColor: Colors.black12,
      backIconColor: Colors.white,
      backgroundColor: Colors.white,
      componentColor: const Color(0xffFF53A5),
      dateColor: Colors.black45,
      headerColor: const Color(0xffFF53A5),
      messageColor: Colors.black87,
      searchContainerIconColor: Colors.black12,
      searchIconColor: Colors.white,
      textHeaderColor: Colors.white,
      titleColor: Colors.black,
      componentTextColor: Colors.white,
    ),
    message: ChatSnackBarMessage(
      noConnected: 'Please Connect To Internet',
      nullMessage: 'Text Must be Not Null',
      textCopy: 'Copy To Clipboard',
    ),
    titleListChat: 'Message',
    firebaseSetting: FirebaseChatSetting(
      serverId: 'AAAAWPtQC1Y:APA91bHqqDxXxIhDun9O0r5ioD3TvmPAm5LE0UAWdZBXpR_XqhEBRlYMWJTAQtDDIzWXcexG0UuCPhSMn7kmguoeTxa8BnKOnNqYZRsdpq7Pfaoad1f5t79JKlon4Bfifcxiugns92rB',
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        backgroundColor: Colors.white,
      ),
      home: const ListChatView(),
    );
  }
}
