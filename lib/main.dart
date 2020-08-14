import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'camera.dart';
import 'boundingndboxes.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print(e);
  }
  runApp(LiveStream());
}



class LiveStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
//      initialRoute: '/',
//      routes: {
//        // When navigating to the "/" route, build the FirstScreen widget.
//        '/': (context) => Sample(),
//        // When navigating to the "/second" route, build the SecondScreen widget.
//        '/live': (context) => CameraApp(cameras),
//      },
      debugShowCheckedModeBanner: false,
      title: 'LiveStream',
//      theme: ThemeData(
//        primarySwatch: Colors.blue,
//      ),
      home: CameraApp(cameras),
    );
  }
}

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraApp(this.cameras);

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  int minacc = 50;

  loadModel() async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
        model: "assets/detect.tflite",
        labels: "assets/labelmap.txt",
      );

      print('Model Loaded $res');
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  @override
  void initState() {
    super.initState();
    loadModel().then((value) => print('Just loading'));
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Tflite'),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Camera(
              cameras: widget.cameras,
              setRecognitions: setRecognitions,
            ),
            Boxdetect(
              results: _recognitions != null ? _recognitions : [],
              previewH: math.max(_imageHeight, _imageWidth),
              previewW: math.min(_imageHeight, _imageWidth),
              screenH: screen.height,
              screenW: screen.width,
              minacc: minacc,
            ),
          ],
        ),
      ),
    );
  }
}
