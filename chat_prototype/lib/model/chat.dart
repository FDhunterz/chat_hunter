enum Person { me, other }
enum Files { pdf, image, video }

class Profile {
  String name;
  String pathImage;

  Profile({required this.name, required this.pathImage});
}

class PersonChat {
  int? id;
  Profile? person;
  Person type;
  String message;
  DateTime date;
  bool isLabel;
  String? timezone;

  PersonChat({this.id, required this.type, required this.message, required this.date, this.person, this.isLabel = false});
}

class GroupChat {}
