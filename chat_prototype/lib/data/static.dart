import 'package:chat_prototype/helper/downloader.dart';
import 'package:chat_prototype/model/chat.dart';
import 'package:chat_prototype/storage/database.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
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
      await ChatDatabase.insert(data: person, lastestData: lastestData);
    } else {
      chat.add(chatData);

      await ChatDatabase.insert(data: chatData, lastestData: lastestData);
    }
    chat.sort((a, b) => a.date.compareTo(b.date));
  }

  static addChatBackground(PersonChat chatData, List list) async {
    chat.add(chatData);

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

  static updateFileId(String? id, int index) async {
    chat.where((element) => element.id == index).first.chatType.idFile = id;
    await ChatDatabase.updateIdFile(
      id: id,
      index: index,
    );
  }

  static deleteChat(PersonChat chats) async {
    await ChatDatabase.delete(chats.id, chats.listId);
    chat.removeWhere((element) => element.id == chats.id);
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
    await ChatDatabase.progressUpdate(id: id, progress: progress);
  }

  static clearChat() {
    chat.clear();
  }
}
