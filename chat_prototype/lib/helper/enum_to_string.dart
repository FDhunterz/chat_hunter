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

dynamic enumChatTypeParse(data) {
  if (data is chatType) {
    if (data == chatType.text) {
      return 0;
    } else if (data == chatType.file) {
      return 1;
    }
  } else {
    if (data == 0) {
      return chatType.text;
    } else if (data == 1) {
      return chatType.file;
    }
  }
  return '';
}

dynamic enumFileTypeParse(data) {
  if (data == null) {
    return 0;
  }
  if (data is Files) {
    if (data == Files.image) {
      return 1;
    } else if (data == Files.pdf) {
      return 2;
    } else if (data == Files.video) {
      return 3;
    }
  } else {
    if (data == '1') {
      return Files.image;
    } else if (data == '2') {
      return Files.pdf;
    } else if (data == '3') {
      return Files.video;
    } else {
      return null;
    }
  }
}
