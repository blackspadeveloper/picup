import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:picup/constants.dart';
import 'package:picup/file/create_file.dart';
import 'package:picup/google_ml_kit/vision/vision.dart';

import '../main.dart';
import '../util.dart';

enum ScreenMode { liveFeed, gallery }

class CameraView extends StatefulWidget {
  const CameraView(
      {Key? key,
      required this.title,
      required this.customPaint,
      required this.onImage,
      this.recognisedText,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final Function(InputImage inputImage, Function(bool result) callback) onImage;
  final CameraLensDirection initialDirection;

  final String? recognisedText;

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  // ScreenMode _mode = ScreenMode.liveFeed;
  final ScreenMode _mode = ScreenMode.gallery;
  CameraController? _controller;
  File? _image;
  ImagePicker? _imagePicker;
  int _cameraIndex = 0;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;

  late AdmobBannerSize bannerSize;
  bool isCreating = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();

    _imagePicker = ImagePicker();
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == widget.initialDirection) {
        _cameraIndex = i;
      }
    }
    bannerSize = AdmobBannerSize.BANNER;
    // _startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
        actions: const [
          // Padding(
          //   padding: const EdgeInsets.only(right: 20.0),
          //   child: GestureDetector(
          //     onTap: _switchScreenMode,
          //     child: Icon(
          //       _mode == ScreenMode.liveFeed
          //           ? Icons.photo_library_outlined
          //           : (Platform.isIOS
          //               ? Icons.camera_alt_outlined
          //               : Icons.camera),
          //     ),
          //   ),
          // ),
        ],
      ),
      body: _body(size),
      // floatingActionButton: _floatingActionButton(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Widget? _floatingActionButton() {
  //   if (_mode == ScreenMode.gallery) return null;
  //   if (cameras.length == 1) return null;
  //   return SizedBox(
  //       height: 70.0,
  //       width: 70.0,
  //       child: FloatingActionButton(
  //         child: Icon(
  //           Platform.isIOS
  //               ? Icons.flip_camera_ios_outlined
  //               : Icons.flip_camera_android_outlined,
  //           size: 40,
  //         ),
  //         onPressed: _switchLiveCamera,
  //       ));
  // }

  Widget _body(Size size) {
    Widget body;
    if (_mode == ScreenMode.liveFeed) {
      body = _liveFeedBody();
    } else {
      body = _galleryBody(size);
    }
    return body;
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CameraPreview(_controller ?? getCameraController()),
          if (widget.customPaint != null) widget.customPaint!,
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Slider(
              value: zoomLevel,
              min: minZoomLevel,
              max: maxZoomLevel,
              onChanged: (newSliderValue) {
                setState(() {
                  zoomLevel = newSliderValue;
                  _controller!.setZoomLevel(zoomLevel);
                });
              },
              divisions: (maxZoomLevel - 1).toInt() < 1
                  ? null
                  : (maxZoomLevel - 1).toInt(),
            ),
          )
        ],
      ),
    );
  }

  Widget _galleryBody(Size size) {
    return Stack(children: [
      Column(
        children: [
          Flexible(
            flex: 8,
            fit: FlexFit.tight,
            child: ListView(shrinkWrap: true, children: [
              _image != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: SizedBox(
                        width: 400,
                        height: 400,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, right: 10.0),
                          child: Image.file(_image!),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image_rounded,
                      size: 200,
                      color: Colors.grey,
                    ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    widget.recognisedText != null
                        ? const Text(
                            '[ 텍스트 확인 결과 ]',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16),
                          )
                        : const Text(''),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: widget.recognisedText != null &&
                              widget.recognisedText!.isNotEmpty
                          ? Container(
                              width: size.width,
                              margin: const EdgeInsets.all(10.0),
                              padding: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.deepOrange, width: 2),
                              ),
                              child: Text(
                                widget.recognisedText ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16),
                              ), // 텍스트 추출 결과
                            )
                          : const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text(
                                '확인된 텍스트가 없습니다.',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              )),
                    ),
                    widget.recognisedText != null &&
                            widget.recognisedText!.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(
                                left: 30, top: 20, right: 30),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0.0,
                                primary: Colors.green,
                                fixedSize: Size(size.width, 50),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                    side:
                                        BorderSide(color: Colors.transparent)),
                              ),
                              onPressed: () {
                                setState(() {
                                  isCreating = true;
                                });
                                generateExcel(context, _image?.absolute.path,
                                    (result) {
                                  setState(() {
                                    isCreating = false;
                                  });
                                });
                              },
                              child: const Text(
                                "파일 저장",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        : const Text('')
                  ],
                ),
              ),
            ]),
          ),
          Flexible(
              flex: 2,
              fit: FlexFit.tight,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 0.0),
                    child: AdmobBanner(
                      adUnitId: Constants.bannerAdUnitId,
                      adSize: bannerSize,
                      listener: (AdmobAdEvent event, Map<String, dynamic>? args) {
                        // Ad failed to load : 3 -> 개발 과정이나 정책 오류로 인한 패널티가 아니라 단순히 광고를 평가라는 이유로 빼버린 상황인 것이다.
                        Util.handleEventAdMob(context, event, args, 'Banner');
                      },
                      onBannerCreated: (AdmobBannerController controller) {
                        // Dispose is called automatically for you when Flutter removes the banner from the widget tree.
                        // Normally you don't need to worry about disposing this yourself, it's handled.
                        // If you need direct access to dispose, this is your guy!
                        // controller.dispose();
                      },
                    ),
                  ),
                  SizedBox(
                      height: 65,
                      child: Row(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            color: Colors.blue,
                            child: InkWell(
                              onTap: () {
                                _getImage(ImageSource.gallery);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: size.width / 2,
                                child: const Text(
                                  "갤러리",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            color: Colors.blue,
                            child: InkWell(
                              onTap: () {
                                _getImage(ImageSource.camera);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: size.width / 2,
                                child: const Text(
                                  "카메라",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                  ),
                ],
              )
          ),
        ],
      ),
      isCreating == true
          ? SpinKitWave(
              color: Colors.blue.shade300,
              size: 40.0,
              type: SpinKitWaveType.center)
          : const SizedBox(
              width: 0,
              height: 0,
            )
      ,
      isProcessing == true
          ? SpinKitWave(
              color: Colors.blue.shade300,
              size: 40.0,
              type: SpinKitWaveType.center)
          : const SizedBox(
              width: 0,
              height: 0,
            )
    ]);
  }

  Future _getImage(ImageSource source) async {
    final pickedFile = await _imagePicker?.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    } else {
      Util.showToast('선택된 사진이 없습니다.');
      debugPrint('No image selected.');
    }
    setState(() {});
  }

  // void _switchScreenMode() async {
  //   if (_mode == ScreenMode.liveFeed) {
  //     _mode = ScreenMode.gallery;
  //     await _stopLiveFeed();
  //   } else {
  //     _mode = ScreenMode.liveFeed;
  //     await _startLiveFeed();
  //   }
  //   setState(() {});
  // }

  CameraController getCameraController() {
    final camera = cameras[_cameraIndex];
    return CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
    );
  }

  // Future _startLiveFeed() async {
  //   final camera = cameras[_cameraIndex];
  //   _controller = CameraController(
  //     camera,
  //     ResolutionPreset.low,
  //     enableAudio: false,
  //   );
  //   _controller?.initialize().then((_) {
  //     if (!mounted) {
  //       return;
  //     }
  //     _controller?.getMinZoomLevel().then((value) {
  //       zoomLevel = value;
  //       minZoomLevel = value;
  //     });
  //     _controller?.getMaxZoomLevel().then((value) {
  //       maxZoomLevel = value;
  //     });
  //     _controller?.startImageStream(_processCameraImage);
  //
  //     _controller?.setFocusMode(FocusMode.auto);
  //
  //     setState(() {});
  //   });
  // }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  // Future _switchLiveCamera() async {
  //   if (_cameraIndex == 0) {
  //     _cameraIndex = 1;
  //   } else {
  //     _cameraIndex = 0;
  //   }
  //   await _stopLiveFeed();
  //   await _startLiveFeed();
  // }

  Future _processPickedFile(XFile pickedFile) async {
    _image = null;
    // image_cropper 추가
    File? croppedFile = await ImageCropper.cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 80,
        compressFormat: ImageCompressFormat.png,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: const AndroidUiSettings(
            toolbarTitle: '사진 편집',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: const IOSUiSettings(
          title: '사진 편집',
          minimumAspectRatio: 1.0,
          doneButtonTitle: '확인',
          cancelButtonTitle: '취소',
        )
    );

    setState(() {
      isProcessing = true;
      if(croppedFile != null) {
        _image = croppedFile;
      } else {
        _image = File(pickedFile.path);
      }
    });

    // final inputImage = InputImage.fromFilePath(pickedFile.path);
    final inputImage = InputImage.fromFilePath(_image!.path);
    widget.onImage(inputImage, (result) {
      isProcessing = false;
    });
  }

  // Future _processCameraImage(CameraImage image) async {
  //   final WriteBuffer allBytes = WriteBuffer();
  //   for (Plane plane in image.planes) {
  //     allBytes.putUint8List(plane.bytes);
  //   }
  //   final bytes = allBytes.done().buffer.asUint8List();
  //
  //   final Size imageSize =
  //       Size(image.width.toDouble(), image.height.toDouble());
  //
  //   final camera = cameras[_cameraIndex];
  //   final imageRotation =
  //       InputImageRotationMethods.fromRawValue(camera.sensorOrientation) ??
  //           InputImageRotation.Rotation_0deg;
  //
  //   final inputImageFormat =
  //       InputImageFormatMethods.fromRawValue(image.format.raw) ??
  //           InputImageFormat.NV21;
  //
  //   final planeData = image.planes.map(
  //     (Plane plane) {
  //       return InputImagePlaneMetadata(
  //         bytesPerRow: plane.bytesPerRow,
  //         height: plane.height,
  //         width: plane.width,
  //       );
  //     },
  //   ).toList();
  //
  //   final inputImageData = InputImageData(
  //     size: imageSize,
  //     imageRotation: imageRotation,
  //     inputImageFormat: inputImageFormat,
  //     planeData: planeData,
  //   );
  //
  //   final inputImage =
  //       InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  //
  //   widget.onImage(inputImage, (result) {
  //     isProcessing = false;
  //   });
  // }

}
