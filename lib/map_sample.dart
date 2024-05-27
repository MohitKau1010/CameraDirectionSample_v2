import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:compass/camera_with_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:point_in_polygon/point_in_polygon.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Google Maps Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: MapScreen(),
//     );
//   }
// }

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController? mapController = null;
  late LocationData? _currentLocation = null;
  double compassHeading = 0.0;
  double _tilt = 0.0;
  final Set<Marker> _markers = {}; // Define a set to hold the markers..
  final Set<Polygon> _polygons = {};
  double _heading = 0;
  bool isStopped = false;
  bool captureImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    getLocation();
    _getCompassHeading();
    FlutterCompass.events?.listen(_onData);
    // Listen to accelerometer events
    accelerometerEvents.listen((event) {
      // Calculate the tilt angle based on accelerometer data
      double angle = atan(event.x / sqrt(event.y * event.y + event.z * event.z));
      setState(() {
        // Convert radians to degrees
        _tilt = angle * (180 / pi);
      });
    });
  }

  // Function to check if a point is inside the polygon
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    List<List<double>> convertedPolygon = polygon.map((LatLng latLng) => [latLng.latitude, latLng.longitude]).toList();
    return Poly.isPointInPolygon(
        Point(y: _currentLocation?.latitude ?? 0.0, x: _currentLocation?.longitude ?? 0.0), <Point>[
      Point(y: 30.693700, x: 76.880371), //30.693700, 76.880371 corner
      Point(y: 30.693683, x: 76.880015), //30.693683, 76.880015 gate 1
      Point(y: 30.692840, x: 76.879868), //30.692840, 76.879868 transformer
      Point(y: 30.692838, x: 76.880331), //30.692838, 76.880331 gate 2
    ]);
  }

  void _onData(CompassEvent x) {
    setState(() {});

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == 'custom_marker');
    });

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == 'custom_marker');
    });

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == 'custom_marker');
    });

    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(0, 0)),
      'assets/img/dot_dot.png',
    ).then((BitmapDescriptor icon) {
      // Create a marker
      Marker marker = Marker(
        markerId: const MarkerId('custom_marker'),
        position: LatLng(_currentLocation?.latitude ?? 0.0, _currentLocation?.longitude ?? 0.0),
        // icon: icon,
        // anchor: const Offset(0.1, 0.1),
        // rotation: _heading, // Set rotation angle for the marker icon
      );

      if (_heading != 0.0) {
        setState(() {
          _markers.add(marker); // Add the marker to the set
        });
        /*if(_heading>=100 || _heading<=150){
          captureImage = true;
        }else{
          captureImage = false;
        }*/
      }

      ///
      setState(() {
        _heading = x.heading!;
        // Reset camera heading to north when FAB is pressed
        if (mapController != null) {
          mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
              target: LatLng(_currentLocation?.latitude ?? 0.0, _currentLocation?.longitude ?? 0.0),
              zoom: 19.0,
              bearing: _heading, // Reset to north
              tilt: _tilt)));
        } else {}
      });
    });
  }

  // // Function to get the current device location
  // _getLocation() async {
  //   var location = Location();
  //   try {
  //     var userLocation = await location.getLocation();
  //     setState(() {
  //       currentLocation = userLocation;
  //     });
  //   } catch (e) {
  //     print("Failed to get location: $e");
  //   }
  // }

  // Function to get the current location
  Future<void> getLocation() async {
    _markers.add(const Marker(
      markerId: MarkerId('custom_marker1'),
      position: LatLng(30.693683, 76.880015),
    ));

    Location location = Location();

    // Request high accuracy
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Request permission
    PermissionStatus permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        return;
      }
    }

    // Set location options
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 500, // Update interval in milliseconds - 1000
      distanceFilter: 2, // Minimum distance for location change in meters - 10
    );

    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentLocation = currentLocation;
        isStopped = false;
      });
    });

    setState(() {});

    try {
      _currentLocation = await location.getLocation();
    } catch (e) {
      print("Unable to get location: $e");
    }
  }

  // Function to get the current device compass heading
  _getCompassHeading() {
    FlutterCompass.events?.listen((event) {
      setState(() {
        compassHeading = event.heading!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lock the orientation to portrait mode
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
    // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp], );

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Capture between 100 - 150'),
      // ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Visibility(
            visible: _currentLocation != null,
            replacement: const Center(child: CircularProgressIndicator()),
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                  target: LatLng(_currentLocation?.latitude ?? 0.0, _currentLocation?.longitude ?? 0.0),
                  // Default center (e.g., San Francisco)
                  zoom: 19.0),
              compassEnabled: false,
              // Disable default compass
              myLocationButtonEnabled: false,
              // myLocationEnabled: true,
              rotateGesturesEnabled: false,
              // Disable manual rotation gestures
              tiltGesturesEnabled: false,
              // Disable manual tilt gestures
              onMapCreated: (GoogleMapController controller) {
                setState(() {
                  mapController = controller;
                });

                setState(() {
                  _polygons.add(
                    Polygon(
                      polygonId: const PolygonId("polygon_1"),
                      points: const [
                        LatLng(30.693700, 76.880371), //30.693700, 76.880371 corner
                        LatLng(30.693683, 76.880015), //30.693683, 76.880015 gate 1
                        LatLng(30.692840, 76.879868), //30.692840, 76.879868 transformer
                        LatLng(30.692838, 76.880331), //30.692838, 76.880331 gate 2
                      ],
                      strokeWidth: 5,
                      strokeColor: Colors.green,
                      fillColor: Colors.green.withOpacity(0.5),
                    ),
                  );
                });

                // _addCustomMarker(LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0), _heading); // Add marker at a specific location with a direction of 45 degrees
              },

              /// myLocationEnabled: true,
              markers: _markers,
              // Set the markers to be displayed on the map
              polygons: _polygons,
            ),
          ),
          if (_currentLocation != null)
            /// LOCATION BUTTON
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  /*mapController.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0), zoom: 18.0),
                  ));*/

                  // Reset camera heading to north when FAB is pressed
                  mapController!.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(_currentLocation?.latitude ?? 0.0, _currentLocation?.longitude ?? 0.0),
                        zoom: 15.0,
                        bearing: _heading, // Reset to north
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.location_searching),
              ),
            ),

          if (_currentLocation != null /*&& isPointInPolygon == false*/)
          /// LOCATION BUTTON
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Transform.rotate(
                angle: compassHeading * (3.1415927 / 180),
                child: FloatingActionButton(
                  heroTag: "btn1",
                  onPressed: () {},
                  child: const Icon(Icons.navigation),
                ),
              ),
            ),

          /// CAMERA BUTTON
          Positioned(
            bottom: 16.0,
            left: 180.0,
            child: FloatingActionButton(
              heroTag: "btn2",
              onPressed: () {
                // mapController.animateCamera(CameraUpdate.newCameraPosition(
                //   CameraPosition(
                //     target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
                //     zoom: 18.0,
                //   ),
                // ));
                // Navigate to the second screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraWithCompass()),
                );
              },
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }

  // Function to add a custom marker with a specific direction
  void _addCustomMarker(LatLng location, double direction) {
    // Load the custom arrow image
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(2, 2)), 'assets/img/arrow.png')
        .then((BitmapDescriptor icon) {
      // Create a marker
      Marker marker = Marker(
        markerId: const MarkerId('custom_marker'),
        position: location,
        icon: icon,
        rotation: direction, // Set rotation angle for the marker icon
      );

      setState(() {
        _markers.add(marker); // Add the marker to the set
      });
    });
  }
}
