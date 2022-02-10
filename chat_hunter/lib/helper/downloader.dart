import 'dart:async';
import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';

Timer? delayed;
bool isLoad = false;

Future<String?> download({fileName, url, directory, bool isOpen = false, bool isShare = false, context}) async {
  String? id;
  if (await File(directory + '/' + fileName).exists()) {
  } else {
    // _onLoading(context);
    String? data = await FlutterDownloader.enqueue(
      url: url,
      savedDir: directory,
      requiresStorageNotLow: true,
      saveInPublicStorage: true,
      fileName: fileName,
      showNotification: false, // show download progress in status bar (for Android)
      openFileFromNotification: true, // click on notification to open downloaded file (for Android)
    );
    id = data;
  }
  delayed = Timer.periodic(const Duration(seconds: 1), (times) async {
    try {
      if (!isLoad) {
        isLoad = true;
        final bool status = await getDownloadfile(fileName);
        if (status) {
          if (isOpen) {
            OpenFile.open(directory + '/' + fileName);
          } else if (isShare) {
            Share.shareFiles([directory + '/' + fileName]);
          }
          isLoad = false;
          delayed!.cancel();
        } else {
          isLoad = false;
        }
      }
    } catch (_) {
      print(_);
      delayed!.cancel();

      if (isOpen) {
        OpenFile.open(directory + '/' + fileName);
      } else if (isShare) {
        Share.shareFiles([directory + '/' + fileName]);
      }
    }
  });
  return id;
}

Future<String> getPhoneDirectory({platform, path}) async {
  if (platform == 'android') {
    await Permission.storage.request();
    final temp = await getExternalStorageDirectory();
    final base = temp!.path + '/';
    await savePath(path, base);
    return base + path;
  } else if (platform == 'ios') {
    final temp = await getApplicationDocumentsDirectory();
    await savePath(path, temp.path + '/');

    return temp.path + '/' + path;
  }
  return '';
}

savePath(String path, String base) {
  final slice = path.split('/');
  String dirs = '';
  for (int i = 0; i < slice.length; i++) {
    dirs += slice[i];
    if (i < slice.length - 1) {
      dirs += '/';
    }
    try {
      Directory(base + dirs).create().then((Directory directory) {});
    } catch (_) {
      print(_);
    }
  }
}

Future<bool> getDownloadfile(fileName) async {
  final tasks2 = await FlutterDownloader.loadTasksWithRawQuery(query: 'SELECT * FROM task WHERE file_name="' + fileName + '"');

  if (tasks2!.first.status == DownloadTaskStatus.complete) {
    return true;
  } else {
    return false;
  }
}

deleteFileData(path) {
  File(path).delete();
}

Future<bool> deleteDataDownloaded(taskId) async {
  FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: false);
  return true;
}

Future<List<FileSystemEntity>> dirContents(Directory dir) async {
  var files = <FileSystemEntity>[];
  var completer = Completer<List<FileSystemEntity>>();
  var lister = dir.list(recursive: true, followLinks: true);
  lister.listen((file) => files.add(file),
      // should also register onError
      onDone: () => completer.complete(files));
  return completer.future;
}
