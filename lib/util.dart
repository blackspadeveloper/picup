import 'dart:developer';
import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:shared_preferences/shared_preferences.dart';

class Util {

  static void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.lightBlue,
        textColor: Colors.white,
        fontSize: 14.0
    );
  }

  static void checkNetwork(BuildContext context, Function(bool result) callback) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if(connectivityResult == ConnectivityResult.none) {
      callback(false);
    } else {
      callback(true);
    }
  }

  static Future<String> get applicationDocumentsDirectory async {
    // /data/user/0/com.acrox.picup/app_flutter/file_20211226_162324.xlsx
    final Directory directory = await path_provider.getApplicationDocumentsDirectory();
    return directory.absolute.path;
  }

  static void handleEventAdMob(BuildContext context, AdmobAdEvent event, Map<String, dynamic>? args, String adType) {
    log('handleEvent :: $event..$adType');
    // switch (event) {
    //   case AdmobAdEvent.loaded:
    //     showSnackBar(context, '$adType Ad loaded!');
    //     break;
    //   case AdmobAdEvent.opened:
    //     showSnackBar(context, '$adType Ad opened!');
    //     break;
    //   case AdmobAdEvent.closed:
    //     showSnackBar(context, '$adType Ad closed!');
    //     break;
    //   case AdmobAdEvent.failedToLoad:
    //     showSnackBar(context, '$adType failed to load!');
    //     break;
    //   default:
    // }
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  static void setPreferences(String key, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(value is int) {
      await prefs.setInt(key, value);
    }
    if(value is String) {
      await prefs.setString(key, value);
    }
    if(value is bool) {
      await prefs.setBool(key, value);
    }
  }

  static Future<SharedPreferences> get preferenceInstance async {
    return await SharedPreferences.getInstance();
  }

}