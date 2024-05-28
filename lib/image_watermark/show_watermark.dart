import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageScreen extends StatefulWidget {
  File imagePath;
  Uint8List mapImage;

  // File watermarkedImage;
  ImageScreen(this.imagePath, this.mapImage, {super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  double _rotation = 0.0;
  bool _isFlipped = false;

  void _rotateImage() {
    setState(() {
      _rotation += 90.0;
      if (_rotation == 360.0) {
        _rotation = 0.0;
      }
    });
  }

  // Replace with your file path
  void _flipImage() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return Scaffold(
        appBar: AppBar(
          title: const Text('View Image'),
            actions: <Widget>[
              InkWell(
                onTap: _rotateImage,
                child: Container(
                    margin: const EdgeInsets.all(10.0),
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white)
                    ),
                    child: const Text("Rotate Image",style: TextStyle(backgroundColor: Colors.black),)),
              ),
            ],
        ),
        body: SingleChildScrollView(
                child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.75,
              width: MediaQuery.of(context).size.width,
              child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationZ(_rotation * 3.1415927 / 180)..scale(_isFlipped ? -1.0 : 1.0, 1.0),
                    child: Image.file(widget.imagePath,
                        fit: BoxFit.fitWidth,
                        // Set the alignment of image
                        alignment: Alignment.center),
                  )),
            ),
            Column(
              children:[
                SizedBox(height: MediaQuery.of(context).size.height * 0.75),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                      onTap: _rotateImage,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.15,
                        child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.memory(widget.mapImage,
                                fit: BoxFit.cover,
                                // Set the alignment of image..
                                alignment: Alignment.center)),
                      )),
                ),
              ]
            ),
          ],
        )));
  }

  Future<ImageProvider> xFileToImage(XFile xFile) async {
    final Uint8List bytes = await xFile.readAsBytes();
    return Image.memory(bytes).image;
  }
}
