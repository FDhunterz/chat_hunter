import 'dart:io';

import 'package:chat_prototype/data/static.dart';
import 'package:chat_prototype/helper/date_to_string.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:chat_prototype/model/chat.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

TextEditingController text = TextEditingController();
GlobalKey getKey = GlobalObjectKey(UniqueKey());
double initSize = 0;
int maxLine = 1;
double currentX = 0, startX = 0, centerWidth = 0, scalePercentage = 0, percentage = 0;
int? selectedId;

updateX(context, offset, setState) {
  currentX += offset * -1;
  percentage = (currentX / centerWidth);
  scalePercentage = 0.13 * percentage;
  setState(() {});
}

class StyleChatColor {
  Color backgroundColor = const Color(0xff2c4159),
      componentColor = const Color(0xff2c4159),
      componentTextColor = Colors.white,
      headerColor = const Color(0xff2c4159),
      textHeaderColor = Colors.white,
      titleColor,
      messageColor,
      dateColor = Colors.black54,
      backIconColor = Colors.white,
      searchIconColor = Colors.white,
      backContainerIconColor = const Color(0xff2c4159),
      searchContainerIconColor = const Color(
        0xff2c4159,
      );
  StyleChatColor({
    required this.backContainerIconColor,
    required this.backIconColor,
    required this.backgroundColor,
    required this.componentColor,
    required this.dateColor,
    required this.headerColor,
    required this.messageColor,
    required this.searchContainerIconColor,
    required this.searchIconColor,
    required this.textHeaderColor,
    required this.titleColor,
    required this.componentTextColor,
  });
}

Widget templateChat1({
  required context,
  required setState,
  Animation? animation,
  String? title,
  StyleChatColor? style,
  required ScrollController scrollController,
  required Function(String) onSendPressed,
  Function? onHoldEnd,
}) {
  return GestureDetector(
    onTap: () {
      final FocusScopeNode currentScope = FocusScope.of(context);
      if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
        FocusManager.instance.primaryFocus!.unfocus();
      }
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
                                              await onHoldEnd();
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
                                                    right: 10,
                                                    child: Icon(Icons.delete),
                                                  ),
                                                  Transform.translate(
                                                    offset: Offset(selectedId == datas[index].id ? (currentX + (animation?.value ?? 0)) : 0, 0),
                                                    child: Material(
                                                      color: datas[index].type == Person.me ? const Color(0xff162f48) : Colors.black12,
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
                                                            datas[index].chatType.type == chatType.text ? ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8), child: text) : fileWidget(datas[index], setState),
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
                                            DateFormat('HH:mm:ss').format(changeTimeZone),
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
                              maxLines: maxLine,
                              controller: text,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Masukkan Pesan',
                                hintStyle: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              onChanged: (data) {
                                state(() {});
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  final box = getKey.currentContext?.size?.height;
                                  maxLine = ((box ?? initSize) / initSize).round();
                                  if (maxLine > 6) maxLine = 5;
                                  if (maxLine < 1) maxLine = 1;
                                  state(() {});
                                });
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await onSendPressed(text.text);

                              text.text = '';
                              maxLine = 1;
                              setState(() {});
                              state(() {});
                            },
                            child: const Icon(
                              Icons.send,
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
