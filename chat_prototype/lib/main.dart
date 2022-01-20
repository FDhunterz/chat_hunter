import 'package:chat_prototype/helper/enum_to_string.dart';
import 'package:chat_prototype/list.dart';
import 'package:chat_prototype/storage/database.dart';
import 'package:chat_prototype/template/list/1/list_1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
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
      // home: const TemplateList1(),
    );
  }
}
