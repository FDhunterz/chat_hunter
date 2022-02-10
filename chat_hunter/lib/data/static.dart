import 'dart:io';

import 'package:chat_hunter/helper/downloader.dart';
import 'package:chat_hunter/model/chat.dart';
import 'package:chat_hunter/storage/database.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Function? chatViewState;
bool isInChat = false;

String? token;

class StaticData {
  static List allChat = [];
  static List<PersonChat> chat = [];
  static List<ListChat> list = [];
  static List<ListChat> baseList = [];

  static allChatInit(List chat) {
    allChat = chat;
  }

  static searchList(data) async {
    list = baseList.where((element) => element.person!.name.toString().toUpperCase().contains(data.toString().toUpperCase())).toList();
  }

  static setChat() {
    chat = [];
    allChat = [];
    // chat.sort((a, b) => a.date.compareTo(b.date));
  }

  static readChat(ListChat list) {
    ChatDatabase.updateRead(id: list.id);
    list.read = 0;
  }

  static addChat(PersonChat chatData, {lastestData}) async {
    if (allChat.where((element) => DateTime.parse(element['date'].toString().split(' ').first).difference(DateTime.parse(DateFormat('yyyy-MM-dd').format(chatData.date))).inDays == 0 && element['isLabel'] == 'true').isEmpty) {
      final person = PersonChat(
        chatType: chatData.chatType,
        type: chatData.type,
        message: chatData.message,
        date: chatData.date,
        isLabel: true,
        person: chatData.person,
        listId: chatData.listId,
        timezone: chatData.timezone,
        id: chatData.id,
      );
      chat.add(person);
      person.message = person.message.replaceAll("'", '{|||}').replaceAll('"', '{|-|}');
      await ChatDatabase.insert(data: person, lastestData: lastestData ?? DateTime.now());
    } else {
      chat.add(chatData);
      try {
        await ChatDatabase.insert(data: chatData, lastestData: lastestData);
      } catch (_) {
        chatData.id = (chatData.id ?? 0) + 1;
        await ChatDatabase.insert(data: chatData, lastestData: lastestData);
      }
    }

    chat.sort((a, b) => a.date.compareTo(b.date));
  }

  static addChatBackground(PersonChat chatData, List list) async {
    chat.add(chatData);
    print(chatData.chatType.file);

    await ChatDatabase.insert(data: chatData, read: isInChat ? 0 : (list.first['read'] ?? 0) + 1);
  }

  static addFromDatabase(PersonChat chatData) async {
    chat.add(chatData);
    chat.sort((a, b) => a.date.compareTo(b.date));
  }

  static addListChat(ListChat data) async {
    await ChatDatabase.insertListChat(data: data);
    list.add(data);
  }

  static updateFileId(String? id, int index, int idList) async {
    try {
      List<PersonChat> getChats = chat.where((element) => element.id == index).toList();
      if (getChats.isNotEmpty) {
        getChats.first.chatType.idFile = id;
      }
    } catch (_) {
      print(_);
    }
    await ChatDatabase.updateIdFile(
      id: id,
      index: index,
      idList: idList,
    );
  }

  static Future<int?> deleteChat(PersonChat chats) async {
    if (chats.chatType.type == chatType.file) {
      try {
        File(chats.chatType.path!).delete();
      } catch (_) {}
    }
    await ChatDatabase.delete(chats.id, chats.listId);
    chat.removeWhere((element) => element.id == chats.id);
    if (chat.isEmpty) {
      return 0;
    } else {
      return chat.last.id;
    }
  }

  static updateProgress(String? id, int progress) async {
    PersonChat getChat = chat.where((element) => element.chatType.idFile == id).first;
    final task = await FlutterDownloader.loadTasksWithRawQuery(query: 'SELECT * FROM task WHERE task_id="$id"');
    getChat.chatType.progress = progress;
    if (progress >= 100) {
      String dir = await getPhoneDirectory(path: '', platform: 'android');
      getChat.chatType.status = 1;
      getChat.chatType.path = dir + (task?.first.filename ?? '');
      if (getChat.chatType.file == Files.video) {
        getChat.chatType.thumnailMemory = await VideoThumbnail.thumbnailData(
          video: dir + (task!.isNotEmpty ? (task.first.filename ?? '') : ''),
          imageFormat: ImageFormat.JPEG,
          maxWidth: 100, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
          quality: 25,
        );
      }
    }
    await ChatDatabase.progressUpdate(id: id, progress: progress, idList: getChat.listId);
  }

  static updateUploadProgress(int? id, int? idList, int progress) async {
    print(id);
    PersonChat getChat = chat.where((element) => element.id == id && element.listId == idList).first;
    getChat.chatType.progress = progress;
    if (progress >= 100) {
      getChat.chatType.status = 1;
    }
    await ChatDatabase.progressUploadUpdate(id: id.toString(), progress: progress, idList: idList);
  }

  static clearChat() {
    chat.clear();
  }
}
