import 'package:chat_prototype/data/static.dart';
import 'package:chat_prototype/helper/enum_to_string.dart';
import 'package:chat_prototype/model/chat.dart';
import 'package:chat_prototype/storage/database.dart';
import 'package:flutter/material.dart';

import 'chat.dart';

int counter = 0;

class ListChatView extends StatefulWidget {
  const ListChatView({Key? key}) : super(key: key);

  @override
  _ListChatViewState createState() => _ListChatViewState();
}

class _ListChatViewState extends State<ListChatView> {
  _addPerson() async {
    ++counter;
    await StaticData.addListChat(
      ListChat(
        id: counter,
        person: Profile(name: 'Testing $counter', pathImage: 'assets/p.png'),
        read: 0,
        updated: DateTime.now(),
        lastMessage: 'Belum Ada Pesan',
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
      print(i['chatType']);
      StaticData.list.add(
        ListChat(
          id: i['id'],
          person: Profile(name: i['person_name'], pathImage: i['person_image']),
          read: i['read'].floor(),
          updated: DateTime.fromMillisecondsSinceEpoch(i['updated']),
          lastMessage: i['message'] == 'null' ? null : i['message'],
          chatType: ChatTypes(type: enumChatTypeParse(i['chatType']) ?? chatType.text),
        ),
      );
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _getList();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: StaticData.list.length,
              itemBuilder: (context, index) {
                ListChat data = StaticData.list[index];
                return GestureDetector(
                  onTap: () {
                    StaticData.chat.clear();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatView(
                          listId: data.id!,
                          profile: data.person!,
                        ),
                      ),
                    ).then((value) async {
                      await _getList();
                      setState(() {});
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(data.person!.pathImage),
                          ),
                        ),
                      ),
                      Expanded(
                        child: data.chatType!.type == chatType.file
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data.person?.name ?? ''),
                                  Row(
                                    children: [
                                      const Icon(Icons.bookmark),
                                      Text(
                                        data.lastMessage!.split('/').last,
                                        overflow: TextOverflow.fade,
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data.person?.name ?? ''),
                                  SizedBox(
                                    height: 18,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data.lastMessage ?? '',
                                            overflow: TextOverflow.fade,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addPerson();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
