import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/passcode_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../util.dart';


class PasswordLockScreen extends StatefulWidget {
  const PasswordLockScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => _PasswordLockScreenState();
}

class _PasswordLockScreenState extends State<PasswordLockScreen> {
  final StreamController<bool> _verificationNotifier =
  StreamController<bool>.broadcast();

  bool isAuthenticated = false;
  List<String>? digitList;

  @override
  void initState() {
    super.initState();
    _generateRandomPassword();
  }

  void _generateRandomPassword() {
    var random = Random();
    List<int> initList = [0,1,2,3,4,5,6,7,8,9];
    digitList = <String>[];
    setState(() {
      while(initList.isNotEmpty) {
        int index = random.nextInt(initList.length);
        int number = initList[index];
        initList.removeAt(index);
        digitList!.add(number.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
          child: Scaffold(
          appBar: null,
          body: Center(
            child: _customColorsLockScreenButton(context),
          ),
        ),
        onWillPop: _onWillPop,
    );
  }


  /// 앱을 종료하기 위한 방식
  // 1. Navigator.of(context).pop(true)
  // 2. SystemNavigator.pop() // 앱 종료
  // 3. exit(0) //강제종료
  Future<bool> _onWillPop() async {
    if(isAuthenticated) {
      Navigator.of(context).pop(true);
      return true;
    } else {
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
                  Navigator.of(context).pop(false);
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
    }
  }

  _customColorsLockScreenButton(BuildContext context) {
    return digitList == null
      ? Container() : PasscodeScreen(
            title: const Text(
              '간편번호 6자리를 입력해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            circleUIConfig: const CircleUIConfig(
                borderColor: Colors.white,
                fillColor: Colors.white,
                circleSize: 30),
            keyboardUIConfig: const KeyboardUIConfig(
                digitBorderWidth: 2,
                primaryColor: Colors.white),
            cancelButton: const Text(
              '취소',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white
              ),
              semanticsLabel: '취소',
            ),
            deleteButton: const Text(
              '삭제',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white
              ),
              semanticsLabel: '삭제',
            ),
            passwordEnteredCallback: _onPasscodeEntered,
            cancelCallback: _onPasscodeCancelled,
            shouldTriggerVerification: _verificationNotifier.stream,
            backgroundColor: Colors.black,
            digits: digitList,
            passwordDigits: 6,
            bottomWidget: _buildPasscodeRestoreButton(),
          );
  }

  _onPasscodeEntered(String enteredPasscode) async {
    var bytes = utf8.encode(enteredPasscode); // data being hashed
    var digest = sha256.convert(bytes);
    SharedPreferences instance = await Util.preferenceInstance;
    final String storePassword = instance.getString(Constants.pinPassword) ?? '';
    bool isValid = (storePassword == digest.toString());
    _verificationNotifier.add(isValid);
    if (isValid) {
      setState(() {
        isAuthenticated = isValid;
      });
    } else {
      Util.showToast("비밀번호가 일치하지 않습니다.");
      setState(() {
        isAuthenticated = isValid;
        var random = Random();
        List<int> presentList = [5,6,7,8,9,0,1,2,3,4];
        digitList = null;
        digitList = [];
        while(presentList.isNotEmpty) {
          int index = random.nextInt(presentList.length);
          int number = presentList[index];
          presentList.removeAt(index);
          digitList?.add(number.toString());
        }
      });
    }
  }

  _onPasscodeCancelled() {
    Navigator.maybePop(context);
  }

  @override
  void dispose() {
    _verificationNotifier.close();
    super.dispose();
  }

  _buildPasscodeRestoreButton() => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10.0, top: 20.0),
      child: TextButton(
        child: const Text(
          "Keypad rearrangement",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w300),
        ),
        onPressed: _randomAppPassword,
      ),
    ),
  );

  _randomAppPassword() {
    var random = Random();
    List<int> presentList = [9,8,7,6,5,4,3,2,1,0];
    digitList = null;
    setState(() {
      digitList = [];
      while(presentList.isNotEmpty) {
        int index = random.nextInt(presentList.length);
        int number = presentList[index];
        presentList.removeAt(index);
        digitList?.add(number.toString());
      }
    });
  }
}