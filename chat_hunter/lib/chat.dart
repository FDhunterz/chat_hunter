import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:chat_hunter/chat_hunter.dart';
import 'package:chat_hunter/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'template/chat/1/chat_1.dart';

int incrementId = 0;
DateTime? newest;

class ChatView extends StatefulWidget {
  const ChatView({Key? key, required this.listId, required this.profile, required this.token}) : super(key: key);
  final int listId;
  final Profile profile;
  final String token;
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver, TickerProviderStateMixin {
  final ScrollController _control = ScrollController();
  int page = 0;
  bool ifNoPagemore = false;
  bool process = false;
  final ReceivePort _port = ReceivePort();
  int? selectedIdDownload;
  bool isConnected = false;
  StreamSubscription<ConnectivityResult>? subscription;

  static Animation? _animationSlide;
  static AnimationController? _animationSlideC;

  _animate(context, state, Person who) {
    if (who == Person.me) {
      if (currentX < -30) {
        _animationSlide = Tween(begin: currentX, end: -30).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
          ..addListener(() {
            double parsedX = currentX + (_animationSlide?.value ?? 0);
            percentage = (parsedX / centerWidth);
            currentX = _animationSlide?.value * 1.0;
            state(() {});
          });
        Future.delayed(const Duration(milliseconds: 350), () {
          _animationSlide = Tween(begin: -30, end: 0.0).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
            ..addListener(() {
              state(() {});
            });
          _animationSlideC!.reset();
          state(() {});
        });
        _animationSlideC!.forward();
      } else {
        _animationSlide = Tween(begin: currentX, end: 0).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
          ..addListener(() {
            currentX = _animationSlide?.value * 1.0;
            state(() {});
          });
        Future.delayed(const Duration(milliseconds: 350), () {
          currentX = 0;
          _animationSlide = Tween(begin: 0.0, end: 0.0).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
            ..addListener(() {
              state(() {});
            });
          _animationSlideC!.reset();
          state(() {});
        });
        _animationSlideC!.forward();
      }
    } else {
      if (currentX > 30) {
        _animationSlide = Tween(begin: currentX, end: 30).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
          ..addListener(() {
            currentX = _animationSlide?.value * 1.0;
            state(() {});
          });
        Future.delayed(const Duration(milliseconds: 350), () {
          _animationSlide = Tween(begin: 30, end: 0.0).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
            ..addListener(() {
              state(() {});
            });
          _animationSlideC!.reset();
          state(() {});
        });
        _animationSlideC!.forward();
      } else {
        _animationSlide = Tween(begin: currentX, end: 0).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
          ..addListener(() {
            currentX = _animationSlide?.value * 1.0;
            state(() {});
          });
        Future.delayed(const Duration(milliseconds: 350), () {
          currentX = 0;
          _animationSlide = Tween(begin: 0.0, end: 0.0).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
            ..addListener(() {
              state(() {});
            });
          _animationSlideC!.reset();
          state(() {});
        });
        _animationSlideC!.forward();
      }
    }
  }

  initAnimation() {
    Future.delayed(Duration.zero, () {
      if (_animationSlideC != null) {
        _animationSlide = Tween(begin: 0.0, end: MediaQuery.of(context).size.width * 0.3).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
          ..addListener(() {
            setState(() {});
          });
      } else {
        _animationSlide = Tween(begin: 0.0, end: MediaQuery.of(context).size.width * 0.3).animate(CurvedAnimation(parent: _animationSlideC!, curve: Curves.easeIn))
          ..addListener(() {
            setState(() {});
          });
        _animationSlideC!.reset();
      }
      setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      isInChat = false;
    } else if (state == AppLifecycleState.resumed) {
      isInChat = true;
      StaticData.chat.clear();
      await getData();
      setState(() {});
    }
  }

  _controllListener() {
    if (_control.position.maxScrollExtent <= _control.offset && !process) {
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

  _sendMessage(texts) async {
    if (texts == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ChatHunter.messageSetting?.nullMessage ?? ''),
        ),
      );
      return;
    }
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ChatHunter.messageSetting?.noConnected ?? ''),
        ),
      );
      return;
    }
    ++incrementId;
    final person = PersonChat(
      type: Person.me,
      message: texts,
      date: DateTime.now(),
      timezone: DateTime.now().timeZoneOffset.inMicroseconds,
      id: incrementId,
      listId: widget.listId,
      chatType: ChatTypes(
        type: chatType.text,
      ),
    );
    StaticData.addChat(
      person,
      lastestData: newest,
    );
    text.text = '';
    setState(() {});
    person.message = person.message.replaceAll("'", '{|||}').replaceAll('"', '{|-|}');
    await sendNotification(person, token, widget.token);
    await ChatDatabase.updateStatus(idList: widget.listId, status: Status.send);
    StaticData.chat.where((element) => element.id == incrementId).first.status = Status.send;
    setState(() {});
  }

  void _me() async {
    ++incrementId;
    final person = PersonChat(
      type: Person.other,
      id: incrementId,
      message: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      date: DateTime.now(),
      timezone: DateTime.now().timeZoneOffset.inMicroseconds,
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
        listId: widget.listId,
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
    setState(() {});
  }

  void checkConnection(ConnectivityResult result) async {
    if (result == ConnectivityResult.mobile) {
      isConnected = true;
    } else if (result == ConnectivityResult.wifi) {
      isConnected = true;
    } else {
      isConnected = false;
    }
    setState(() {});
  }

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    WidgetsBinding.instance!.addObserver(this);
    isInChat = true;
    chatViewState = setState;

    Future.delayed(Duration.zero, () async {
      _animationSlideC = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      initAnimation();

      currentX = 0;
      startX = 0;
      scalePercentage = 0;
      percentage = 0;
      final box = getKey.currentContext?.size?.height;
      initSize = (box ?? 0);
      centerWidth = MediaQuery.of(context).size.width;
    });
    maxLine = 2;
    text.text = '';
    page = 0;
    super.initState();
    subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      checkConnection(result);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (chatViewState == setState) {
        await notificationHandler(message);
        if (message.data['types'] == 'chat') {
          await chatRead(message);
          await readSend(token, widget.token);
        }
        StaticData.chat.clear();
        await getData();
      }
    });
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
    isInChat = false;
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    WidgetsBinding.instance!.removeObserver(this);
    subscription!.cancel();
    super.dispose();
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return templateChat1(
      context: context,
      setState: setState,
      title: widget.profile.name,
      scrollController: _control,
      animation: _animationSlide,
      onHoldEnd: (personChat) {
        _animate(context, setState, personChat.type);
      },
      onSendPressed: (text) async {
        await _sendMessage(text);
      },
    );
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text(widget.profile.name),
    //   ),
    //   body: Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Expanded(
    //           child: Padding(
    //             padding: const EdgeInsets.only(bottom: 100),
    //             child: Padding(
    //               padding: const EdgeInsets.all(16.0),
    //               child: ListView.builder(
    //                 controller: _control,
    //                 reverse: true,
    //                 itemCount: StaticData.chat.length,
    //                 itemBuilder: (context, index) {
    //                   final data = StaticData.chat.reversed.toList();
    //                   DateTime changeTimeZone = data[index].date;
    //                   changeTimeZone = data[index].timezone! < 0 ? changeTimeZone.add(Duration(microseconds: data[index].timezone! * -1)) : changeTimeZone.subtract(Duration(microseconds: data[index].timezone!));
    //                   changeTimeZone = changeTimeZone.add(Duration(milliseconds: DateTime.now().timeZoneOffset.inMilliseconds));
    //                   final date = dateToString(changeTimeZone);
    //                   bool isShow = data[index].isLabel;
    //                   List<TextSpan> linkText = [];
    //                   Widget text = Row();
    //                   if (data[index].chatType.type == chatType.text) {
    //                     List sliceLinkOrDeeplink = data[index].message.replaceAll('\n', ' %2526 ').split(' ');
    //                     for (int i = 0; i < sliceLinkOrDeeplink.length; i++) {
    //                       String data = sliceLinkOrDeeplink[i];
    //                       if (data.contains('://')) {
    //                         linkText.add(
    //                           TextSpan(
    //                             text: data.replaceAll('%2526', '\n') + ' ',
    //                             onEnter: (pointer) {},
    //                             recognizer: TapGestureRecognizer()
    //                               ..onTap = () {
    //                                 launch(data, forceWebView: false, forceSafariVC: false);
    //                               },
    //                             style: const TextStyle(
    //                               color: Colors.blue,
    //                               decoration: TextDecoration.underline,
    //                             ),
    //                           ),
    //                         );
    //                       } else {
    //                         linkText.add(
    //                           TextSpan(
    //                             text: data == '%2526' ? '\n' : data + ' ',
    //                             style: const TextStyle(
    //                               color: Colors.black,
    //                             ),
    //                           ),
    //                         );
    //                       }
    //                     }
    //                     text = SizedBox(
    //                       width: MediaQuery.of(context).size.width * 0.8,
    //                       child: RichText(
    //                         text: TextSpan(
    //                           text: '',
    //                           children: linkText.toList(),
    //                         ),
    //                       ),
    //                     );
    //                   }
    //                   return Padding(
    //                     padding: const EdgeInsets.only(bottom: 12.0),
    //                     child: InkWell(
    //                       focusColor: Colors.transparent,
    //                       hoverColor: Colors.transparent,
    //                       splashColor: Colors.transparent,
    //                       highlightColor: Colors.transparent,
    //                       onTap: data[index].chatType.type == chatType.text
    //                           ? null
    //                           : () async {
    //                               if (data[index].chatType.type == chatType.file) {
    //                                 if (data[index].chatType.file == Files.video) {
    //                                   if (await File(data[index].chatType.path!).exists()) {
    //                                     Navigator.of(context).push(
    //                                       MaterialPageRoute(
    //                                         builder: (context) => BasicPlayerPage(
    //                                           url: data[index].chatType.path!,
    //                                         ),
    //                                       ),
    //                                     );
    //                                   } else {
    //                                     String dir = await getPhoneDirectory(path: '', platform: 'android');
    //                                     selectedIdDownload = data[index].id;
    //                                     await download(
    //                                       context: context,
    //                                       directory: dir,
    //                                       url: data[index].message,
    //                                       fileName: DateFormat('y-M-d-H-m-s').format(changeTimeZone) + '.' + data[index].message.split('.').last,
    //                                       isOpen: false,
    //                                       isShare: false,
    //                                     );
    //                                   }
    //                                 } else if (data[index].chatType.file == Files.image) {
    //                                   if (data[index].chatType.path == null) data[index].chatType.path = '';
    //                                   if (await File(data[index].chatType.path!).exists()) {
    //                                     Navigator.push(
    //                                       context,
    //                                       MaterialPageRoute(
    //                                         builder: (context) => ImageViewer(path: data[index].chatType.path!),
    //                                       ),
    //                                     );
    //                                   } else {
    //                                     String dir = await getPhoneDirectory(path: '', platform: 'android');
    //                                     selectedIdDownload = data[index].id;
    //                                     await download(
    //                                       context: context,
    //                                       directory: dir,
    //                                       url: data[index].message,
    //                                       fileName: DateFormat('y-M-d-H-m-s').format(changeTimeZone) + '.' + data[index].message.split('.').last,
    //                                       isOpen: false,
    //                                       isShare: false,
    //                                     );
    //                                   }
    //                                 } else {
    //                                   launch(data[index].message);
    //                                 }
    //                               }
    //                             },
    //                       child: SizedBox(
    //                         width: MediaQuery.of(context).size.width * 0.8,
    //                         child: Column(
    //                           crossAxisAlignment: data[index].type == Person.me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    //                           children: [
    //                             isShow ? Center(child: Text(date)) : const SizedBox(),
    //                             data[index].chatType.type == chatType.text ? text : fileWidget(data[index], setState),
    //                             Text(
    //                               DateFormat('HH:mm:ss').format(changeTimeZone) + ' ' + (data[index].type == Person.me ? data[index].status.toString() : ''),
    //                             ),
    //                           ],
    //                         ),
    //                       ),
    //                     ),
    //                   );
    //                 },
    //               ),
    //             ),
    //           ),
    //         ),
    //         Padding(
    //           padding: const EdgeInsets.symmetric(horizontal: 12.0),
    //           child: TextFormField(
    //             controller: text,
    //             decoration: const InputDecoration(
    //               hintText: 'Masukkan Pesan',
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    //   floatingActionButton: Stack(
    //     alignment: Alignment.bottomRight,
    //     children: [
    //       const Center(),
    //       FloatingActionButton(
    //         heroTag: "btn2",
    //         onPressed: _incrementCounter,
    //         tooltip: 'Increment',
    //         child: const Icon(Icons.add),
    //       ),
    //       // Positioned(
    //       //   bottom: 70,
    //       //   child: FloatingActionButton(
    //       //     heroTag: "btn3",
    //       //     onPressed: _me,
    //       //     tooltip: 'Increment',
    //       //     child: const Icon(Icons.ac_unit),
    //       //   ),
    //       // )
    //     ],
    //   ), // This trailing comma makes auto-formatting nicer for build methods.
    // );
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
