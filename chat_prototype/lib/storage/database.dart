import 'package:chat_prototype/helper/enum_to_string.dart';
import 'package:chat_prototype/model/chat.dart';
import 'package:sqflite/sqflite.dart';

class ChatDatabase {
  static String path = '';
  static init() async {
    // Get a location using getDatabasesPath
    var databasesPath = await getDatabasesPath();
    path = databasesPath + 'chat.db';
  }

  static Future<Database> connect() async {
    await init();
    Database database = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute('CREATE TABLE Chat (id INTEGER PRIMARY KEY, idlist REAL ,message TEXT, isLabel TEXT, type TEXT, date TEXT, person_name TEXT, person_image TEXT)');
      await db.execute('CREATE TABLE ListChat (id INTEGER PRIMARY KEY, read REAL,updated INTEGER,person_name TEXT, person_image TEXT, message TEXT)');
    });

    return database;
  }

  static insertListChat({required ListChat data}) async {
    Database db = await connect();
    await db.transaction((txn) async {
      await txn.rawInsert('INSERT INTO ListChat(id,read,person_name,person_image,updated) VALUES(${data.id},${data.read},"${data.person?.name}","${data.person?.pathImage}",${data.updated!.millisecondsSinceEpoch})');
    });
    await db.close();
  }

  static deleteListChat(id) async {
    Database db = await connect();
    await db.rawDelete('DELETE FROM ListChat WHERE id = $id');
    await db.close();
  }

  static insert({required PersonChat data}) async {
    Database db = await connect();
    await db.transaction((txn) async {
      await txn.rawInsert('INSERT INTO Chat(id,idlist,message, isLabel, type,date,person_name,person_image) VALUES(${data.id},${data.listId},"${data.message}","${data.isLabel}","${enumPersonParse(data.type)}","${data.date}","${data.person?.name}","${data.person?.pathImage}")');
      await txn.rawUpdate('UPDATE ListChat SET updated=${data.type == Person.me ? '0' : DateTime.now().millisecondsSinceEpoch},message="${data.message}" WHERE id=${data.listId}');
    });
    await db.close();
  }

  static insertList({required List<PersonChat> data}) async {
    String list = '';
    int count = 0;
    String lastMessage = '';
    for (final i in data) {
      ++count;
      if (count == data.length) {
        list += '(${i.id},${i.listId},"${i.message}","${i.isLabel}","${enumPersonParse(i.type)}","${i.date}","${i.person?.name}","${i.person?.pathImage}")';
      } else {
        list += '(${i.id},${i.listId},"${i.message}","${i.isLabel}","${enumPersonParse(i.type)}","${i.date}","${i.person?.name}","${i.person?.pathImage}"),';
      }
      lastMessage = i.message;
    }
    Database db = await connect();
    await db.transaction((txn) async {
      await txn.rawInsert('INSERT INTO Chat(id,idlist,message, isLabel, type,date,person_name,person_image) VALUES $list');
      await txn.rawUpdate('UPDATE ListChat SET updated=${DateTime.now().millisecondsSinceEpoch},message="$lastMessage" WHERE id=${data.first.listId}');
    });
    await db.close();
  }

  static delete(id, idList) async {
    Database db = await connect();
    await db.rawDelete('DELETE FROM Chat WHERE id = $id AND idlist = $idList');
    await db.close();
  }

  static deleteAll() async {
    Database db = await connect();
    await db.rawDelete('DELETE FROM Chat');
    await db.close();
  }

  static Future<List<Map>> getData({required int idList}) async {
    Database db = await connect();
    List<Map> list = await db.rawQuery('SELECT * FROM Chat WHERE idlist = $idList ORDER BY id DESC');
    await db.close();
    return list;
  }

  static Future<List<Map>> getDataListChat() async {
    Database db = await connect();
    List<Map> list = await db.rawQuery('SELECT * FROM ListChat ORDER BY updated DESC');
    await db.close();
    return list;
  }

  static deleteDatabases() async {
    await init();
    await deleteDatabase(path);
  }
}
