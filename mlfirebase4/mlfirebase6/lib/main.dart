import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:proximity_plugin/proximity_plugin.dart';
import 'package:screen/screen.dart';
import 'package:sensors/sensors.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:ext_storage/ext_storage.dart';

Future<void> main() async {
  runApp(new MyDetector());
}

class MyDetector extends StatefulWidget {
  @override
  _MyDetectorState createState() => _MyDetectorState();
}

class _MyDetectorState extends State<MyDetector> {

  static const platform = const MethodChannel('com.example.epic/epic');

  void Printy() async {
    String value;

    try{
      value = await platform.invokeMethod("Printy");
      print(value);
    } catch (e) {
      print(e);
    }
  }

  String _proximity ;
  double brightness ;


//  static const platform = const MethodChannel('flutterAndroidBridge');
//  String _responseFromNativeCode = 'Waiting for Response...';
//
//  Future<void> responseFromNativeCode() async {
//    String response = "";
//    try {
//      final String result = await platform.invokeMethod('helloFromNativeCode');
//      response = result;
//    } on PlatformException catch (e) {
//      response = "Failed to Invoke: '${e.message}'.";
//    }
//    setState(() {
//      _responseFromNativeCode = response;
//    });
//  }


  List<StreamSubscription<dynamic>> _streamSubscriptions =
  <StreamSubscription<dynamic>>[];
  List<double> _accelerometerValues = <double>[0.0, 0.0, 0.0];
  List<double> _gyroscopeValues = <double>[0.0, 0.0, 0.0];
  List<double> _userAccelerometerValues = <double>[0.0, 0.0, 0.0];
  @override
  initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    _streamSubscriptions
        .add(proximityEvents.listen((ProximityEvent event) async {
      _proximity= event.x;
      if(_proximity == "Yes"){
        Fluttertoast.showToast(
            msg: "Your eyes are too close",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIos: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
        brightness = await Screen.brightness;

        // Set the brightness:
        //Screen.setBrightness(0);

        // Check if the screen is kept on:
        //bool isKeptOn = await Screen.isKeptOn;

        // Prevent screen from going into sleep mode:
        //Screen.keepOn(true);
      }
      else{
        //Screen.setBrightness(brightness);
      }

      setState(() {


      });
    }));

    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));
    _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];

      });
    }));
    _streamSubscriptions
        .add(userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        _userAccelerometerValues = <double>[event.x, event.y, event.z];
        if(_userAccelerometerValues[0].abs() > 10){
          getImage();
        }
      });
    }));
  }








  File _image;
  Rect boundingBox;
  FaceLandmark leftEye;
  FaceLandmark rightEye;
  Offset leftEyePos;
  Offset rightEyePos;
  double distance;

  FirebaseVisionImage visionImage;
  FaceDetector faceDetector;
  List<Face> faces;

  Future getImage() async {
    var path = await ExtStorage.getExternalStorageDirectory();

    leftEye = null;
    rightEye = null;
    boundingBox = null;
    leftEyePos = null;
    rightEyePos = null;
    distance = null;

    _image = File(path + '/1_pic.jpg');
    Fluttertoast.showToast(
        msg: 'Image Detected',
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
        toastLength: Toast.LENGTH_SHORT
    );
    visionImage = FirebaseVisionImage.fromFile(_image);
    faceDetector = FirebaseVision.instance.faceDetector(
        FaceDetectorOptions(enableLandmarks: true)
    );
    faces = await faceDetector.processImage(visionImage);
    if(faces == null) Fluttertoast.showToast(
        msg: "Too close, back off",
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIos: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );

    for(Face face in faces){
      boundingBox = face.boundingBox;
      leftEye = face.getLandmark(FaceLandmarkType.leftEye);
      rightEye = face.getLandmark(FaceLandmarkType.rightEye);

      if(leftEye != null){
        leftEyePos = leftEye.position;
      }
      if(rightEye != null){
        rightEyePos = rightEye.position;
      }
    }

    distance = (leftEyePos - rightEyePos).distance;
    print(distance);
    if(distance > 500){Fluttertoast.showToast(
        msg: "Too close, back off",
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIos: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );}
    else if(distance < 300){Fluttertoast.showToast(
        msg: "Too far, come upfront",
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIos: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );}
    else {Fluttertoast.showToast(
        msg: "Keep it up",
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIos: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );}
    faceDetector.close();

    setState(() {


    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: new Center(
          child: Column(
            children: <Widget>[
              new Text('User Accelerometer is: \n'
                  'x: ${_userAccelerometerValues[0]} \n'
                  'y: ${_userAccelerometerValues[1]} \n'
                  'z: ${_userAccelerometerValues[2]} \n'),
              RaisedButton(
                child: Text('Press me'),
                onPressed: () {
                  Printy();
                },
              )
            ],
          ),
        ),
      ),
    );
  }

//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text('Face Detection Demo'),
//      ),
//      body: Center(
//        child:
//        _image == null ?
//        Text('No Image Selected') :
//        Image.file(_image, height: 700,),
//
//      ),
//      floatingActionButton: FloatingActionButton(
//        onPressed: getImage,
//        tooltip: 'Pick Image',
//        child: Icon(Icons.add_a_photo),
//      ),
//    );
//  }
}







