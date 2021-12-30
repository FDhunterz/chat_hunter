import 'package:chat_prototype/model/chat.dart';

dynamic enumPersonParse(data) {
  if (data is Person) {
    if (data == Person.me) {
      return 'me';
    } else if (data == Person.other) {
      return 'other';
    }
  } else {
    if (data == 'me') {
      return Person.me;
    } else if (data == 'other') {
      return Person.other;
    }
  }
  return '';
}
