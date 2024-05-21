import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:cross_file_image/cross_file_image.dart';

class ImageScreen extends StatelessWidget {
  File imagePath;
  Uint8List mapImage;

  // File watermarkedImage;
  ImageScreen(this.imagePath, this.mapImage, {super.key}); // Replace with your file path

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //   title: const Text('Image from File Path'),
        // ),
        body: Row(children: [
      SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          width: MediaQuery.of(context).size.width * 0.7,
          child: Image.file(imagePath,
              fit: BoxFit.fitWidth,
              // set the alignment of image
              alignment: Alignment.center)),
      SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          width: MediaQuery.of(context).size.width * 0.3,
          child: Image.memory(
            mapImage,
            fit: BoxFit.fitHeight,
            // set the alignment of image
            alignment: Alignment.center,
          )),
    ]));
  }

  Future<ImageProvider> xFileToImage(XFile xFile) async {
    final Uint8List bytes = await xFile.readAsBytes();
    return Image.memory(bytes).image;
  }
}
