import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:compass/image_watermark/show_watermark.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'camera_page.dart';
import 'compass_sample.dart';
import 'main.dart';

class CameraWithCompass extends StatefulWidget {
  const CameraWithCompass({super.key});

  @override
  State<CameraWithCompass> createState() => _CameraWithCompassState();
}

class _CameraWithCompassState extends State<CameraWithCompass> with WidgetsBindingObserver {
  double _heading = 0;
  late bool isPortrait;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The argument type 'void Function(double)' can't be assigned to the parameter type 'void Function(CompassEvent)?'.
    FlutterCompass.events?.listen(_onData);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onData(CompassEvent x) => setState(() {
        _heading = x.heading!;
      });

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    // Lock the orientation to portrait mode...
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
    return MaterialApp(
        // title: 'Flutter Camera App',
        themeMode: ThemeMode.dark,
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        // home : MapScreen(), // MapSample(),
        home: Scaffold(
          body: Stack(children: [
            Container(
                height: MediaQuery.of(context).size.height * 0.99,
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(top: 5.0),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: (!(_heading.toInt() <= 100 || _heading.toInt() >= 150)) ? Colors.green : Colors.red,
                        width: 15.0)),
                child: const CameraPage()),

            /// COMPASS
            SizedBox(
                height: (isPortrait) ? MediaQuery.of(context).size.height * 0.55 : MediaQuery.of(context).size.height,
                width: (isPortrait) ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.width*0.5,
                child: Compass()),

            /// BACK BUTTON
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                  height: 40,
                  width: 100,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text("< Back")),
            ),
          ]),
        ));
  }
}
