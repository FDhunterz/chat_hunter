import 'package:chat_hunter/chat_hunter.dart';
import 'package:chat_hunter/data/static.dart';
import 'package:chat_hunter/helper/enum_to_string.dart';
import 'package:chat_hunter/model/chat.dart';
import 'package:chat_hunter/storage/database.dart';
import 'package:chat_hunter/template/list/1/list_1.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat.dart';
import 'notification.dart';

int counter = 0;

class ListChatView extends StatefulWidget {
  const ListChatView({Key? key}) : super(key: key);

  @override
  _ListChatViewState createState() => _ListChatViewState();
}

class _ListChatViewState extends State<ListChatView> with WidgetsBindingObserver {
  final TextEditingController text = TextEditingController();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getList();
    }
  }

  _addPerson() async {
    ++counter;
    await StaticData.addListChat(
      ListChat(
        id: counter,
        person: Profile(name: 'Testing $counter', pathImage: 'assets/p.png'),
        read: 0,
        updated: DateTime.now(),
        lastMessage: 'Belum Ada Pesan',
        token: text.text != '' ? text.text : 'fA6cMkfxQAWOGiJmsnWIs-:APA91bG1ERUMX98ncRgl0MAKxDQM2gQAbGB_xE80PB60x43hrUluny4AJ7X6WrS6zEDppaTFj80Mgty1mhKu2n6-t3tgBTTnvb8aKG_-0qHTfeVUojn9vD1-PLNaJ1CiRdsl8CPcPLyK',
        groupToken: text.text != '' ? text.text : 'fA6cMkfxQAWOGiJmsnWIs-:APA91bG1ERUMX98ncRgl0MAKxDQM2gQAbGB_xE80PB60x43hrUluny4AJ7X6WrS6zEDppaTFj80Mgty1mhKu2n6-t3tgBTTnvb8aKG_-0qHTfeVUojn9vD1-PLNaJ1CiRdsl8CPcPLyK',
        chatType: ChatTypes(type: chatType.text),
      ),
    );

    setState(() {});
  }

  _getList() async {
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
    setState(() {});
  }

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xff162f48),
      ),
    );
    chatViewState = setState;
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    Future.delayed(Duration.zero, () async {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (chatViewState == setState) {
          await notificationHandler(message);
          await _getList();
        }
      });
      await _getList();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return templateList1(
      context: context,
      setState: setState,
      style: ChatHunter.styleListSetting,
      title: ChatHunter.listTitle,
      onListTap: (data) async {
        StaticData.clearChat();
        StaticData.readChat(data);
        readSend(token, data.token);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatView(
              listId: data.id!,
              profile: data.person!,
              token: data.token!,
            ),
          ),
        ).then((value) async {
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Color(0xff162f48),
              statusBarIconBrightness: Brightness.light,
            ),
          );
          await _getList();
          chatViewState = setState;
          setState(() {});
        });
      },
    );
  }
}
