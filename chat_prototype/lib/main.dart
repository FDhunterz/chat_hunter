import 'package:chat_prototype/helper/enum_to_string.dart';
import 'package:chat_prototype/list.dart';
import 'package:chat_prototype/storage/database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'data/static.dart';
import 'model/chat.dart';

Future _backgroundMessageHandler(RemoteMessage message) async {
  ChatDatabase.deleteDatabases();

  final dataList = await ChatDatabase.getDataListChat();
  List list = dataList.where((element) => element['groupToken'] == message.data['token']).toList();

  if (list.isEmpty) {
    await StaticData.addListChat(
      ListChat(
        id: dataList.length + 1,
        person: Profile(name: 'Testing ${dataList.length + 1}', pathImage: 'assets/p.png'),
        read: 0,
        updated: DateTime.now(),
        lastMessage: 'Belum Ada Pesan',
        groupToken: message.data['token'],
        chatType: ChatTypes(type: chatType.text),
      ),
    );
    final dataLists = await ChatDatabase.getDataListChat();
    list = dataLists.where((element) => element['groupToken'] == message.data['token']).toList();
  }

  final data = await ChatDatabase.getData(
    idList: list.isNotEmpty ? list.first['id'] : 0,
  );

  print(data);
  print(list);

  final person = PersonChat(
    type: Person.other,
    id: data.isEmpty ? null : data.first['id'] + 1,
    message: message.data['message'],
    date: DateTime.now(),
    listId: list.first['id'],
    person: Profile(
      name: message.data['person'],
      pathImage: message.data['person_name'],
    ),
    chatType: ChatTypes(
      type: enumChatTypeParse(message.data['chat_type']),
      file: enumFileTypeParse(message.data['file_type']),
      path: '',
    ),
  );
  StaticData.addChat(person);
}

void main() async {
  runApp(const MyApp());
  await Firebase.initializeApp();
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  token = await FirebaseMessaging.instance.getToken();
  print(token);
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
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
      ),
      home: const ListChatView(),
    );
  }
}
