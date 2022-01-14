import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:chat_prototype/video_player.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/static.dart';
import 'helper/date_to_string.dart';
import 'helper/downloader.dart';
import 'helper/enum_to_string.dart';
import 'image_viewer.dart';
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
  final ReceivePort _port = ReceivePort();

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
      message: '''whatsapp://send?phone=6288217081355&text=test''',
      date: DateTime.now(),
      listId: widget.listId,
      chatType: ChatTypes(
        type: chatType.text,
      ),
    );
    StaticData.addChat(person);
    setState(() {});
    _control.jumpTo(0);
    // saveList();
  }

  void _me() async {
    final person = PersonChat(
      type: Person.other,
      message: 'https://mediplusclinic.co.id/assets/image/klinik/4711ac8334ade5fa1f3152104f6d1bae.jpg',
      date: DateTime.now(),
      listId: widget.listId,
      chatType: ChatTypes(
        type: chatType.file,
        file: Files.image,
      ),
    );
    StaticData.addChat(person);
    setState(() {});
  }

  saveList() async {}

  getData() async {
    String dir = await getPhoneDirectory(path: '', platform: 'android');
    final data = await ChatDatabase.getData(
      idList: widget.listId,
    );
    if (data.isEmpty) {
      ifNoPagemore = true;
      return;
    }
    for (var i in data.skip(page * 20).take(20).toList().reversed) {
      List<DownloadTask>? task = [];
      if (enumChatTypeParse(i['chatType']) == chatType.file) {
        task = await FlutterDownloader.loadTasksWithRawQuery(query: 'SELECT * FROM task WHERE url="${i['message']}"');
      }

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
        chatType: ChatTypes(
          type: enumChatTypeParse(i['chatType']),
          file: enumFileTypeParse(i['fileType']),
          status: task != null
              ? task.first.progress == 100
                  ? 1
                  : 0
              : 0,
          progress: task?.first.progress == 100 ? 1 : 0,
          path: dir + (task?.first.filename ?? ''),
        ),
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
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      if (progress >= 100) {
        StaticData.chat.clear();
        getData();
      }
      setState(() {});
    });
    FlutterDownloader.registerCallback(downloadCallback);
    getData();
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
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
                      List<TextSpan> linkText = [];
                      Widget text = Row();
                      if (data[index].chatType.type == chatType.text) {
                        List sliceLinkOrDeeplink = data[index].message.replaceAll('\n', ' %2526 ').split(' ');
                        for (int i = 0; i < sliceLinkOrDeeplink.length; i++) {
                          String data = sliceLinkOrDeeplink[i];
                          if (data.contains('://')) {
                            linkText.add(
                              TextSpan(
                                text: data.replaceAll('%2526', '\n') + ' ',
                                onEnter: (pointer) {},
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launch(data, forceWebView: false, forceSafariVC: false);
                                  },
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            );
                          } else {
                            linkText.add(
                              TextSpan(
                                text: data == '%2526' ? '\n' : data + ' ',
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }
                        }
                        text = SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: RichText(
                            text: TextSpan(
                              text: '',
                              children: linkText.toList(),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: data[index].chatType.type == chatType.text
                              ? null
                              : () async {
                                  if (data[index].chatType.type == chatType.file) {
                                    if (data[index].chatType.file == Files.video) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => BasicPlayerPage(
                                            url: data[index].message,
                                          ),
                                        ),
                                      );
                                    } else if (data[index].chatType.file == Files.image) {
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => const ImageViewer(
                                      //       path: 'https://media.istockphoto.com/photos/abstract-wavy-object-picture-id1198271727?b=1&k=20&m=1198271727&s=170667a&w=0&h=b626WM5c-lq9g_yGyD0vgufb4LQRX9UgYNWPaNUVses=',
                                      //     ),
                                      //   ),
                                      // );
                                      String dir = await getPhoneDirectory(path: '', platform: 'android');
                                      await download(
                                        context: context,
                                        directory: dir,
                                        url: data[index].message,
                                        fileName: DateFormat('y-M-d-H-m-s').format(DateTime.now()) + '.' + data[index].message.split('.').last,
                                        isOpen: false,
                                        isShare: false,
                                      );
                                    } else {
                                      launch(data[index].message);
                                    }
                                  }
                                },
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Column(
                              crossAxisAlignment: data[index].type == Person.me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                isShow ? Center(child: Text(date)) : const SizedBox(),
                                data[index].chatType.type == chatType.text
                                    ? text
                                    : (data[index].chatType.file == Files.image && data[index].chatType.status == 1
                                        ? Container(
                                            width: 100,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                              image: FileImage(
                                                File(data[index].chatType.path!),
                                              ),
                                            )),
                                          )
                                        : const Icon(Icons.file_download)),
                                Text(DateFormat('HH:mm:ss').format(data[index].date)),
                              ],
                            ),
                          ),
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
