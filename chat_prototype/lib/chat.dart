import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:chat_prototype/video_player.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'data/static.dart';
import 'helper/date_to_string.dart';
import 'helper/downloader.dart';
import 'helper/enum_to_string.dart';
import 'image_viewer.dart';
import 'model/chat.dart';
import 'notification.dart';
import 'storage/database.dart';

class ChatView extends StatefulWidget {
  const ChatView({Key? key, required this.listId, required this.profile, required this.token}) : super(key: key);
  final int listId;
  final Profile profile;
  final String token;
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _control = ScrollController();
  int page = 0;
  bool ifNoPagemore = false;
  bool process = false;
  final ReceivePort _port = ReceivePort();
  int? selectedIdDownload;
  int incrementId = 0;

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
    ++incrementId;
    final person = PersonChat(
      type: Person.me,
      message: '''whatsapp://send?phone=6288217081355&text=test''',
      date: DateTime.now(),
      id: incrementId,
      listId: widget.listId,
      chatType: ChatTypes(
        type: chatType.text,
      ),
    );
    StaticData.addChat(person);
    setState(() {});
    _control.jumpTo(0);
    saveList();
    sendNotification(person, token, widget.token);
  }

  void _me() async {
    ++incrementId;
    final person = PersonChat(
      type: Person.other,
      id: incrementId,
      message: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      date: DateTime.now(),
      listId: widget.listId,
      chatType: ChatTypes(
        type: chatType.file,
        file: Files.video,
        path: '',
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
    setState(() {});
  }

  @override
  void initState() {
    page = 0;
    super.initState();
    _control.addListener(_controllListener);
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');

    _port.listen((dynamic data) async {
      String id = data[0];
      int progress = data[2];
      // try {
      if (progress == 0) {
        await StaticData.updateFileId(id, selectedIdDownload!);
        setState(() {});
      } else {
        Future.delayed(const Duration(milliseconds: 500), () async {
          await StaticData.updateProgress(id, progress);
          setState(() {});
        });
      }
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
                      print(data[index].chatType.path);
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
                                      if (await File(data[index].chatType.path!).exists()) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => BasicPlayerPage(
                                              url: data[index].chatType.path!,
                                            ),
                                          ),
                                        );
                                      } else {
                                        String dir = await getPhoneDirectory(path: '', platform: 'android');
                                        selectedIdDownload = data[index].id;
                                        await download(
                                          context: context,
                                          directory: dir,
                                          url: data[index].message,
                                          fileName: DateFormat('y-M-d-H-m-s').format(DateTime.now()) + '.' + data[index].message.split('.').last,
                                          isOpen: false,
                                          isShare: false,
                                        );
                                      }
                                    } else if (data[index].chatType.file == Files.image) {
                                      if (data[index].chatType.path == null) data[index].chatType.path = '';
                                      if (await File(data[index].chatType.path!).exists()) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ImageViewer(path: data[index].chatType.path!),
                                          ),
                                        );
                                      } else {
                                        String dir = await getPhoneDirectory(path: '', platform: 'android');
                                        selectedIdDownload = data[index].id;
                                        await download(
                                          context: context,
                                          directory: dir,
                                          url: data[index].message,
                                          fileName: DateFormat('y-M-d-H-m-s').format(DateTime.now()) + '.' + data[index].message.split('.').last,
                                          isOpen: false,
                                          isShare: false,
                                        );
                                      }
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
                                data[index].chatType.type == chatType.text ? text : fileWidget(data[index], setState),
                                Text(
                                  DateFormat('HH:mm:ss').format(data[index].date),
                                ),
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
            heroTag: "btn2",
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          Positioned(
            bottom: 70,
            child: FloatingActionButton(
              heroTag: "btn3",
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

Widget fileWidget(PersonChat data, state) {
  if (data.chatType.file == Files.image && data.chatType.status == 1) {
    return Container(
      width: 100,
      height: 50,
      decoration: BoxDecoration(
          image: DecorationImage(
        image: FileImage(
          File(data.chatType.path!),
        ),
      )),
    );
  } else if (data.chatType.file == Files.video && data.chatType.status == 1) {
    return Container(
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        image: data.chatType.thumnailMemory == null
            ? null
            : DecorationImage(
                image: MemoryImage(
                  data.chatType.thumnailMemory!,
                ),
              ),
      ),
    );
  }
  return Row(
    children: [
      const Icon(Icons.file_download),
      CircularProgressIndicator(
        value: data.chatType.progress / 100,
      ),
    ],
  );
}
