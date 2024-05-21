import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'circular_map.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'image_watermark/show_watermark.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  late TabController _tabController;

  // for
  bool _isCameraInitialized = false;
  late final List<CameraDescription> _cameras;
  bool _isRecording = false;

  // for getting head direction.
  double _heading = 0;

  //Create an instance of ScreenshotController
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    initCamera();
    // The argument type 'void Function(double)' can't be assigned to the parameter type 'void Function(CompassEvent)?'.
    FlutterCompass.events?.listen(_onData);
  }

  void _onData(CompassEvent x) => setState(() {
        _heading = x.heading!;
      });

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
    _tabController.dispose();
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
      debugPrint('Error occurred while taking picture: $e');
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
      debugPrint('Error occurred while taking picture: $e');
      return null;
    }
  }

  void onTakePhotoPressed() async {
    print("<<<< PRESSED >>>");
    // final navigator = Navigator.of(context);
    final xFile = await capturePhoto();
    if (xFile != null) {
      if (xFile.path.isNotEmpty) {
        //
        /// Add watermark text...
        // get the image file
        // File assetFile = await getFileFromAsset();

        // decode image and return new image
        img.Image? originalImage = img.decodeImage(File(xFile.path).readAsBytesSync());

        // watermark text
        String waterMarkText = "LatLng(30.6924784,76.8775464)";
        // add watermark to image and specify the position
        img.drawString(originalImage!, img.arial_14, 5, (originalImage.height - 100), waterMarkText, color: 0xffFF0000);

        // watermark text
        String waterMarkText2 = "Captured Angle (10 degree)";
        // add watermark to image and specify the position
        img.drawString(originalImage!, img.arial_14, 205, (originalImage.height - 100), waterMarkText2,
            color: 0xffFF0000);

        // create temporary directory on storage
        var tempDir = await getTemporaryDirectory();

        // generate random name
        Random _random = Random();
        String randomFileName = _random.nextInt(10000).toString();

        // store new image on filename
        File('${tempDir.path}/$randomFileName.png').writeAsBytesSync(img.encodePng(originalImage));

        // set watermarked image from image path
        File watermarkedImage = File('${tempDir.path}/$randomFileName.png');

        Uint8List? mapImage;

        await screenshotController.capture(delay: const Duration(milliseconds: 10)).then((capturedImage) async {
          mapImage = capturedImage;
          // ShowCapturedWidget(context, capturedImage!);
          print(" << SCREENSHOT CAPTURED >> ");
        }).catchError((onError) {
          print(onError);
        });

        // Navigate to Screen 2
        Navigator.push(context, MaterialPageRoute(builder: (context) => ImageScreen(watermarkedImage, mapImage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    if (_isCameraInitialized) {
      return SafeArea(
        child: Scaffold(
          body: Row(children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: /*Container(color: Colors.black)*/ CameraPreview(_controller!)),
            const SizedBox(width: 5),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // const SizedBox(width: 15),
                Screenshot(
                  controller: screenshotController,
                  child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      width: MediaQuery.of(context).size.width * 0.20,
                      child: const CircularMap())
                ),
                const SizedBox(height: 8),
                // Container(
                //     height: 100,
                //     width: 100,
                //     child: TabBar(controller: _tabController, tabs: const [
                //       Tab(text: 'Camera'),
                //       Tab(text: 'Video'),
                //     ])),
                // const SizedBox(height: 2),
                // TabBarView(
                //   controller: _tabController,
                //   children: const [
                //     Center(child: Text('Tab 1 Content')),
                //     Center(child: Text('Tab 2 Content'))
                //   ]
                // ),

                // give the tab bar a height [can change height to preferred height]
               /* Container(
                    height: 15,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(25.0)),
                    child: TabBar(
                        controller: _tabController,
                        // give the indicator a decoration (color and border radius)
                        indicator: BoxDecoration(borderRadius: BorderRadius.circular(25.0), color: Colors.green),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black,
                        tabs: const [
                          // first tab [you can add an icon using the icon property]
                          Tab(text: 'A'),
                          // second tab [you can add an icon using the icon property]
                          Tab(text: 'B')
                        ])),*/

                // Camera Button
                Visibility(
                    visible: true, //!(_heading.toInt() <= 100 || _heading.toInt() >= 150),
                    replacement: SizedBox(height: MediaQuery.of(context).size.height * 0.25, width: 70),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.18,
                      child: ElevatedButton(
                          onPressed: onTakePhotoPressed,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              fixedSize: const Size(70, 70),
                              shape: const CircleBorder(),
                              backgroundColor: Colors.white),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 30)),
                    )),
              ],
            )
          ]),
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
    final CameraController cameraController =
        CameraController(description, ResolutionPreset.high, imageFormatGroup: ImageFormatGroup.jpeg);

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
