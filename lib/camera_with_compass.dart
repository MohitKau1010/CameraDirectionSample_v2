import 'package:flutter/material.dart';

import 'camera_page.dart';
import 'main.dart';

class CameraWithCompass extends StatefulWidget {
  const CameraWithCompass({super.key});

  @override
  State<CameraWithCompass> createState() => _CameraWithCompassState();
}

class _CameraWithCompassState extends State<CameraWithCompass> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Camera App',
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      // home : MapScreen(),//MapSample(),
      home: Stack(children:[
          const CameraPage(),
          CompassDemo()
      ]),
    );
  }
}
