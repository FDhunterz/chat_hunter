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
      await db.execute('CREATE TABLE Chat (id INTEGER PRIMARY KEY, message TEXT, isLabel TEXT, type TEXT, date TEXT, person_name TEXT, person_image TEXT)');
    });

    return database;
  }

  static insert({required PersonChat data}) async {
    Database db = await connect();
    await db.transaction((txn) async {
      print('${data.id},"${data.message}","${data.isLabel}","${enumPersonParse(data.type)}","${data.date}","${data.person?.name}","${data.person?.pathImage}"');
      await txn.rawInsert('INSERT INTO Chat(id,message, isLabel, type,date,person_name,person_image) VALUES(${data.id},"${data.message}","${data.isLabel}","${enumPersonParse(data.type)}","${data.date}","${data.person?.name}","${data.person?.pathImage}")');
    });
    await db.close();
  }

  static insertList({required List<PersonChat> data}) async {
    String list = '';
    int count = 0;
    for (final i in data) {
      ++count;
      if (count == data.length) {
        list += '(${i.id},"${i.message}","${i.isLabel}","${enumPersonParse(i.type)}","${i.date}","${i.person?.name}","${i.person?.pathImage}")';
      } else {
        list += '(${i.id},"${i.message}","${i.isLabel}","${enumPersonParse(i.type)}","${i.date}","${i.person?.name}","${i.person?.pathImage}"),';
      }
    }
    Database db = await connect();
    await db.transaction((txn) async {
      await txn.rawInsert('INSERT INTO Chat(id,message, isLabel, type,date,person_name,person_image) VALUES$list');
    });
    await db.close();
  }

  static delete(id) async {
    Database db = await connect();
    await db.rawDelete('DELETE FROM Chat WHERE id = $id');
    await db.close();
  }

  static deleteAll() async {
    Database db = await connect();
    await db.rawDelete('DELETE FROM Chat');
    await db.close();
  }

  static Future<List<Map>> getData({int? limit}) async {
    Database db = await connect();
    List<Map> list = await db.rawQuery('SELECT * FROM Chat ORDER BY id DESC');
    await db.close();
    print(list.length);
    return list;
  }

  static deleteDatabases() async {
    await init();
    await deleteDatabase(path);
  }
}
