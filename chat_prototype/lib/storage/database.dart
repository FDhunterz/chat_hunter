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
      await db.execute('CREATE TABLE Chat (id INTEGER PRIMARY KEY, idlist INTEGER ,message TEXT, isLabel TEXT, type TEXT, date TEXT, person_name TEXT, person_image TEXT,chatType INTEGER, fileType TEXT,idFile TEXT,progress Text)');
      await db.execute('CREATE TABLE ListChat (id INTEGER PRIMARY KEY, read INTEGER,updated INTEGER,person_name TEXT, person_image TEXT, message TEXT,chatType INTEGER,token TEXT,groupToken TEXT)');
    });

    return database;
  }

  static insertListChat({required ListChat data}) async {
    Database db = await connect();
    await db.transaction((txn) async {
      await txn.rawInsert('INSERT INTO ListChat(id,read,person_name,person_image,updated,chatType,token,groupToken) VALUES(${data.id},${data.read},"${data.person?.name}","${data.person?.pathImage}",${data.updated!.millisecondsSinceEpoch},0,"${data.token}","${data.groupToken}")');
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
      await txn.rawInsert('INSERT INTO Chat(id,idlist,message, isLabel, type,date,person_name,person_image,chatType,fileType,idFile,progress) VALUES(${data.id},${data.listId},"${data.message}","${data.isLabel}","${enumPersonParse(data.type)}","${data.date}","${data.person?.name}","${data.person?.pathImage}",${enumChatTypeParse(data.chatType.type)},${enumFileTypeParse(data.chatType.file)},"null","0")');
      await txn.rawUpdate('UPDATE ListChat SET updated=${data.type == Person.me ? '0' : DateTime.now().millisecondsSinceEpoch},message="${data.message}",chatType=${enumChatTypeParse(data.chatType.type)} WHERE id=${data.listId}');
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
        list += '(${i.id},${i.listId},"${i.message}","${i.isLabel}","${enumPersonParse(i.type)}","${i.date}","${i.person?.name}","${i.person?.pathImage}",${enumChatTypeParse(i.chatType.type)},${enumFileTypeParse(i.chatType.file)},"null","0")';
      } else {
        list += '(${i.id},${i.listId},"${i.message}","${i.isLabel}","${enumPersonParse(i.type)}","${i.date}","${i.person?.name}","${i.person?.pathImage}",${enumChatTypeParse(i.chatType.type)},${enumFileTypeParse(i.chatType.file)},"null","0"),';
      }
      lastMessage = i.message;
    }
    Database db = await connect();
    await db.transaction((txn) async {
      await txn.rawInsert('INSERT INTO Chat(id,idlist,message, isLabel, type,date,person_name,person_image,chatType,fileType,idFile,progress) VALUES $list');
      await txn.rawUpdate('UPDATE ListChat SET updated=${DateTime.now().millisecondsSinceEpoch},message="$lastMessage" WHERE id=${data.first.listId}');
    });
    await db.close();
  }

  static updateIdFile({String? id, index}) async {
    Database db = await connect();
    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE Chat SET idFile="$id" WHERE id=$index');
    });
    await db.close();
  }

  static progressUpdate({String? id, progress}) async {
    Database db = await connect();
    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE Chat SET progress="$progress" WHERE idFile="$id"');
    });
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

  static Future<List<Map>> getDataByToken({required String token}) async {
    Database db = await connect();
    List<Map> list = await db.rawQuery('SELECT * FROM Chat WHERE groupToken = "$token" ORDER BY id DESC');
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
