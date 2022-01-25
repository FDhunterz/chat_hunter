import 'package:chat_hunter/chat_hunter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notif.dart';

void main() async {
  runApp(const MyApp());
  await ChatHunter.mainInit(
    firebaseSetting: FirebaseChatSetting(serverId: 'AAAAWPtQC1Y:APA91bHqqDxXxIhDun9O0r5ioD3TvmPAm5LE0UAWdZBXpR_XqhEBRlYMWJTAQtDDIzWXcexG0UuCPhSMn7kmguoeTxa8BnKOnNqYZRsdpq7Pfaoad1f5t79JKlon4Bfifcxiugns92rB'),
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
      home: const MyHomePage(title: 'Chat Demo'),
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
      list = await ChatHunter.getListChat();
      setState(() {});
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
