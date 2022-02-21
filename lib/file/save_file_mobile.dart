import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart' as open_file;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../main.dart';
import '../util.dart';

///To save the Excel file in the device
Future<void> saveAndLaunchFile(List<int> bytes, String fileName, BuildContext context, Function(bool result) callback) async {
  //Get the storage folder location using path_provider package.
  String? path;
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isLinux ||
      Platform.isWindows) {
    path = await Util.applicationDocumentsDirectory;
  } else {
    path = await PathProviderPlatform.instance.getApplicationSupportPath();
  }

  final File file = File(Platform.isWindows ? '$path\\$fileName' : '$path/$fileName');
  await file.writeAsBytes(bytes, flush: true).then((file) {
    var existsSync = file.existsSync();
    callback(existsSync);

    if(existsSync) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: null,
          content: Text("$fileName를 여시겠습니까?",
            style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontSize: 14),
          ),
          actions: [
            CupertinoDialogAction(
                onPressed: () {
                  // Navigator.of(context,
                  //     rootNavigator: true)
                  //     .pop("Discard");

                  // Navigator.of(context).pop();

                  // clear activity stack in flutter
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const PicUpMain(),
                    ),
                    (route) => false,
                  );
                },
                isDefaultAction: true,
                child: const Text("취소",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 14),
                )
            ),
            CupertinoDialogAction(
                onPressed: () async {
                  // Navigator.of(context,
                  //     rootNavigator: true)
                  //     .pop("Discard");

                  // Navigator.of(context).pop();

                  // clear activity stack in flutter
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const PicUpMain(),
                    ),
                        (route) => false,
                  );

                  await open_file.OpenFile.open('$path/$fileName');

                  // if (Platform.isAndroid || Platform.isIOS) {
                  //   //Launch the file (used open_file package)
                  //   await open_file.OpenFile.open('$path/$fileName');
                  // } else if (Platform.isWindows) {
                  //   await Process.run('start', <String>['$path\\$fileName'], runInShell: true);
                  // } else if (Platform.isMacOS) {
                  //   await Process.run('open', <String>['$path/$fileName'], runInShell: true);
                  // } else if (Platform.isLinux) {
                  //   await Process.run('xdg-open', <String>['$path/$fileName'], runInShell: true);
                  // }
                },
                isDefaultAction: true,
                child: const Text("확인",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 14),
                )
            ),
          ],
        ),
      );
    }
  });

}
