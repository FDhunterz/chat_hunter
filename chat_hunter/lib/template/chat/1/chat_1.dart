import 'dart:io';

import 'package:chat_hunter/chat_hunter.dart';
import 'package:chat_hunter/data/static.dart';
import 'package:chat_hunter/helper/date_to_string.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:chat_hunter/model/chat.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../chat.dart';
import '../../../image_viewer.dart';
import '../../../video_player.dart';

TextEditingController text = TextEditingController();
GlobalKey getKey = GlobalObjectKey(UniqueKey());
double initSize = 0;
int maxLine = 2;
double currentX = 0, startX = 0, centerWidth = 0, scalePercentage = 0, percentage = 0;
int? selectedId;

updateX(context, offset, setState) {
  currentX += offset * -1;
  setState(() {});
}

Widget templateChat1({
  required context,
  required setState,
  Animation? animation,
  String? title,
  StyleChatColor? style,
  required ScrollController scrollController,
  required Function(String) onSendPressed,
  Function(PersonChat)? onHoldEnd,
  required Function onSendFilePressed,
  required Function(PersonChat) onDownloadPressed,
}) {
  return GestureDetector(
    onTap: () {
      final FocusScopeNode currentScope = FocusScope.of(context);
      if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
        FocusManager.instance.primaryFocus!.unfocus();
      }
      currentX = 0;
      setState(() {});
    },
    child: SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff162f48),
        body: StatefulBuilder(
          builder: (context, state) {
            return Column(
              children: [
                Material(
                  color: style?.backgroundColor ?? Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: Material(
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                              color: Colors.transparent,
                              child: Icon(
                                Icons.chevron_left,
                                color: style?.backIconColor,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          title ?? 'Undefined',
                          style: TextStyle(
                            color: style?.textHeaderColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {},
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: Material(
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                              color: Colors.transparent,
                              child: Icon(
                                Icons.search,
                                color: style?.searchIconColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    color: style?.backgroundColor ?? Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: ListView.builder(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          reverse: true,
                          itemCount: StaticData.chat.length,
                          itemBuilder: (context, index) {
                            final datas = StaticData.chat.reversed.toList();
                            DateTime changeTimeZone = datas[index].date;
                            changeTimeZone = datas[index].timezone! < 0 ? changeTimeZone.add(Duration(microseconds: datas[index].timezone! * -1)) : changeTimeZone.subtract(Duration(microseconds: datas[index].timezone!));
                            changeTimeZone = changeTimeZone.add(Duration(milliseconds: DateTime.now().timeZoneOffset.inMilliseconds));
                            final date = dateToString(changeTimeZone);
                            bool isShow = datas[index].isLabel;
                            List<TextSpan> linkText = [];
                            Widget text = Row();
                            if (datas[index].chatType.type == chatType.text) {
                              List sliceLinkOrDeeplink = datas[index].message.replaceAll('\n', ' %2526 ').split(' ');
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
                                      style: TextStyle(
                                        color: datas[index].type == Person.me ? Colors.white : Colors.black,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  );
                                } else {
                                  linkText.add(
                                    TextSpan(
                                      text: data == '%2526' ? '\n' : data + ' ',
                                      style: TextStyle(
                                        color: datas[index].type == Person.me ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  );
                                }
                              }
                              text = RichText(
                                text: TextSpan(
                                  text: '',
                                  children: linkText.toList(),
                                  style: TextStyle(
                                    color: datas[index].type == Person.me ? Colors.white : Colors.black,
                                  ),
                                ),
                              );
                            }
                            return Builder(builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  child: Column(
                                    children: [
                                      isShow
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Material(
                                                color: style?.backgroundColor,
                                                borderRadius: const BorderRadius.all(Radius.circular(20)),
                                                elevation: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                                                  child: Text(
                                                    date,
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox(),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 3.0),
                                        child: GestureDetector(
                                          onLongPress: () {
                                            Clipboard.setData(ClipboardData(text: datas[index].message));

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(ChatHunter.messageSetting?.textCopy ?? ''),
                                              ),
                                            );
                                          },
                                          onHorizontalDragStart: (start) {
                                            selectedId = datas[index].id;
                                            startX = start.globalPosition.dx;
                                          },
                                          onHorizontalDragUpdate: (update) {
                                            updateX(context, startX - update.globalPosition.dx, state);
                                            startX = update.globalPosition.dx;
                                          },
                                          onHorizontalDragEnd: (end) async {
                                            if (onHoldEnd != null) {
                                              await onHoldEnd(datas[index]);
                                            }
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment: datas[index].type == Person.me ? MainAxisAlignment.end : MainAxisAlignment.start,
                                            children: [
                                              Stack(
                                                alignment: Alignment.centerRight,
                                                children: [
                                                  Positioned(
                                                    right: datas[index].type == Person.me ? 0 : null,
                                                    left: datas[index].type == Person.other ? 0 : null,
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        incrementId = await StaticData.deleteChat(datas[index]) ?? 0;
                                                        print(incrementId);
                                                        setState(() {});
                                                      },
                                                      child: const Icon(Icons.delete),
                                                    ),
                                                  ),
                                                  Transform.translate(
                                                    offset: Offset(selectedId == datas[index].id ? currentX : 0, 0),
                                                    child: Material(
                                                      color: datas[index].type == Person.me ? const Color(0xff162f48) : const Color(0xffdadada),
                                                      borderRadius: datas[index].type == Person.me
                                                          ? const BorderRadius.only(
                                                              topLeft: Radius.circular(20),
                                                              topRight: Radius.circular(20),
                                                              bottomLeft: Radius.circular(20),
                                                            )
                                                          : const BorderRadius.only(
                                                              topLeft: Radius.circular(20),
                                                              topRight: Radius.circular(20),
                                                              bottomRight: Radius.circular(20),
                                                            ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            datas[index].chatType.type == chatType.text
                                                                ? ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8), child: text)
                                                                : fileWidget(
                                                                    datas[index],
                                                                    setState,
                                                                    context,
                                                                    () {
                                                                      onDownloadPressed(datas[index]);
                                                                    },
                                                                  ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: datas[index].type == Person.me ? MainAxisAlignment.end : MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('HH:mm:ss').format(changeTimeZone) + ' ' + datas[index].id.toString(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: style?.dateColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      datas[index].type == Person.me
                                          ? Row(
                                              mainAxisAlignment: datas[index].type == Person.me ? MainAxisAlignment.end : MainAxisAlignment.start,
                                              children: [
                                                datas[index].status == Status.pending
                                                    ? const Icon(
                                                        Icons.lock_clock,
                                                        size: 12,
                                                      )
                                                    : datas[index].status == Status.send
                                                        ? const Icon(
                                                            Icons.send,
                                                            size: 12,
                                                          )
                                                        : const Icon(
                                                            Icons.check,
                                                            size: 12,
                                                          ),
                                              ],
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: 0,
                        child: Row(
                          children: [
                            Expanded(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: initSize == 0 ? 100 : initSize * 5,
                                ),
                                child: Container(
                                  key: getKey,
                                  child: Text(
                                    text.text + '1',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            const Icon(
                              Icons.send,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              scrollPadding: EdgeInsets.zero,
                              textInputAction: TextInputAction.newline,
                              maxLines: maxLine,
                              controller: text,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Masukkan Pesan',
                                hintStyle: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              onChanged: (data) {
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  final box = getKey.currentContext?.size?.height;
                                  maxLine = ((box ?? initSize) / initSize).round();
                                  if (maxLine > 6) maxLine = 5;
                                  if (maxLine < 2) maxLine = 2;
                                  state(() {});
                                });
                                state(() {});
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await onSendPressed(text.text);

                              text.text = '';
                              maxLine = 2;
                              setState(() {});
                              state(() {});
                            },
                            child: const Icon(
                              Icons.send,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await onSendFilePressed();
                            },
                            child: const Icon(
                              Icons.file_copy_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

Widget fileWidget(PersonChat data, state, context, onDownloadPressed) {
  print(data.chatType.path);
  if (data.chatType.file == Files.image && (data.chatType.path != '' && data.chatType.path != null)) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewer(
              path: data.chatType.path ?? '',
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: data.type == Person.me
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
              image: DecorationImage(
                image: FileImage(
                  File(data.chatType.path!),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          data.chatType.progress == 100
              ? const SizedBox()
              : SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: data.chatType.progress == 100 || data.chatType.progress == 0 ? null : (data.chatType.progress / 100),
                  ),
                ),
        ],
      ),
    );
  } else if (data.chatType.file == Files.video && data.chatType.status == 1) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HunterPlayer(
              path: data.chatType.path ?? '',
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            child: Image.memory(data.chatType.thumnailMemory!),
            borderRadius: data.type == Person.me
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
          ),
          const Icon(
            Icons.play_arrow,
            size: 40,
          ),
          data.chatType.progress == 100
              ? const SizedBox()
              : SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: data.chatType.progress == 100 || data.chatType.progress == 0 ? null : (data.chatType.progress / 100),
                  ),
                ),
        ],
      ),
    );
  }
  return GestureDetector(
    onTap: () {
      onDownloadPressed();
    },
    child: Row(
      children: [
        const Icon(Icons.file_download),
        CircularProgressIndicator(
          value: data.chatType.progress / 100,
        ),
      ],
    ),
  );
}
