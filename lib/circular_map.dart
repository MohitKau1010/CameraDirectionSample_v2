import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
// import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'image_watermark/show_watermark.dart';


class CircularMap extends StatefulWidget {
  GoogleMapController? mapController;

  CircularMap(this.mapController, {super.key});

  @override
  State<CircularMap> createState() => _CircularMapState();
}

class _CircularMapState extends State<CircularMap> {


  late LocationData? currentLocation = null;
  double compassHeading = 0.0;
  double _tilt = 0.0;
  final Set<Marker> _markers = {}; // Define a set to hold the markers..
  final Set<Polygon> _polygons = {};
  double _heading = 0;
  bool captureImage = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    _getCompassHeading();
    FlutterCompass.events?.listen(_onData);
    // Listen to accelerometer events.
    accelerometerEvents.listen((event) {
      // Calculate the tilt angle based on accelerometer data.
      double angle = atan(event.x / sqrt(event.y * event.y + event.z * event.z));
      // setState(() {
        // Convert radians to degrees
        _tilt = angle * (180 / pi);
      // });
    });
  }

  void _onData(CompassEvent x) {
    // setState(() {
    //   _markers.removeWhere((marker) => marker.markerId == 'custom_marker');
    // });

    // setState(() {
    //   _markers.removeWhere((marker) => marker.markerId == 'custom_marker');
    // });

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
        position: LatLng(currentLocation?.latitude ?? 0.0, currentLocation?.longitude ?? 0.0),
        // icon: icon,
        // anchor: const Offset(0.5, 0.5),
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

      setState(() {
        _heading = x.heading!;
        // Reset camera heading to north when FAB is pressed
        if(widget.mapController!=null){
          widget.mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(currentLocation?.latitude ?? 0.0, currentLocation?.longitude ?? 0.0),
                zoom: 17.5,
                bearing: _heading, // Reset to north
                tilt: _tilt,
              ),
            ),
          );
        }

      });
    });

  }

  // Function to get the current device location
  _getLocation() async {
    var location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    try {
      var userLocation = await location.getLocation();
      setState(() {
        currentLocation = userLocation;
      });
      setState(() {});
    } catch (e) {
      print("Failed to get location: $e");
    }
  }

  // Function to get the current device compass heading
  _getCompassHeading() {
    FlutterCompass.events?.listen((event) {
      // setState(() {
        compassHeading = event.heading!;
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: currentLocation!=null,
      replacement: const Center(child: CircularProgressIndicator()),
      child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(currentLocation?.latitude ?? 0.0, currentLocation?.longitude ?? 0.0),
            // Default center (e.g., San Francisco)
            zoom: 17.5, // Reset to north
          ),
          compassEnabled: true, // Disable default compass
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          mapToolbarEnabled: false,
          liteModeEnabled: false,
          zoomControlsEnabled: false,
          rotateGesturesEnabled: false, // Disable manual rotation gestures
          tiltGesturesEnabled: false, // Disable manual tilt gestures
          onMapCreated: (GoogleMapController controller) {
            widget.mapController = controller;

            setState(() {});

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
    );
  }
}
