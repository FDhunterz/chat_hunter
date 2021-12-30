import 'package:chat_prototype/video_player.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'data/static.dart';
import 'helper/date_to_string.dart';
import 'helper/enum_to_string.dart';
import 'model/chat.dart';
import 'storage/database.dart';

class ChatView extends StatefulWidget {
  const ChatView({Key? key, required this.listId, required this.profile}) : super(key: key);
  final int listId;
  final Profile profile;
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _control = ScrollController();
  int page = 0;
  bool ifNoPagemore = false;
  bool process = false;

  _controllListener() {
    if (_control.position.maxScrollExtent == _control.offset && !process) {
      process = true;
      if (ifNoPagemore) {
        return;
      }
      ++page;
      getData();
      Future.delayed(const Duration(seconds: 1), () {
        process = false;
      });
    }
  }

  void _incrementCounter() async {
    final person = PersonChat(
      type: Person.other,
      message: 'lol',
      date: DateTime.now(),
      listId: widget.listId,
    );
    StaticData.addChat(person);
    setState(() {});
    _control.jumpTo(0);
    // saveList();
  }

  void _me() async {
    // final person = PersonChat(
    //   type: Person.me,
    //   message: 'its me',
    //   date: DateTime.now(),
    //   listId: widget.listId,
    // );
    // StaticData.addChat(person);
    // setState(() {});
    // _control.jumpTo(0);
    // saveList();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const BasicPlayerPage()));
  }

  saveList() async {
    await ChatDatabase.insertList(data: [
      PersonChat(
        type: Person.me,
        message: 'lol 111111',
        date: DateTime.now(),
      ),
      PersonChat(
        type: Person.me,
        message: 'lol 222222',
        date: DateTime.now(),
      ),
      PersonChat(
        type: Person.me,
        message: 'lol 333333',
        date: DateTime.now(),
      )
    ]);
  }

  getData() async {
    final data = await ChatDatabase.getData(
      idList: widget.listId,
    );
    if (data.isEmpty) {
      ifNoPagemore = true;
      return;
    }
    for (var i in data.skip(page * 20).take(20).toList().reversed) {
      final person = PersonChat(
        type: enumPersonParse(i['type']),
        message: i['message'],
        date: DateTime.parse(i['date']),
        id: i['id'],
        isLabel: i['isLabel'] == 'true' ? true : false,
        listId: widget.listId,
        person: i['person_name'] != 'null' && i['person_image'] != 'null'
            ? Profile(
                name: i['person_name'],
                pathImage: i['person_image'],
              )
            : null,
      );

      StaticData.addFromDatabase(person);
    }
    setState(() {});
  }

  @override
  void initState() {
    page = 0;
    super.initState();
    _control.addListener(_controllListener);
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    controller: _control,
                    reverse: true,
                    itemCount: StaticData.chat.length,
                    itemBuilder: (context, index) {
                      final data = StaticData.chat.reversed.toList();
                      final date = dateToString(data[index].date);
                      bool isShow = data[index].isLabel;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: data[index].type == Person.me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            isShow ? Center(child: Text(date)) : const SizedBox(),
                            Text(data[index].message),
                            Text(DateFormat('HH:mm:ss').format(data[index].date)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          const Center(),
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          Positioned(
            bottom: 70,
            child: FloatingActionButton(
              onPressed: _me,
              tooltip: 'Increment',
              child: const Icon(Icons.ac_unit),
            ),
          )
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
