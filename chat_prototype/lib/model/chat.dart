enum Person { me, other }
enum Files { pdf, image, video }
enum chatType { text, file }

class ChatTypes {
  chatType type;
  Files? file;
  int status;
  int progress;
  String? path;

  ChatTypes({this.file, required this.type, this.status = 0, this.progress = 0, this.path});
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
  String? timezone;

  PersonChat({this.id, required this.type, required this.message, required this.date, this.person, this.isLabel = false, this.listId, required this.chatType});
}

class GroupChat {}

class ListChat {
  int? id, read;
  Profile? person;
  DateTime? updated;
  String? lastMessage;
  ChatTypes? chatType;

  ListChat({this.id, this.person, this.read, this.updated, this.lastMessage, this.chatType});
}
