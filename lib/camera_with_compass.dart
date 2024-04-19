import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import 'camera_page.dart';
import 'main.dart';

class CameraWithCompass extends StatefulWidget {
  const CameraWithCompass({super.key});

  @override
  State<CameraWithCompass> createState() => _CameraWithCompassState();
}

class _CameraWithCompassState extends State<CameraWithCompass> with WidgetsBindingObserver {
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The argument type 'void Function(double)' can't be assigned to the parameter type 'void Function(CompassEvent)?'.
    FlutterCompass.events?.listen(_onData);
  }
  void _onData(CompassEvent x) => setState(() { _heading = x.heading!; });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Camera App',
        themeMode: ThemeMode.dark,
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        // home : MapScreen(),//MapSample(),
        home: Stack(children: [
          const CameraPage(),
          CompassDemo(),
          Container(
              decoration: BoxDecoration(
            border: Border.all(color: (!(_heading.toInt()<=100||_heading.toInt()>=150)) ? Colors.green : Colors.red, width: 10.0)
          ))
        ]));
  }
}
