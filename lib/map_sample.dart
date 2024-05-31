import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:compass/test_add_polygons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:compass/camera_with_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
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
  final _formKey = GlobalKey<FormState>();
  double distanceInMeters = 0.0;
  String displayText = "";
  bool showPopUi = false;
  bool reached = false;
  final Set<Marker> _markers = {}; // Define a set to hold the markers..
  final Set<Polygon> _polygons = {};

  // for getting inside polygon or not
  late Point currentPoint;
  final List<LatLng> _polygonsPoints = const [
    LatLng(30.693700, 76.880371), // 30.693700, 76.880371 corner
    LatLng(30.693683, 76.880015), // 30.693683, 76.880015 gate 1
    LatLng(30.692840, 76.879868), // 30.692840, 76.879868 transformer
    LatLng(30.692838, 76.880331), // 30.692838, 76.880331 gate 2
  ];

  final List<Point> points = <Point>[
    Point(y: 30.693700, x: 76.880371),
    Point(y: 30.693683, x: 76.880015),
    Point(y: 30.692840, x: 76.879868),
    Point(y: 30.692838, x: 76.879868),
  ];

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
    if (Platform.isIOS) {
      location_permission();
    }
    getLocation();
    _getCompassHeading();
    FlutterCompass.events?.listen(_onData);
    // Listen to accelerometer events
    accelerometerEvents.listen((event) {
      // Calculate the tilt angle based on accelerometer data
      double angle = atan(event.x / sqrt(event.y * event.y + event.z * event.z));
      // if (MediaQuery.of(context).orientation == Orientation.portrait) {
      //   // Portrait mode
      //   angle = atan2(event.y, event.z);
      // } else {
      //   // Landscape mode
      //   angle = atan2(event.x, event.z);
      // }
      if (this.mounted) {
        setState(() {
          // Convert radians to degrees
          _tilt = angle * (180 / pi);
        });
      }

      if(_currentLocation!=null){
        setState(() {
          distanceInMeters = geo.Geolocator.distanceBetween(
              _currentLocation!.latitude ?? 0.0, _currentLocation!.longitude ?? 0.0, 30.693683, 76.880015);
          print(">>> distanceInMeters >> ${distanceInMeters.toInt()}");
          if (distanceInMeters.toInt() <= 5) {
            setState(() {
              showPopUi = (reached == false) ? true : false;
            });
          }
          currentPoint = Point(x: _currentLocation!.latitude ?? 0.0, y: _currentLocation!.longitude ?? 0.0);
          if(Poly.isPointInPolygon(currentPoint, points)){
            displayText = "You are in the Lot :) ";
          }else{
            displayText = "Outside the lot make sure. :( Please make sure your lot number."; // true
          }
        });
      }

    });
  }

  // Function to check if a point is inside the polygon
  // bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  //   List<List<double>> convertedPolygon = polygon.map((LatLng latLng) => [latLng.latitude, latLng.longitude]).toList();
  //   return Poly.isPointInPolygon(
  //       Point(y: _currentLocation?.latitude ?? 0.0, x: _currentLocation?.longitude ?? 0.0), <Point>[
  //     Point(y: 30.693700, x: 76.880371), //30.693700, 76.880371 corner
  //     Point(y: 30.693683, x: 76.880015), //30.693683, 76.880015 gate 1
  //     Point(y: 30.692840, x: 76.879868), //30.692840, 76.879868 transformer
  //     Point(y: 30.692838, x: 76.880331), //30.692838, 76.880331 gate 2
  //   ]);
  // }

  void _onData(CompassEvent x) {
    setState(() {
      // double distanceInMeters = await geo.Geolocator().distanceBetween(lat1, lng1, lat2, lng2);
    });

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == 'custom_marker2');
    });

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == 'custom_marker');
    });

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == 'custom_marker');
    });

    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(2, 2)),
      'assets/img/dot_dot.png',
    ).then((BitmapDescriptor icon) {
      // Create a marker
      Marker marker = Marker(
        markerId: const MarkerId('custom_marker2'),
        position: LatLng(_currentLocation?.latitude ?? 0.0, _currentLocation?.longitude ?? 0.0),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        rotation: _heading/180, // Set rotation angle for the marker icon
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
        // Reset camera heading to north when FAB is pressed..
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

  // // Function to get the current device location..
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp], );
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
            onTap: () {
              showPopUi = true;
              setState(() {});
            },
            child: Text('${distanceInMeters.toInt()} meters away')),
      ),
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
                      points: _polygonsPoints,
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

            /// CURRENT LOCATION BUTTON
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
                        zoom: 19.0,
                        bearing: _heading, // Reset to north
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.location_searching),
              ),
            ),

          /// Draw Lot/Parcel
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              heroTag: "btn1",
              onPressed: () async {
                // Navigate to the second screen..
                List<LatLng>  result = await Navigator.push(
                    context, MaterialPageRoute(builder: (context) => DrawPolygon(_currentLocation, _polygonsPoints)));
                if (result != null ) {
                  _polygonsPoints.clear();
                  _polygonsPoints.addAll(result);
                  setState(() {
                    _polygons.clear();
                    _polygons.add(
                      Polygon(
                        polygonId: const PolygonId("polygon_1"),
                        points: _polygonsPoints,
                        strokeWidth: 5,
                        strokeColor: Colors.green,
                        fillColor: Colors.green.withOpacity(0.5),
                      ),
                    );
                  });
                }
                // Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result"),duration: const Duration(seconds: 3),));
              },
              child: const Icon(Icons.add),
            ),
          ),

          // if (_currentLocation != null /*&& isPointInPolygon == false*/)
          /// LOCATION BUTTON
          /*Positioned(
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
            ),*/

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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraWithCompass()));
              },
              child: const Icon(Icons.camera_alt),
            ),
          ),

          /*if (showPopUi == true)*/ popupUI(context),
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

  popupUI(BuildContext context) {
    // setState(() {
    //   reached = false;
    // });
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              showPopUi = false;
              reached = true;
            });
            setState(() {});
          },
          child: Container(
              height: MediaQuery.of(context).size.height * 0.05,
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.only(top: 20.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2.0),
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  color: Colors.yellow),
              child: Center(
                  child: Text(displayText,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)))),
        ),
      ],
    );
  }

  void location_permission() async {
    // final PermissionStatus permission = await _getLocationPermission();
    // if (permission == PermissionStatus.granted) {
    //   final position = await geolocator.getCurrentPosition(
    //       desiredAccuracy: LocationAccuracy.best);
    //
    //   // Use the position to do whatever...
    // }
  }

  /*Future<PermissionStatus> _getLocationPermission() async {
    final PermissionStatus permission = await LocationPermissions()
        .checkPermissionStatus(level: LocationPermissionLevel.location);

    if (permission != PermissionStatus.granted) {
      final PermissionStatus permissionStatus = await LocationPermissions()
          .requestPermissions(
          permissionLevel: LocationPermissionLevel.location);

      return permissionStatus;
    } else {
      return permission;
    }
  }*/
}
