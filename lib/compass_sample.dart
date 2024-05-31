import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:image_picker/image_picker.dart';

class Compass extends StatefulWidget {
  // Compass({Key key}) : super(key: key);
  @override
  _CompassState createState() => _CompassState();
}

class _CompassState extends State<Compass> {
  double _heading = 0.0;
  late XFile _image;
  late bool isPortrait;
  final picker = ImagePicker();

  String get _readout => (_heading > 0) ? '${_heading.toStringAsFixed(0)}°' : '${(0 - _heading).toStringAsFixed(0)}°';

  @override
  void initState() {
    super.initState();
    // The argument type 'void Function(double)' can't be assigned to the parameter type 'void Function(CompassEvent)?'.
    FlutterCompass.events?.listen(_onData);
  }

  void _onData(CompassEvent x) {
    if (this.mounted) {
      setState(() {
        _heading = x.heading!;
      });
    }


  }

  final TextStyle _style =
      TextStyle(color: Colors.red[50]?.withOpacity(0.9), fontSize: 32, fontWeight: FontWeight.w200);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: OrientationBuilder(builder: (_, orientation) {
          if (orientation == Orientation.portrait) {
            return CustomPaint(
                foregroundPainter: CompassPainter(angle: _heading, isPortrait: true),
                child: Center(child: Text(_readout, style: _style)));
          } else {
            return CustomPaint(
                foregroundPainter: CompassPainter(angle: _heading, isPortrait: false),
                child: Center(child: Text(_readout, style: _style)));
          }
        }));
  }
}

class CompassPainter extends CustomPainter {
  CompassPainter({required this.angle, required this.isPortrait}) : super();

  bool isPortrait;
  final double angle;

  double get rotation => -2 * pi * (angle / 360);

  Paint get _brush => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    Paint circle = _brush..color = Colors.indigo[400]!.withOpacity(0.6);
    Paint needle = _brush..color = Colors.red[400]!;

    /// Android Portrait
    double radius;
    Offset center;
    Offset? start;
    Offset? end;

    if (isPortrait) {
      /// Android Portrait
      radius = min(size.height / 3, size.width / 3);
      center = Offset(size.height / 2.5, size.width / 2.3);
      start = Offset.lerp(Offset(center.dx, radius), center, 3);
      end = Offset.lerp(Offset(center.dx, radius), center, 1);
    } else {
      /// Android Landscape
      radius = min(size.height / 3, size.width / 3);
      center = Offset(size.height / 2, size.width / 2.3);
      start = Offset.lerp(Offset(center.dx, radius), center, 3);
      end = Offset.lerp(Offset(center.dx, radius), center, 1);
    }

    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawLine(start!, end!, needle);
    canvas.drawCircle(center, radius, circle);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
