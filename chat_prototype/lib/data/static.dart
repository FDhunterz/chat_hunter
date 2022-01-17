import 'package:chat_prototype/helper/downloader.dart';
import 'package:chat_prototype/model/chat.dart';
import 'package:chat_prototype/storage/database.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

String? token;

class StaticData {
  static List<PersonChat> chat = [];
  static List<ListChat> list = [];

  static setChat() {
    chat = [];
    // chat.sort((a, b) => a.date.compareTo(b.date));
  }

  static addChat(PersonChat chatData) async {
    if (chat.where((element) => DateTime.parse(DateFormat('yyyy-MM-dd').format(element.date)).difference(DateTime.parse(DateFormat('yyyy-MM-dd').format(chatData.date))).inDays == 0 && element.isLabel).isEmpty) {
      final person = PersonChat(
        chatType: chatData.chatType,
        type: chatData.type,
        message: chatData.message,
        date: chatData.date,
        isLabel: true,
        person: chatData.person,
        listId: chatData.listId,
        id: chatData.id,
      );
      chat.add(person);
      await ChatDatabase.insert(data: person);
    } else {
      chat.add(chatData);

      await ChatDatabase.insert(data: chatData);
    }
    chat.sort((a, b) => a.date.compareTo(b.date));
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
    print(index);
    chat.where((element) => element.id == index).first.chatType.idFile = id;
    await ChatDatabase.updateIdFile(
      id: id,
      index: index,
    );
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
