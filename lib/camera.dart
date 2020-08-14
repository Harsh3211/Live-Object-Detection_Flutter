import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

typedef void Callback(List<dynamic> list, int h, int w);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;

  Camera({this.cameras,  this.setRecognitions});

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController camera_controller;
  bool detecting = false;

  @override
  void initState() {
    super.initState();

    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera found');
    } else {
      camera_controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      camera_controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        camera_controller.startImageStream((CameraImage img) {
          if (!detecting) {
            detecting = true;

            int startTime = new DateTime.now().millisecondsSinceEpoch;

              Tflite.detectObjectOnFrame(
                bytesList: img.planes.map((plane) {
                  return plane.bytes;
                }).toList(),
//                model: widget.model == yolo ? "YOLO" : "SSDMobileNet",
                imageHeight: img.height,
                imageWidth: img.width,
                imageMean: 127.5,
                imageStd:  127.5,
                numResultsPerClass: 1,
                threshold:  0.4,
              ).then((recognitions) {
                int endTime = new DateTime.now().millisecondsSinceEpoch;
                print("Detection took ${endTime - startTime}");

                widget.setRecognitions(recognitions, img.height, img.width);

                detecting = false;
              });
            }
          });
      });
    }
  }

  @override
  void dispose() {
    camera_controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (camera_controller == null || !camera_controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = camera_controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(camera_controller),
    );
  }
}
