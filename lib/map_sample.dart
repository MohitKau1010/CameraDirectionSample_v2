import 'package:compass/camera_with_compass.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  late GoogleMapController mapController;
  late LocationData currentLocation;
  double compassHeading = 0.0;
  List<double> _magnetometerValues = [0.0, 0.0, 0.0];
  Set<Marker> _markers = {}; // Define a set to hold the markers
  Set<Polygon> _polygons = {};
  double _heading = 0;
  bool captureImage = false;

  @override
  void didChangeDependencies() {
    _getLocation();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    _getCompassHeading();
    FlutterCompass.events?.listen(_onData);
    // Listen to accelerometer events
    // Listen to magnetometer events
    magnetometerEvents.listen((MagnetometerEvent event) {
      setState(() {
        _magnetometerValues = [event.x, event.y, event.z];
      });
    });
  }

  void _onData(CompassEvent x) {
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
      const ImageConfiguration(size: Size(1, 1)),
      'assets/img/dot_dot.png',
    ).then((BitmapDescriptor icon) {
      // Create a marker
      Marker marker = Marker(
        markerId: const MarkerId('custom_marker'),
        position: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        rotation: _heading, // Set rotation angle for the marker icon
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
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
              zoom: 19.0,
              bearing: _heading, // Reset to north
              tilt: 90.0
            ),
          ),
        );
      });
    });
  }

  // Function to get the current device location
  _getLocation() async {
    var location = Location();
    try {
      var userLocation = await location.getLocation();
      setState(() {
        currentLocation = userLocation;
      });
    } catch (e) {
      print("Failed to get location: $e");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture between 100 - 150'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
              // Default center (e.g., San Francisco)
              zoom: 19.0,
            ),
            compassEnabled: false, // Disable default compass
            myLocationButtonEnabled: false,
            // myLocationEnabled: true,
            rotateGesturesEnabled: false, // Disable manual rotation gestures
            tiltGesturesEnabled: false, // Disable manual tilt gestures
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;


              setState(() {
                _polygons.add(
                  Polygon(
                    polygonId: const PolygonId("polygon_1"),
                    points: const [
                      LatLng(30.693690, 76.879999), //30.693690, 76.879999
                      LatLng(30.693704, 76.880370), //30.693704, 76.880370
                      LatLng(30.692839, 76.880332), //30.692839, 76.880332
                      LatLng(30.692848, 76.879868), //30.692848, 76.879868
                    ],
                    strokeWidth: 2,
                    strokeColor: Colors.blue,
                    fillColor: Colors.blue.withOpacity(0.5),
                  ),
                );
              });


              // _addCustomMarker(LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0), _heading); // Add marker at a specific location with a direction of 45 degrees
            },
            /// myLocationEnabled: true,
            markers: _markers, // Set the markers to be displayed on the map
            polygons: _polygons,
          ),
          if (currentLocation != null)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: FloatingActionButton(
                onPressed: () {
                  /*mapController.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0), zoom: 18.0),
                  ));*/
                  // Reset camera heading to north when FAB is pressed
                  mapController.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
                        zoom: 15.0,
                        bearing: _heading, // Reset to north
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.location_searching),
              ),
            ),
          if (currentLocation != null)
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Transform.rotate(
                angle: compassHeading * (3.1415927 / 180),
                child: FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.navigation),
                ),
              ),
            ),
          Positioned(
            bottom: 16.0,
            left: 180.0,
            child: FloatingActionButton(
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
                  MaterialPageRoute(builder: (context) => const CameraWithCompass()),
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
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(2, 2)),
      'assets/img/arrow.png',
    ).then((BitmapDescriptor icon) {
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
