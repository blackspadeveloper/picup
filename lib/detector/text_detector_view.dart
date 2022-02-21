import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:picup/google_ml_kit/google_ml_kit.dart';
import 'package:picup/google_ml_kit/vision/vision.dart';

import 'camera_view.dart';
import 'text_detector_painter.dart';

class TextDetectorView extends StatefulWidget {
  const TextDetectorView({Key? key}) : super(key: key);

  @override
  _TextDetectorViewState createState() => _TextDetectorViewState();
}

class _TextDetectorViewState extends State<TextDetectorView> {
  TextDetector textDetector = GoogleMlKit.vision.textDetector();
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
    final recognisedText = await textDetector.processImage(inputImage);
    recognitionText = recognisedText.text;
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
