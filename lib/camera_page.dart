import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:video_player/video_player.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  late final List<CameraDescription> _cameras;
  bool _isRecording = false;
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initCamera();
    // The argument type 'void Function(double)' can't be assigned to the parameter type 'void Function(CompassEvent)?'.
    FlutterCompass.events?.listen(_onData);
  }
  void _onData(CompassEvent x) => setState(() { _heading = x.heading!; });


  Future<void> initCamera() async {
    _cameras = await availableCameras();
    // Initialize the camera with the first camera in the list
    await onNewCameraSelected(_cameras.first);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<XFile?> capturePhoto() async {
    final CameraController? cameraController = _controller;
    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      await cameraController.setFlashMode(FlashMode.off);
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      debugPrint('Error occured while taking picture: $e');
      return null;
    }
  }

  Future<XFile?> captureVideo() async {
    final CameraController? cameraController = _controller;
    try {
      setState(() {
        _isRecording = true;
      });
      await cameraController?.startVideoRecording();
      await Future.delayed(const Duration(seconds: 5));
      final video = await cameraController?.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      return video;
    } on CameraException catch (e) {
      debugPrint('Error occured while taking picture: $e');
      return null;
    }
  }

  void _onTakePhotoPressed() async {
    final navigator = Navigator.of(context);
    final xFile = await capturePhoto();
    if (xFile != null) {
      if (xFile.path.isNotEmpty) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => PreviewPage(
              imagePath: xFile.path
            ),
          ),
        );
      }
    }

    /*try {
      // Ensure that the camera is initialized
      await _initializeControllerFuture;

      // Attempt to take a picture and get the file
      final image = await _controller.takePicture();

      // If the picture was taken, display it on a new screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: image?.path),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console
      print("Error taking picture: $e");
    }*/
  }

  void _onRecordVideoPressed() async {
    final navigator = Navigator.of(context);
    final xFile = await captureVideo();
    if (xFile != null) {
      if (xFile.path.isNotEmpty) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => PreviewPage(
              videoPath: xFile.path,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCameraInitialized) {
      return SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              CameraPreview(_controller!),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Visibility(
                      visible: !(_heading.toInt()<=100||_heading.toInt()>=150),
                      child: ElevatedButton(
                        onPressed: _onTakePhotoPressed,
                        style: ElevatedButton.styleFrom(
                            fixedSize: const Size(70, 70), shape: const CircleBorder(), backgroundColor: Colors.white),
                        child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
                      ),
                    ),
                  /*if (!_isRecording) const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed:_isRecording? null: _onRecordVideoPressed,
                    style: ElevatedButton.styleFrom(
                        fixedSize: const Size(70, 70),
                        shape: const CircleBorder(),
                        backgroundColor: Colors.white),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.videocam,
                      color: Colors.red,
                    ),
                  ),*/
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Future<void> onNewCameraSelected(CameraDescription description) async {
    final previousCameraController = _controller;

    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      description,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      debugPrint('Error initializing camera: $e');
    }
    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        _controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = _controller!.value.isInitialized;
      });
    }
  }
}

class PreviewPage extends StatefulWidget {
  final String? imagePath;
  final String? videoPath;

  const PreviewPage({Key? key, this.imagePath, this.videoPath}) : super(key: key);

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  VideoPlayerController? controller;

  Future<void> _startVideoPlayer() async {
    if (widget.videoPath != null) {
      controller = VideoPlayerController.file(File(widget.videoPath!));
      await controller!.initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized,
        // even before the play button has been pressed.
        setState(() {});
      });
      await controller!.setLooping(true);
      await controller!.play();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.videoPath != null) {
      _startVideoPlayer();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: widget.imagePath != null
            ? Image.file(
                File(widget.imagePath ?? ""),
                fit: BoxFit.cover,
              )
            : AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
      ),
    );
  }
}
