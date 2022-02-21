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

import '../constants.dart';
import '../util.dart';


enum EnterPage { first, second }

class SettingPasswordLockScreen extends StatefulWidget {
  const SettingPasswordLockScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => _SettingPasswordLockScreenState();
}

class _SettingPasswordLockScreenState extends State<SettingPasswordLockScreen> {
  final StreamController<bool> _verificationNotifier =
  StreamController<bool>.broadcast();

  bool isAuthenticated = false;
  Digest? firstPassword;

  EnterPage page = EnterPage.first;

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
    Navigator.of(context).pop(true);
    return true;
  }

  _customColorsLockScreenButton(BuildContext context) {
    return digitList == null
      ? Container() : page == EnterPage.first ? PasscodeScreen(
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
            passwordEnteredCallback: _onPasscodeEntered1,
            cancelCallback: _onPasscodeCancelled,
            shouldTriggerVerification: _verificationNotifier.stream,
            backgroundColor: Colors.black,
            digits: digitList,
            passwordDigits: 6,
            bottomWidget: _buildPasscodeRestoreButton1(),
          ) : PasscodeScreen(
                title: const Text(
                  '간편번호 6자리를 다시 입력해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                circleUIConfig: const CircleUIConfig(
                    borderColor: Colors.white,
                    fillColor: Colors.white,
                    circleSize: 30),
                keyboardUIConfig: const KeyboardUIConfig(
                    digitBorderWidth: 2, primaryColor: Colors.white),
                cancelButton: const Text(
                  '취소',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  semanticsLabel: '취소',
                ),
                deleteButton: const Text(
                  '삭제',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  semanticsLabel: '삭제',
                ),
                passwordEnteredCallback: _onPasscodeEntered2,
                cancelCallback: _onPasscodeCancelled,
                shouldTriggerVerification: _verificationNotifier.stream,
                backgroundColor: Colors.black,
                digits: digitList,
                passwordDigits: 6,
                bottomWidget: _buildPasscodeRestoreButton2(),
              );
  }

  // _showLockScreen(
  //     BuildContext context, {
  //       required bool opaque,
  //       CircleUIConfig? circleUIConfig,
  //       KeyboardUIConfig? keyboardUIConfig,
  //       required Widget cancelButton,
  //       List<String>? digits,
  //     }) {
  //   Navigator.push(
  //       context,
  //       PageRouteBuilder(
  //         opaque: opaque,
  //         pageBuilder: (context, animation, secondaryAnimation) =>
  //             PasscodeScreen(
  //               title: const Text(
  //                 'Enter App Passcode',
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(color: Colors.white, fontSize: 28),
  //               ),
  //               circleUIConfig: circleUIConfig,
  //               keyboardUIConfig: keyboardUIConfig,
  //               passwordEnteredCallback: _onPasscodeEntered,
  //               cancelButton: cancelButton,
  //               deleteButton: const Text(
  //                 '삭제',
  //                 style: TextStyle(fontSize: 16, color: Colors.white),
  //                 semanticsLabel: '삭제',
  //               ),
  //               shouldTriggerVerification: _verificationNotifier.stream,
  //               backgroundColor: Colors.black,
  //               cancelCallback: _onPasscodeCancelled,
  //               digits: digits,
  //               passwordDigits: 6,
  //               bottomWidget: _buildPasscodeRestoreButton(),
  //             ),
  //       ));
  // }

  _onPasscodeEntered1(String enteredPasscode) {
    var bytes = utf8.encode(enteredPasscode); // data being hashed
    var digest = sha256.convert(bytes);
    firstPassword = digest;
    _verificationNotifier.add(false);
    setState(() {
      page = EnterPage.second;
    });
  }

  _onPasscodeEntered2(String enteredPasscode) {
    var bytes = utf8.encode(enteredPasscode); // data being hashed
    var digest = sha256.convert(bytes);
    bool isValid = (firstPassword == digest);
    _verificationNotifier.add(isValid);
    if (isValid) {
      Util.setPreferences(Constants.pinPassword, firstPassword.toString());
      setState(() {
        isAuthenticated = isValid;
      });
    } else {
      Util.showToast("이전 입력하신 비밀번호와 일치하지 않습니다.");
      setState(() {
        firstPassword = null;
        page = EnterPage.first;
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

  _buildPasscodeRestoreButton1() => Align(
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

  _buildPasscodeRestoreButton2() => Align(
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