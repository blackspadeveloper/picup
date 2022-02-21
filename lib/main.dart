import 'dart:developer';
import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:open_file/open_file.dart' as open_file;
import 'package:picup/constants.dart';
import 'package:picup/lock/biometric_screen.dart';
import 'package:picup/setting.dart';

import 'detector/text_detector_view.dart';
import 'detector/text_detectorv2_view.dart';
import 'lock/password_screen.dart';
import 'model/file_data.dart';
import 'util.dart';

List<CameraDescription> cameras = [];

const String splashImage = 'assets/splashscreen_image.png';
bool _isAuthCompleted = false;

Future<void> main() async {
  // main 메소드에서 비동기 메소드 사용시 반드시 추가
  // runApp 메소드의 시작 지점에서 Flutter 엔진과 위젯의 바인딩이 미리 완료되어 있게만들어줍니다.
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  // Initialize without device test ids.
  Admob.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PicUp',
      initialRoute: '/',
      routes: {
        '/textDetectorView': (context) => const TextDetectorView(), // android, ios
        '/textDetectorV2View': (context) => const TextDetectorV2View(), // only android
        '/passwordLockScreen': (context) => const PasswordLockScreen(title: '',),
        '/biometricLockScreen': (context) => const BiometricLockScreen(title: '',),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Appbar 우측 상단에 debug 뱃지
      home: const PicUpMain(),
      // AnimatedSplashScreen(
      //     duration: 500,
      //     splash: splashImage,
      //     nextScreen: const PicUpMain(),
      //     splashTransition: SplashTransition.fadeTransition,
      //     // pageTransitionType: PageTransitionType.scale, // Null check operator used on a null value
      //     backgroundColor: Colors.white,
      // )
    );
  }
}

class PicUpMain extends StatefulWidget {
  const PicUpMain({Key? key}) : super(key: key);

  @override
  State<PicUpMain> createState() => _PicUpMainState();
}

class _PicUpMainState extends State<PicUpMain> {
  List<MutableFileData> entries = [];

  bool _isClicked = false;
  bool _isAllChecked = false;
  bool _isReading = false;

  AdmobBannerSize? bannerSize;

  @override
  void initState() {
    super.initState();

    // You should execute `Admob.requestTrackingAuthorization()` here before showing any ad.
    Admob.requestTrackingAuthorization();
    bannerSize = AdmobBannerSize.BANNER;

    _getIsLock();
    readFiles();
  }

  _getIsLock() async {
    await Util.preferenceInstance.then((instance) {
      bool isOpened = instance.getBool("IS_OPEN") ?? false;
      if(!isOpened) {
        _showDialog();
      }
      bool isLocked = instance.getBool(Constants.lock) ?? false;
      String lockType = instance.getString(Constants.lockType) ?? Constants.pin;
      if(isLocked) {
        _movePage(lockType);
      }
    });
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 여백을 눌러도 닫히지 않게 만들기
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          title: const Text(
            "[ 사용방법 ]",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15),
          ),
          content: const SingleChildScrollView(
              child: Text(
            Constants.usableContents,
            style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black54,
                fontSize: 14),
          )),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.white, // backgroundd
                elevation: 0,
              ),
              child: const Text(
                "확인",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 15),
              ),
              onPressed: () {
                Util.setPreferences("IS_OPEN", true);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _movePage(String type) {
    log('_movePage :_lockType: $type...$_isAuthCompleted');
    // String pageName = "";
    // if(type == Constants.pin) {
    //   pageName = "/passwordLockScreen";
    // } else {
    //   pageName = "/biometricLockScreen";
    // }
    //
    // Navigator.pushNamed(context, pageName).then((value) {
    //   // This block runs when you have returned back to the 1st Page from 2nd.
    //   log("Navigator.pushNamed(PasswordLockScreen)...$value");
    //   // if(entries.isEmpty) {
    //   //   readFiles();
    //   // }
    // });

    if(!_isAuthCompleted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          (type == Constants.pin)
              ? const PasswordLockScreen(title: '',)
              : const BiometricLockScreen(title: '',),
          transitionDuration: const Duration(seconds: 0),
          reverseTransitionDuration: const Duration(seconds: 0),
        ),
      ).then((value) {
        log("_movePage // Navigator.pushNamed :: $value");
        setState(() {
          _isAuthCompleted = true;
        });
        // if(entries.isEmpty) {
        //   readFiles();
        // }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _moveCameraPage(BuildContext context) {
    Util.checkNetwork(context, (result) {
      log("checkNetwork result :: $result");
      if (result) {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => const TextDetectorV2View()),
        // );
        /**
         * 다음 화면에서 이전화면으로 back 하면 상태값 변경
         */
        // Navigator.pushNamed(context, Platform.isAndroid ? '/textDetectorV2View' : '/textDetectorView').then((_) {
        //   // This block runs when you have returned back to the 1st Page from 2nd.
        //   log("Navigator.pushNamed");
        //   readFiles();
        //   setState(() {
        //     // Call setState to refresh the page.
        //     isClicked = false;
        //   });
        // });

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Platform.isAndroid ? const TextDetectorV2View() : const TextDetectorView(),
            transitionDuration: const Duration(seconds: 0),
          ),
        ).then((value) {
          log("_moveCameraPage // Navigator.pushNamed :: $value");
          readFiles();
          setState(() {
            // Call setState to refresh the page.
            _isClicked = false;
          });
        });
      } else {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: null,
            content: const Text("네트워크 연결이 원활하지 않습니다.\n네트워크 연결 상태를 확인 후 다시 시도해주세요.",
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  fontSize: 14),
            ),
            actions: [
              CupertinoDialogAction(
                  onPressed: () {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      SystemChannels.platform
                          .invokeMethod('SystemNavigator.pop');
                    });
                  },
                  isDefaultAction: true,
                  child: textWidget
              ),
            ],
          ),
        );
      }
    });
  }

  var textWidget = const Text("확인",
    style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
        fontSize: 14),
  );

  Future<void> readFiles() async {
    log('readFiles');
    setState(() {
      _isReading = true;
    });
    try {
      final String? directoryPath = await Util.applicationDocumentsDirectory;
      String pdfDirectory = '$directoryPath/';
      final myDir = Directory(pdfDirectory);
      List<FileSystemEntity> _folders = myDir.listSync(
          recursive: true, followLinks: false);

      if (_folders.isNotEmpty) {
        // if (entries.isNotEmpty) {
        //   entries.clear();
        // }

        List<MutableFileData> files = [];
        for (FileSystemEntity file in _folders) {
          String _fileName = file.path
              .split('/')
              .last;
          if (_fileName.lastIndexOf("xlsx") > 0) {
            files.add(MutableFileData(
                isChecked: false,
                fileName: _fileName
                    .split('.')
                    .first,
                extensionName: _fileName
                    .split('.')
                    .last,
                lastModified: await File(file.path).lastModified(),
            ));
          }
        }

        files.sort((a, b) => b.fileName.compareTo(a.fileName));
        // files.sort((a, b) => b.lastModified.compareTo(a.lastModified));

        setState(() {
          _isReading = false;
          entries.clear();
          entries = files;
        });
      }
    } on Exception catch(e) {
      log(e.toString());
    }
  }

  Future<void> openFile(String fileName) async {
    try {
      final String? directoryPath = await Util.applicationDocumentsDirectory;
      await open_file.OpenFile.open('$directoryPath/$fileName');
    } on Exception catch(e) {
      log(e.toString());
    }
  }

  Future<int> deleteFiles() async {
    try {
      final String? directoryPath = await Util.applicationDocumentsDirectory;
      for (MutableFileData data in entries) {
        if (data.isChecked) {
          try {
            final file = File(
                '$directoryPath/${data.fileName}.${data.extensionName}');
            file.delete();
          } on Exception {
            return -1;
          }
        }
      }
      return 0;
    } on Exception catch(e) {
      log(e.toString());
      return -1;
    }
  }

  Future<bool> _onWillPop() async {
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
          appBar: AppBar(
            title: const Text("파일 목록"),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const PicUpSetting(title: '설정',),
                      transitionDuration: const Duration(seconds: 0),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          // backgroundColor: Colors.black,
          body: Column(
            children: <Widget>[
              Container(
                color: Colors.grey.shade300,
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0.0,
                              primary: Colors.red.withOpacity(0),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(2),
                                  ),
                                  side: BorderSide(color: Colors.transparent)),
                            ),
                            onPressed: () {
                              setState(() {
                                _isClicked = !_isClicked;
                                if(!_isClicked) {
                                  for(MutableFileData data in entries){
                                    data.isChecked = false;
                                  }
                                  _isAllChecked = false;
                                }
                              });
                            },
                            child: const Icon(Icons.check, color: Colors.black54,)
                        ),
                        _isClicked && entries.isNotEmpty
                            ? Row(
                          children: [
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0.0,
                                  primary: Colors.red.withOpacity(0),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(2),
                                      ),
                                      side: BorderSide(
                                          color: Colors.transparent)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isAllChecked = !_isAllChecked;
                                    for(MutableFileData data in entries) {
                                      data.isChecked = _isAllChecked;
                                    }
                                  });
                                },
                                child: const Icon(Icons.done_all, color: Colors.black54,)
                            ),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0.0,
                                  primary: Colors.red.withOpacity(0),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(2),
                                      ),
                                      side: BorderSide(
                                          color: Colors.transparent)),
                                ),
                                onPressed: () {
                                  int _count = 0;
                                  for(MutableFileData data in entries) {
                                    if(data.isChecked) {
                                      _count++;
                                    }
                                  }

                                  if(_count > 0) {
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          CupertinoAlertDialog(
                                            title: null,
                                            content:
                                            const Text("선택된 파일을 삭제하시겠습니까?",
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
                                                    Navigator.of(context,
                                                        rootNavigator: true)
                                                        .pop("Discard");

                                                    int result = await deleteFiles();
                                                    if (result == 0) {
                                                      readFiles();
                                                    } else {
                                                      showCupertinoDialog(
                                                        context: context,
                                                        builder: (BuildContext context) =>
                                                            CupertinoAlertDialog(
                                                              title: null,
                                                              content:
                                                              const Text("파일 삭제에 실패했습니다.",
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
                                                                      readFiles();
                                                                    },
                                                                    isDefaultAction: true,
                                                                    child: textWidget
                                                                ),
                                                              ],
                                                            ),
                                                      );
                                                    }
                                                  },
                                                  isDefaultAction: true,
                                                  child: textWidget
                                              ),
                                            ],
                                          ),
                                    );
                                  } else {
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          CupertinoAlertDialog(
                                            title: null,
                                            content:
                                            const Text("선택된 파일이 없습니다.",
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
                                                  },
                                                  isDefaultAction: true,
                                                  child: textWidget
                                              ),
                                            ],
                                          ),
                                    );
                                  }
                                },
                                child: Icon(Icons.delete_forever, color: Colors.red.shade900,)
                            ),
                          ],
                        )
                            : Container(),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0.0,
                              primary: Colors.red.withOpacity(0),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(2),
                                  ),
                                  side: BorderSide(color: Colors.transparent)),
                            ),
                            onPressed: () {
                              if(entries.isNotEmpty) {
                                readFiles();
                              }
                            },
                            child: Icon(Icons.refresh, color: Colors.green.shade400,)
                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0.0,
                              primary: Colors.red.withOpacity(0),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(2),
                                  ),
                                  side: BorderSide(color: Colors.transparent)),
                            ),
                            onPressed: () {
                              _moveCameraPage(context);
                            },
                            child: const Icon(Icons.camera, color: Colors.blue,)
                        ),
                      ],
                    )
                  ],
                ),
              ),
              /*
            Vertical viewport was given unbounded height.
            => scrollDirection, shrinkWrap 추가
           */
              entries.isNotEmpty
                  ? Expanded(
                  flex: 7,
                  child: Stack(
                    children: [
                      Scrollbar(
                        child:
                        ListView.separated(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 10),
                          itemCount: entries.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              height: 60,
                              color: Colors.green[index % 2 == 0 ? 300 : 100],
                              child: Container(
                                  padding: const EdgeInsets.only(left: 15, right: 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Row(
                                        children: [
                                          _isClicked
                                              ? SizedBox(
                                            width: 20,
                                            height: 10,
                                            child: Transform.scale(
                                              scale: 1.4,
                                              child: Checkbox(
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  value: entries[index].isChecked,
                                                  onChanged: (value) {
                                                    log("isChecked :: ${entries[index].isChecked}");
                                                    log("value :: $value");
                                                    setState(() {
                                                      entries[index].isChecked = value ?? false;
                                                    });
                                                  }),
                                            ),
                                          ) : Container(),
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            margin: EdgeInsets.only(left: _isClicked ? 16: 0),
                                            child: Text(
                                              '[${index+1}] ${entries[index].fileName}.${entries[index].extensionName}',
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                  fontSize: 15
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          // Container(
                                          //   alignment: Alignment.centerRight,
                                          //   margin: const EdgeInsets.only(top: 8, bottom: 8, right: 5),
                                          //   padding: const EdgeInsets.all(5.0),
                                          //   decoration: BoxDecoration(
                                          //     border: Border.all(
                                          //         color: Colors.white70, width: 1),
                                          //   ),
                                          //   child: Text(
                                          //     entries[index].extensionName,
                                          //     textAlign: TextAlign.left,
                                          //     style: const TextStyle(
                                          //         fontWeight: FontWeight.normal,
                                          //         color: Colors.black,
                                          //         fontSize: 14),
                                          //   ),
                                          // ),
                                          ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                elevation: 0.0,
                                                primary: Colors.red.withOpacity(0),
                                                shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.all(
                                                      Radius.circular(2),
                                                    ),
                                                    side: BorderSide(color: Colors.transparent)),
                                              ),
                                              onPressed: () {
                                                openFile('${entries[index].fileName}.${entries[index].extensionName}');
                                              },
                                              child: const Icon(Icons.open_in_new, color: Colors.black,)
                                          )
                                        ],
                                      )
                                    ],
                                  )
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                        ),
                      ),
                      _isReading == true
                            ? SpinKitWave(
                                color: Colors.blue.shade300,
                                size: 40.0,
                                type: SpinKitWaveType.center)
                            : const SizedBox(
                                width: 0,
                                height: 0,
                              )
                      ],
                  )
              ) : _isReading == true
                      ? Expanded(
                          flex: 8,
                          child: SpinKitWave(
                              color: Colors.blue.shade300,
                              size: 40.0,
                              type: SpinKitWaveType.center
                          ),
                        )
                      : Expanded(
                          flex: 8,
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              '파일 목록이 없습니다.',
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  fontSize: 16),
                            ),
                          )
                        ),
              Expanded(
                flex: 1,
                child: Container(
                  alignment: FractionalOffset.topCenter,
                  margin: const EdgeInsets.only(bottom: 0.0),
                  child: AdmobBanner(
                    adUnitId: Constants.bannerAdUnitId,
                    adSize: bannerSize!,
                    listener: (AdmobAdEvent event, Map<String, dynamic>? args) {
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
              )
            ],
          )
      ),
      onWillPop: _onWillPop,
    );

  }
}