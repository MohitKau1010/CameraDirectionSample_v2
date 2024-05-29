import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:image_picker/image_picker.dart';
import 'map_sample.dart';

// void main() => runApp(CompassDemo());
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp,DeviceOrientation.portraitDown,DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// Lock the orientation to portrait mode
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.portraitUp,
    // ]);
    return MaterialApp(
      title: 'Flutter Camera App',
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: MapScreen(), // CameraScreen()  // const MapSample(),  // const CameraWithCompass(),
      // home: Stack(children:[
      //     const CameraPage(),
      //     CompassDemo()
      // ]),
    );
  }
}



