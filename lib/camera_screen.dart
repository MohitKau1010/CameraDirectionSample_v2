// import 'dart:io';
// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter_compass/flutter_compass.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:sensors/sensors.dart';
// import 'main.dart';
// class CameraScreen extends StatefulWidget {
//   @override
//   CameraScreenState createState() => CameraScreenState();
// }
//
// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _controller;
//   Position? _currentPosition;
//   double _heading = 0.0;
//   bool _isLoading = true;
//   int _selectedCameraIndex = 0;
//   var _direction = "";
//   @override
//   void initState() {
//     super.initState();
//     _initCamera();
//     _initLocation();
//     _initCompass();
//
//   }
//
//   void _initCamera() {
//     _controller = CameraController(cameras![_selectedCameraIndex], ResolutionPreset.medium);
//     controller?.initialize().then(() {
//       if (!mounted) {
//         return;
//       }
//       setState(() {
//         _isLoading = false;
//       });
//     });
//   }
//
//   void _initLocation() async {
//     var location = Location();
//     try {
//       var userLocation = await location.getLocation();
//       setState(() {
//         _currentPosition = userLocation;
//       });
//     } catch (e) {
//       print("Failed to get location: $e");
//     }
//   }
//
//   void _initCompass() {
//     FlutterCompass.events?.listen((event) {
//       if(mounted){
//         setState(() {
//           _heading = event.heading!;
//         });
//       }
//
//     });
//   }
//
//   // String _getDirection(double heading) {
//   //   if (heading >= 45 && heading < 135) {
//   //     return 'East';
//   //   } else if (heading >= 135 && heading < 225) {
//   //     return 'South';
//   //   } else if (heading >= 225 && heading < 315) {
//   //     return 'West';
//   //   } else {
//   //     return 'North';
//   //   }
//   // }
//
//   String _getDirection(double heading) {
//     if ((heading >= 0 && heading < 22.5) || (heading >= 337.5 && heading <= 360)) {
//       return 'North';
//     } else if (heading >= 22.5 && heading < 67.5) {
//       return 'North-East';
//     } else if (heading >= 67.5 && heading < 112.5) {
//       return 'East';
//     } else if (heading >= 112.5 && heading < 157.5) {
//       return 'South-East';
//     } else if (heading >= 157.5 && heading < 202.5) {
//       return 'South';
//     } else if (heading >= 202.5 && heading < 247.5) {
//       return 'South-West';
//     } else if (heading >= 247.5 && heading < 292.5) {
//       return 'West';
//     } else { // From 292.5 to 337.5
//       return 'North-West';
//     }
//   }
//
//   Future<void> _captureAndSave() async {
//     try {
//       final image = await _controller?.takePicture();
//       // Save the image details along with direction, location, and camera lens direction
//       final capturedImageDetails = ImageDetails(
//         image: image!,
//         direction: _getDirection(_heading),
//         latitude: _currentPosition!.latitude,
//         longitude: _currentPosition!.longitude,
//         cameraLensDirection: _controller?.description.lensDirection,
//       );
//       Navigator.pop(context,capturedImageDetails);
//       // Do whatever you want with capturedImageDetails (e.g., save to storage)
//     } catch (e) {
//       print("Error: $e");
//     }
//   }
//
//   Future<void> _toggleCamera() async {
//     // Dispose the current controller
//     await _controller?.dispose();
//     // Toggle the selected camera index
//     // selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
//     // Reinitialize the camera with the new selected index
//     _initCamera();
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Center(child: CircularProgressIndicator());
//     }
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Camera with Direction and Location'),
//         actions: [
//           IconButton(
//             onPressed: _toggleCamera,
//             icon: Icon(Icons.switch_camera),
//           ),
//         ],
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: RotatedBox(
//               quarterTurns: (_heading ~/ 90) % 1,
//               child: CameraPreview(_controller!),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Direction: ${_getDirection(_heading)}',
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Latitude: ${_currentPosition?.latitude}',
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Longitude: ${_currentPosition?.longitude}',
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Camera Lens Direction: ${_controller?.description.lensDirection.toString()}',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _captureAndSave,
//             child: Text('Capture and Save'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ImageDetails {
//   final XFile image;
//   final String direction;
//   final double latitude;
//   final double longitude;
//   final CameraLensDirection? cameraLensDirection;
//   String id = DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10);
//   ImageDetails({
//     required this.image,
//     required this.direction,
//     required this.latitude,
//     required this.longitude,
//     this.cameraLensDirection,
//   });
// }