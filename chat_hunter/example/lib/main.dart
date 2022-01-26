import 'package:chat_hunter/chat_hunter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:request_api_helper/request.dart' as req;
import 'package:request_api_helper/request_api_helper.dart';

void main() async {
  runApp(const MyApp());
  await ChatHunter.mainInit(
    firebaseSetting: FirebaseChatSetting(serverId: 'AAAAWPtQC1Y:APA91bHqqDxXxIhDun9O0r5ioD3TvmPAm5LE0UAWdZBXpR_XqhEBRlYMWJTAQtDDIzWXcexG0UuCPhSMn7kmguoeTxa8BnKOnNqYZRsdpq7Pfaoad1f5t79JKlon4Bfifcxiugns92rB'),
    styleListChat: StyleColor(
      backContainerIconColor: Colors.white10,
      backIconColor: Colors.white,
      backgroundColor: Colors.white,
      componentColor: Colors.black54,
      dateColor: Colors.black45,
      headerColor: Colors.black45,
      messageColor: Colors.black26,
      searchContainerIconColor: Colors.white10,
      searchIconColor: Colors.white,
      textHeaderColor: Colors.white,
      titleColor: Colors.black,
      componentTextColor: Colors.white,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UseTemplate(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _control = TextEditingController();
  int _counter = 0;
  List<ListChat> list = [];

  void _incrementCounter() async {}

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      await req.send(
        type: RESTAPI.get,
        customData: CustomRequestData(
          url: 'http://mediplusclinic.co.id/api/list_chat_dokter',
          header: {
            'token': '9658511de72515a5637044dc917fdc2a',
          },
        ),
        changeConfig: RequestApiHelperConfigData(
          logResponse: true,
          onSuccess: (data) {},
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final data = list[index];
                  return InkWell(
                    onTap: () async {
                      await ChatHunter.initChat();
                      await ChatHunter.getChat(listChatId: data.id ?? 0);
                      await ChatHunter.sendMessage(data: data, message: 'Tes');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        data.groupToken ?? '',
                      ),
                    ),
                  );
                },
              ),
            ),
            TextFormField(
              controller: _control,
              decoration: const InputDecoration(hintText: 'Masukkan Token'),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class UseTemplate extends StatefulWidget {
  const UseTemplate({Key? key}) : super(key: key);

  @override
  State<UseTemplate> createState() => _UseTemplateState();
}

class _UseTemplateState extends State<UseTemplate> {
  final TextEditingController _token = TextEditingController();
  List<ListChat> _listChat = [];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      _listChat = await ChatHunter.getListChat();
      await req.send(
        type: RESTAPI.get,
        customData: CustomRequestData(
          url: 'http://mediplusclinic.co.id/api/pasien/histori_pasien',
          header: {
            'token': '9658511de72515a5637044dc917fdc2a',
          },
        ),
        changeConfig: RequestApiHelperConfigData(
          // logResponse: true,
          onSuccess: (data) async {
            for (var i in data['data'] ?? []) {
              int check = _listChat.where((element) => element.id == int.parse(i['dokter_id'])).length;
              if (check == 0) {
                try {
                  await ChatHunter.addListChat(
                    data: ListChat(
                      id: int.parse(i['dokter_id']),
                      groupToken: i['dokter_id'],
                      token: '',
                      person: Profile(
                        name: i['nama_dokter'],
                        pathImage: i['img_file'],
                      ),
                      chatType: ChatTypes(
                        type: chatType.text,
                      ),
                      lastMessage: '',
                      updated: DateTime.now(),
                    ),
                  );
                } catch (_) {
                  print(_);
                }
              }
            }
          },
        ),
      );
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChatHunter.chat(
      currentState: setState,
      overflowWidget: Positioned(
        bottom: 0,
        right: 0,
        child: Material(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _token,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await ChatHunter.addListChat(
                        data: ListChat(
                          chatType: ChatTypes(
                            type: chatType.text,
                          ),
                          person: Profile(
                            name: 'Generated',
                            pathImage: '',
                          ),
                          groupToken: _token.text,
                          token: _token.text,
                          updated: DateTime.now(),
                          lastMessage: '',
                          id: 99999,
                        ),
                      );
                      setState(() {});
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      color: Colors.blue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      Clipboard.setData(ClipboardData(text: ChatHunter.tokenApp));
                      print(ChatHunter.tokenApp);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
