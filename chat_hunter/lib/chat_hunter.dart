import 'package:flutter/widgets.dart';

import 'list.dart';
import 'model/chat.dart';
export 'package:chat_hunter/model/chat.dart';

class ChatHunter {
  static ChatSnackBarMessage? _messageSetting;
  static Template? _templateSetting;
  static StyleColor? _styleListSetting;
  static StyleChatColor? _styleChatSetting;
  static String? listTitle;
  static FirebaseChatSetting? _firebaseSetting;

  static ChatSnackBarMessage? get messageSetting => _messageSetting;
  static Template? get templateSetting => _templateSetting;
  static StyleColor? get styleListSetting => _styleListSetting;
  static StyleChatColor? get styleChatSetting => _styleChatSetting;
  static FirebaseChatSetting? get firebaseSetting => _firebaseSetting;

  /// After runApp() in main.dart
  static mainInit({ChatSnackBarMessage? message, Template? template, StyleColor? styleListChat, StyleChatColor? styleChat, String? titleListChat, FirebaseChatSetting? firebaseSetting}) {
    _messageSetting = message ??
        ChatSnackBarMessage(
          noConnected: '',
          nullMessage: '',
          textCopy: '',
        );

    _templateSetting = template ?? Template.standart;
    _styleListSetting = styleListChat;
    _styleChatSetting = styleChat;
    _styleListSetting = styleListChat;
    listTitle = titleListChat;
    _firebaseSetting = firebaseSetting;
  }

  static Widget chat() {
    return const ListChatView();
  }
}
