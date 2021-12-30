import 'package:chat_prototype/model/chat.dart';
import 'package:chat_prototype/storage/database.dart';
import 'package:intl/intl.dart';

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
        type: chatData.type,
        message: chatData.message,
        date: chatData.date,
        isLabel: true,
        person: chatData.person,
        listId: chatData.listId,
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
}
