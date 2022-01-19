import 'dart:typed_data';

enum Person { me, other }
enum Files { pdf, image, video }
enum chatType { text, file }
enum Status { pending, send, read }

class ChatTypes {
  chatType type;
  Files? file;
  int status;
  int progress;
  String? idFile;
  String? path;
  String? thumbnailPath;
  Uint8List? thumnailMemory;

  ChatTypes({this.file, required this.type, this.status = 0, this.progress = 0, this.path, this.idFile, this.thumbnailPath, this.thumnailMemory});
}

class Profile {
  String name;
  String pathImage;

  Profile({required this.name, required this.pathImage});
}

class PersonChat {
  int? id, listId;
  ChatTypes chatType;
  Profile? person;
  Person type;
  String message;
  DateTime date;
  bool isLabel;
  int? timezone;
  Status status;

  PersonChat({this.id, required this.type, required this.message, required this.date, this.person, this.isLabel = false, this.listId, required this.chatType, this.timezone, this.status = Status.pending});
}

class GroupChat {}

class ListChat {
  int? id, read, timezone;
  Profile? person;
  DateTime? updated;
  String? lastMessage, token, groupToken;
  ChatTypes? chatType;
  bool isTyping;

  ListChat({this.id, this.person, this.read, this.updated, this.lastMessage, this.chatType, this.groupToken, this.token, this.timezone, this.isTyping = false});
}
