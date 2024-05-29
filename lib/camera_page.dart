import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:compass/video_player_screen.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:http/http.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'circular_map.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'image_watermark/show_watermark.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:http/http.dart' as http;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  late TabController _tabController;
  GoogleMapController? mapController;

  // for
  bool _isCameraInitialized = false;
  late final List<CameraDescription> _cameras;
  bool _isRecording = false;

  // For getting head direction.
  double _heading = 0;
  int _activeTabIndex = 0;

  // Create an instance of ScreenshotController
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
    // within your initState() method
    _tabController.addListener(_setActiveTabIndex);

    _cameras = await availableCameras();
    // Initialize the camera with the first camera in the list
    await onNewCameraSelected(_cameras.first);
  }

  void _setActiveTabIndex() {
    setState(() {
      _activeTabIndex = _tabController.index;
    });
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
      // await cameraController.setFlashMode(FlashMode.off);
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

        img.Image fixedImage = originalImage!; //img.flipHorizontal(originalImage!);

        // watermark text
        String waterMarkText = "LatLng(30.6924784,76.8775464)";
        // add watermark to image and specify the position
        img.drawString(fixedImage!, img.arial_14, 5, (fixedImage.height - 100), waterMarkText, color: 0xffFF0000);

        // watermark text
        String waterMarkText2 = "Captured Angle (10 degree)";
        // add watermark to image and specify the position
        img.drawString(fixedImage, img.arial_14, 205, (fixedImage.height - 100), waterMarkText2, color: 0xffFF0000);

        // create temporary directory on storage
        var tempDir = await getTemporaryDirectory();

        /// tempDir >> iOS Path "/var/mobile/Containers/Data/Application/7AD051AD-67E4-470F-9F78-0CAF264E7F99/Library/Caches"

        // generate random name
        Random _random = Random();
        String randomFileName = _random.nextInt(10000).toString();

        // store new image on filename
        File('${tempDir.path}/$randomFileName.png').writeAsBytesSync(
          // img.encodePng(originalImage),
          img.encodeJpg(fixedImage),
          flush: true,
        );

        // set watermarked image from image path
        File watermarkedImage = File('${tempDir.path}/$randomFileName.png');

        Uint8List? mapImage;

        // if(Platform.isIOS){
        //   const String apiKey = 'AIzaSyB1TDvuhR4D3wGte6WgAlhCOglbB-mh-cQ';
        //   var latitude ='30.6924738';
        //   var longitude = 'https://www.google.com/maps/place/TeQ+Mavens/@30.6924738,,17z/data=!3m1!4b1!4m14!1m7!3m6!1s0x390f951666fd58cb:0x8870b09d27543cf8!2sTeQ+Mavens!8m2!3d30.6924738!4d76.8801213!16s%2Fg%2F11h0ml7xn5!3m5!1s0x390f951666fd58cb:0x8870b09d27543cf8!8m2!3d30.6924738!4d76.8801213!16s%2Fg%2F11h0ml7xn5?entry=ttu';
        //   final String url = 'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=14&size=600x300&maptype=roadmap&key=$apiKey';
        //
        //   final http.Response response = await http.get(Uri.parse(url));
        //   if (response.statusCode == 200) {
        //     mapImage = response.bodyBytes;
        //   } else {
        //     throw Exception('Failed to load Google Map');
        //   }
        // }

        await screenshotController.capture(delay: const Duration(milliseconds: 10)).then((capturedImage) async {

          // Uint8List test = await mapController?.takeSnapshot() as Uint8List;
          // print(" << takeSnapshot >> path : $test");

          mapImage = capturedImage;
          // ShowCapturedWidget(context, capturedImage!);
          print(" << WATER_MARKED CAPTURED >> path : $watermarkedImage");
          print(" << SCREENSHOT CAPTURED >> path : $mapImage");
        }).catchError((onError) {
          print(onError);
        });

        // Navigate to Screen 2..
        Navigator.push(context, MaterialPageRoute(builder: (context) => ImageScreen(watermarkedImage, mapImage!)));
      }
    }
  }

  void takeSnapShot() async {
    // GoogleMapController controller = await _mapController.future;
    // Future<void>.delayed(const Duration(milliseconds: 1000), () async {
    //   imageBytes = await controller.takeSnapshot();
    //   setState(() {});
    // });
  }

  @override
  Widget build(BuildContext context) {
    // var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    if (_isCameraInitialized) {
      return SafeArea(
          child: Scaffold(
              body: Stack(children: [
        OrientationBuilder(builder: (_, orientation) {
          if (orientation == Orientation.portrait) {
            // Portrait MODE
            return portraitView(context);
          } else {
            // Landscape MODE
            return landscapeView(context);
          }
        }),
        // Compass(),
      ])));
    } else {
      return Container(color: Colors.black);
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

  Widget portraitView(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.71,
              child: /*Container(color: Colors.blue)*/ CameraPreview(_controller!)),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // const SizedBox(width: 15),
              /// Map View
              Screenshot(
                  controller: screenshotController,
                  child: Container(
                      height: MediaQuery.of(context).size.height * 0.23,
                      width: MediaQuery.of(context).size.width * 0.45,
                      color: Colors.white,
                      child: CircularMap(mapController))),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Give the tab bar a height [can change height to preferred height]
                  Container(
                      height: MediaQuery.of(context).size.height * 0.04,
                      width: MediaQuery.of(context).size.width * 0.44,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15.0)),
                      child: TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          // give the indicator a decoration (color and border radius)
                          // indicator: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.green),
                          labelColor: Colors.green,
                          labelPadding: const EdgeInsets.only(left: 10, right: 10),
                          unselectedLabelColor: Colors.black,
                          indicatorSize: TabBarIndicatorSize.label,
                          padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 2.0, bottom: 2.0),
                          tabs: const [
                            // First tab [you can add an icon using the icon property]
                            Tab(text: 'Image'),
                            // Second tab [you can add an icon using the icon property]
                            Tab(text: 'Video')
                          ])),

                  // Camera Button
                  Visibility(
                      visible: _activeTabIndex == 0,
                      // !(_heading.toInt() <= 100 || _heading.toInt() >= 150),
                      replacement: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.16,
                          child: ElevatedButton(
                              onPressed: () async {
                                if (!_isRecording) {
                                  XFile? file = await captureVideo();
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoFile: file!)));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  fixedSize: const Size(70, 70),
                                  shape: const CircleBorder(),
                                  backgroundColor: Colors.white),
                              child: Icon(Icons.video_camera_back_outlined,
                                  color: (_isRecording == true) ? Colors.red : Colors.black, size: 30))),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.16,
                        child: ElevatedButton(
                            onPressed: onTakePhotoPressed,
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                fixedSize: const Size(70, 70),
                                shape: const CircleBorder(),
                                backgroundColor: Colors.white),
                            child: const Center(child: Icon(Icons.camera_alt, color: Colors.black, size: 30))),
                      )),
                ],
              )
            ],
          ),
        ]);
  }

  Widget landscapeView(BuildContext context) {
    return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.5,
              child: /*Container(color: Colors.lightBlueAccent) */ CameraPreview(_controller!)),
          const SizedBox(width: 5),
          Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // const SizedBox(width: 15),
                Screenshot(
                    controller: screenshotController,
                    child: Container(
                        height: MediaQuery.of(context).size.height * 0.55,
                        width: MediaQuery.of(context).size.width * 0.25,
                        color: Colors.white,
                        child: CircularMap(mapController))),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.31,
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: Column(
                    children: [
                      // Give the tab bar a height [can change height to preferred height]
                      Container(
                          height: MediaQuery.of(context).size.height * 0.09,
                          width: MediaQuery.of(context).size.width * 0.20,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15.0)),
                          child: TabBar(
                              controller: _tabController,
                              dividerColor: Colors.transparent,
                              // give the indicator a decoration (color and border radius)
                              // indicator: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: Colors.green),
                              labelColor: Colors.green,
                              labelPadding: EdgeInsets.only(left: 10, right: 10),
                              unselectedLabelColor: Colors.black,
                              indicatorSize: TabBarIndicatorSize.label,
                              padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 2.0, bottom: 2.0),
                              tabs: const [
                                // First tab [you can add an icon using the icon property]
                                Tab(text: 'Image'),
                                // Second tab [you can add an icon using the icon property]
                                Tab(text: 'Video')
                              ])),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      // Camera Button
                      Visibility(
                          visible: _activeTabIndex == 0,
                          // !(_heading.toInt() <= 100 || _heading.toInt() >= 150),
                          replacement: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2,
                            child: ElevatedButton(
                                onPressed: () async {
                                  if (!_isRecording) {
                                    XFile? file = await captureVideo();
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoFile: file!)));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    fixedSize: const Size(70, 70),
                                    shape: const CircleBorder(),
                                    backgroundColor: Colors.white),
                                child: Icon(Icons.video_camera_back_outlined,
                                    color: (_isRecording == true) ? Colors.red : Colors.black, size: 30)),
                          ),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2,
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
                  ),
                )
              ])
        ]);
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
            ? Image.file(File(widget.imagePath ?? ""), fit: BoxFit.cover)
            : AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!)),
      ),
    );
  }
}
