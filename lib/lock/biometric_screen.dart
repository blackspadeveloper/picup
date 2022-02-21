import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../util.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      _authenticateWithBiometrics();
    });
  }

  // 생체인증만
  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
          localizedReason : "지문을 인증해주세요.",
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
          androidAuthStrings: const AndroidAuthMessages(
            biometricHint : "",
            biometricSuccess : "성공",
            cancelButton : "취소",
            goToSettingsButton : "설정",
            signInTitle: "지문 인증",
          ),
          iOSAuthStrings: const IOSAuthMessages(
            goToSettingsButton : "설정",
            cancelButton : "취소",
          ),
      );
    } on PlatformException catch (e) {
      log(e.message.toString());
      setState(() {
        _authorized = false;
      });
      Util.showToast(e.message.toString());
      // if (e.code == auth_error.notAvailable) {
      // }
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _authorized = authenticated;
    });

    if(_authorized) {
      Navigator.of(context, rootNavigator: true).pop(context);
    } else {
      exit(0);
      // _onWillPop();
    }
  }

  // Future<void> _cancelAuthentication() async {
  //   await auth.stopAuthentication();
  //   setState(() => _authorized = false);
  // }

  Future<bool> _onWillPop() async {
    // if(_authorized) {
    //   Navigator.of(context).pop(true);
    //   return true;
    // } else {
      return (await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: null,
          content: const Text(
            "앱을 종료하시겠습니까?",
            style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontSize: 14),
          ),
          actions: [
            CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context,
                      rootNavigator: true)
                      .pop("Discard");
                  _authenticateWithBiometrics();
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
                onPressed: () {
                  exit(0);
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
      )) ?? false;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: const Scaffold(
        backgroundColor: Colors.black,
        appBar: null,
        body: null,
      ),
      onWillPop: _onWillPop,
    );
  }

}