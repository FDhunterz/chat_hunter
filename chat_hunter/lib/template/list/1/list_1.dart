import 'package:chat_hunter/data/static.dart';
import 'package:chat_hunter/helper/date_to_string.dart';
import 'package:chat_hunter/model/chat.dart';
import 'package:flutter/material.dart';

import '../../search.dart';

Widget templateList1({
  required context,
  required setState,
  Function(ListChat)? onListTap,
  String? title,
  StyleColor? style,
}) {
  style ??= StyleColor(
    backgroundColor: Colors.white,
    componentColor: const Color(0xff2c4159),
    componentTextColor: Colors.white,
    headerColor: const Color(0xff162f48),
    textHeaderColor: Colors.white,
    dateColor: Colors.black54,
    backIconColor: Colors.white,
    searchIconColor: Colors.white,
    backContainerIconColor: const Color(0xff2c4159),
    searchContainerIconColor: const Color(0xff2c4159),
    messageColor: Colors.black,
    titleColor: Colors.black,
  );
  return GestureDetector(
    onTap: () {
      final FocusScopeNode currentScope = FocusScope.of(context);
      if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
        FocusManager.instance.primaryFocus!.unfocus();
      }
    },
    child: SafeArea(
      child: Scaffold(
        backgroundColor: style.headerColor,
        body: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: Material(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      color: style.backContainerIconColor,
                      child: Icon(
                        Icons.chevron_left,
                        color: style.backIconColor,
                      ),
                    ),
                  ),
                  Text(
                    title ?? 'Messages',
                    style: TextStyle(
                      color: style.textHeaderColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await searchBottom(context);
                      setState(() {});
                    },
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: Material(
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        color: style.searchContainerIconColor,
                        child: Icon(
                          Icons.search,
                          color: style.searchIconColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: Material(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                color: style.backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ListView.builder(
                      itemCount: StaticData.list.length,
                      itemBuilder: (context, index) {
                        ListChat data = StaticData.list[index];
                        return InkWell(
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            if (onListTap != null) {
                              onListTap(data);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: style?.componentColor,
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: NetworkImage(data.person?.pathImage ?? ''),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.person?.name ?? data.groupToken ?? 'Undefined',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: style?.titleColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      Text(
                                        data.lastMessage ?? '',
                                        style: TextStyle(
                                          color: style?.messageColor,
                                          fontSize: 11,
                                          overflow: TextOverflow.ellipsis,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        dateToStringList(data.updated!),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: style?.dateColor,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      data.read == null
                                          ? const SizedBox()
                                          : data.read! <= 0
                                              ? const SizedBox()
                                              : Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: style?.componentColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      data.read.toString(),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: style?.componentTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
