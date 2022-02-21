import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:picup/google_ml_kit/google_ml_kit.dart';
import 'package:picup/google_ml_kit/vision/vision.dart';

import 'camera_view.dart';
import 'text_detector_painter.dart';

class TextDetectorV2View extends StatefulWidget {
   const TextDetectorV2View({Key? key}) : super(key: key);

  @override
  _TextDetectorViewV2State createState() => _TextDetectorViewV2State();
}

class _TextDetectorViewV2State extends State<TextDetectorV2View> {
  TextDetectorV2 textDetector = GoogleMlKit.vision.textDetectorV2();
  bool isBusy = false;
  CustomPaint? customPaint;

  String? recognitionText;

  @override
  void dispose() async {
    super.dispose();
    await textDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: '텍스트 확인',
      customPaint: customPaint,
      recognisedText: recognitionText,
      onImage: (inputImage, callback) {
        processImage(inputImage, (result) {
          callback(result);
        });
      },
    );
  }

  Future<void> processImage(InputImage inputImage, Function(bool result) processCallback) async {
    if (isBusy) return;
    isBusy = true;
    final recognisedText = await textDetector.processImage(inputImage,
        script: TextRecognitionOptions.KOREAN); // 언어 설정
        // script: TextRecognitionOptions.DEVANAGIRI);
    recognitionText = recognisedText.text;
    log('recognitionText : $recognitionText');
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = TextDetectorPainter(
          recognisedText,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      customPaint = CustomPaint(painter: painter);
      processCallback(true);
    } else {
      customPaint = null;
      processCallback(false);
    }
    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
