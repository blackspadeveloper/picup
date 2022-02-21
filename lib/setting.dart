import 'dart:developer';
import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picup/lock/setting_password_screen.dart';
import 'package:picup/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slidable_button/slidable_button.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import 'constants.dart';


enum _SupportState {
  unknown,
  supported,
  unsupported,
}
enum LockType { pin, finger, face, none }
extension LockTypeExtension on LockType {
  LockType getType(String type) {
    if(type == Constants.pin) {
      return LockType.pin;
    } else if(type == Constants.finger) {
      return LockType.finger;
    } else if(type == Constants.face){
      return LockType.face;
    } else {
      return LockType.none;
    }
  }
}

class PicUpSetting extends StatefulWidget {
  const PicUpSetting({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _PicUpSettingState createState() => _PicUpSettingState();
}

class _PicUpSettingState extends State<PicUpSetting> {
  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
    buildSignature: '',
  );

  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  bool _isAuthenticating = false;

  late AdmobBannerSize bannerSize;

  LockType _lockType = LockType.none;
  SlidableButtonPosition? lockPosition;

  bool isLoadFailed = false;

  @override
  void initState() {
    super.initState();
    bannerSize = AdmobBannerSize.BANNER;
    _initPackageInfo();
    _getSlideTypeValue();
    _checkLockType();

    auth.isDeviceSupported().then(
          (bool isSupported) => setState(() => _supportState = isSupported
          ? _SupportState.supported
          : _SupportState.unsupported),
    );
    _checkBiometrics();
  }

  _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  _getSlideTypeValue() async {
    await Util.preferenceInstance.then((instance) {
      setState(() {
        lockPosition = instance.getBool(Constants.lock) ?? false ? SlidableButtonPosition.right : SlidableButtonPosition.left;
      });
    });
  }

  _checkLockType() async {
    SharedPreferences instance = await Util.preferenceInstance;
    String type = instance.getString(Constants.lockType) ?? "none";
    var _type = _lockType.getType(type);
    if(_lockType != _type) {
      setState(() {
        _lockType = _lockType.getType(type);
      });
    }
  }

  // 생체인증이 가능한지 확인
  Future<void> _checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      log(e.message.toString());
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });

    if(canCheckBiometrics) {
      _getAvailableBiometrics();
    }
  }

  // 등록된 바이오인증 목록
  Future<void> _getAvailableBiometrics() async {
    late List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await auth.getAvailableBiometrics(); // [BiometricType.fingerprint, BiometricType.fingerprint]
    } on PlatformException catch (e) {
      availableBiometrics = <BiometricType>[];
      log(e.message.toString());
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  // 생체인증만
  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
          localizedReason: "지문을 인증해주세요.",
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
          androidAuthStrings: const AndroidAuthMessages(
            biometricHint : "",
            biometricSuccess : "성공",
            cancelButton : "취소",
            goToSettingsButton : "설정",
            signInTitle: "지문 확인",
          ),
          iOSAuthStrings: const IOSAuthMessages(
            goToSettingsButton : "설정",
            cancelButton : "취소",
          ),
      );

    } on PlatformException catch (e) {
      log(e.message.toString());
      setState(() {
        _isAuthenticating = false;
      });
      if (e.code == auth_error.notAvailable) {
        // Handle this exception here.
      }
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticating = authenticated;
    });
  }

  void _handleRadioValueChange(LockType lockType) {
    if(lockType == LockType.pin) {
      Util.setPreferences(Constants.lockType, Constants.pin);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingPasswordLockScreen(title: '간편비밀번호 설정')),
      );
    } else if(lockType == LockType.finger) {
      Util.setPreferences(Constants.lockType, Constants.finger);
      _authenticateWithBiometrics();
    } else {
      Util.setPreferences(Constants.lockType, Constants.face);
      _authenticateWithBiometrics();
    }
  }

  // Future<void> _cancelAuthentication() async {
  //   await auth.stopAuthentication();
  //   setState(() => _isAuthenticating = false);
  // }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
        ),
        // backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
                flex: 10,
                child: Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  margin: const EdgeInsets.only(top: 10.0),
                                  child: const Text('잠금설정',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 15),
                                  ),
                                ),
                                lockPosition == null
                                    ? Container() : Container(
                                  margin: const EdgeInsets.only(top: 10.0),
                                  child: SlidableButton(
                                    width: MediaQuery.of(context).size.width / 5,
                                    height: 35.0,
                                    buttonWidth: 30.0,
                                    color: Colors.grey.shade300,
                                    buttonColor: Theme.of(context).primaryColor.withOpacity(0.8),
                                    dismissible: false,
                                    label: const Center(child: Text('')),
                                    initialPosition : lockPosition ?? SlidableButtonPosition.left,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: const [
                                          Text('ON',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black38,
                                                  fontSize: 11)),
                                          Text('OFF',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black38,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    onChanged: (position) async {
                                      setState(() {
                                        lockPosition = position;
                                      });
                                      Util.setPreferences(Constants.lock, (position == SlidableButtonPosition.right) ? true : false);
                                      if(position == SlidableButtonPosition.right) {
                                        SharedPreferences instance = await Util.preferenceInstance;
                                        String type = instance.getString(Constants.lockType) ?? 'none';
                                        if(type == "none") {
                                          setState(() {
                                            _lockType = LockType.pin;
                                          });
                                          Future.delayed(const Duration(milliseconds: 500), () {
                                            _handleRadioValueChange(LockType.pin);
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: SizedBox(
                                  width: size.width,
                                  child: const Divider(color: Colors.grey, thickness: 1.5)
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('간편비밀번호',
                                  style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                      fontSize: 14),
                                ),
                                Transform.scale(
                                  scale: 1.3,
                                  child: RadioButton(
                                    description: "",
                                    value: LockType.pin,
                                    groupValue: _lockType,
                                    onChanged: (lockPosition == null || lockPosition == SlidableButtonPosition.left) ? null : (value) {
                                      setState(() {
                                        _lockType = value as LockType;
                                      });
                                      _handleRadioValueChange(LockType.pin);
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: _supportState != _SupportState.supported || _canCheckBiometrics == false
                                  ? null : !(_availableBiometrics?.contains(BiometricType.fingerprint) ?? false)
                                    ? null : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('지문',
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        fontSize: 14),
                                  ),
                                  Transform.scale(
                                    scale: 1.3,
                                    child: RadioButton(
                                      description: "",
                                      value: LockType.finger,
                                      groupValue: _lockType,
                                      onChanged: (lockPosition == null || lockPosition == SlidableButtonPosition.left) ? null : (value) {
                                        setState(() {
                                          _lockType = value as LockType;
                                        });
                                        _handleRadioValueChange(LockType.finger);
                                      },
                                      activeColor: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Platform.isAndroid
                                    ? null : _supportState != _SupportState.supported || _canCheckBiometrics == false
                                      ? null : !(_availableBiometrics?.contains(BiometricType.face) ?? false)
                                        ? null : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text('FaceID',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                          fontSize: 14),
                                    ),
                                    Transform.scale(
                                      scale: 1.3,
                                      child: RadioButton(
                                        description: "",
                                        value: LockType.face,
                                        groupValue: _lockType,
                                        onChanged: (lockPosition == null || lockPosition == SlidableButtonPosition.left) ? null : (value) {
                                          setState(() {
                                            _lockType = value as LockType;
                                          });
                                          _handleRadioValueChange(LockType.face);
                                        },
                                        activeColor: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                )
                            ),
                          ],
                        )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
                      child: SizedBox(
                          width: size.width,
                          child: const Divider(color: Colors.grey, thickness: 1.5)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.only(top: 10.0),
                            child: const Text('앱 버전',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 15),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.only(top: 10.0),
                            child: _packageInfo.version.isEmpty ?
                            const Text('') : Text(_packageInfo.version,
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
            ),
            Expanded(
               flex: isLoadFailed == true ? 1 : 2,
                child: Column(
                  children: [
                    Container(
                      alignment: FractionalOffset.bottomCenter,
                      margin: const EdgeInsets.only(top: 5.0, bottom: 10),
                      child: const Text(Constants.copyRight,
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black54,
                            fontSize: 12),),
                    ),
                    isLoadFailed == true
                      ? const SizedBox(width: 0, height: 0,) : Container(
                      alignment: FractionalOffset.topCenter,
                      margin: const EdgeInsets.only(bottom: 0.0),
                      child: AdmobBanner(
                        adUnitId: Constants.bannerAdUnitId,
                        adSize: bannerSize,
                        listener: (AdmobAdEvent event, Map<String, dynamic>? args) {
                          if(event == AdmobAdEvent.failedToLoad || event == AdmobAdEvent.closed) {
                            setState(() {
                              isLoadFailed = true;
                            });
                          }
                          // Ad failed to load : 3 -> 개발 과정이나 정책 오류로 인한 패널티가 아니라 단순히 광고를 평가라는 이유로 빼버린 상황인 것이다.
                          Util.handleEventAdMob(context, event, args, 'Banner');
                        },
                        onBannerCreated:
                            (AdmobBannerController controller) {
                          // Dispose is called automatically for you when Flutter removes the banner from the widget tree.
                          // Normally you don't need to worry about disposing this yourself, it's handled.
                          // If you need direct access to dispose, this is your guy!
                          // controller.dispose();
                        },
                      ),
                    ),
                  ],
                )
            )
          ],
        ),
    );
  }
}