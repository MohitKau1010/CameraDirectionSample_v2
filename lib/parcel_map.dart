import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'atom_api.dart';

// AIzaSyB1TDvuhR4D3wGte6WgAlhCOglbB-mh-cQ  API KEY
// AIzaSyAoxAmYdOyrhIvBmp-15uZhRrMRELNmcE8  API KEY

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late GoogleMapController mapController;
  final locationController = Location();
  LatLng? currentPosition;
  late Future<Map<String, dynamic>> _data;
  static const googlePlex = LatLng(30.693690, 76.879999);
  static const mountainView = LatLng(37.3861, -122.0839);
  Map<PolylineId, Polyline> polylines = {};
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Set<Polygon> _polygons = {};
  late Marker marker;

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initializeMap());
    _fetchData();
  }

  Future<void> _fetchData() async {
    final api = AttomApi();
    setState(() {
      _data = api.fetchData();
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: currentPosition == null
  //           ? const Center(child: CircularProgressIndicator())
  //           : GoogleMap(
  //       mapType: MapType.hybrid,
  //       initialCameraPosition: _kGooglePlex,
  //       onMapCreated: (GoogleMapController controller) {
  //         _controller.complete(controller);
  //       },
  //       markers: {
  //       Marker(
  //         markerId: const MarkerId('currentLocation'),
  //         icon: BitmapDescriptor.defaultMarker,
  //         position: currentPosition!,
  //       ),
  //       const Marker(
  //         markerId: MarkerId('sourceLocation'),
  //         icon: BitmapDescriptor.defaultMarker,
  //         position: googlePlex,
  //       ),
  //       const Marker(
  //         markerId: MarkerId('destinationLocation'),
  //         icon: BitmapDescriptor.defaultMarker,
  //         position: mountainView,
  //       )
  //     },
  //     polylines: Set<Polyline>.of(polylines.values),
  //   ),
  //
  //     // floatingActionButton: FloatingActionButton.extended(
  //     //   onPressed: _goToTheLake,
  //     //   label: const Text('To the lake!'),
  //     //   icon: const Icon(Icons.directions_boat),
  //     // ),
  //   );
  // }

  Future<void> _goToTheLake() async {
    final GoogleMapController mapController = await _controller.future;
    await mapController.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<void> initializeMap() async {
    await fetchLocationUpdates();
    final coordinates = await fetchPolylinePoints();
    generatePolyLineFromPoints(coordinates);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: currentPosition == null
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                mapType: MapType.satellite,
                initialCameraPosition: CameraPosition(target: currentPosition!, zoom: 19.5),
                markers: {

                  Marker(
                    markerId: const MarkerId('currentLocation'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: currentPosition!,
                  ),

                  // const Marker(
                  //   markerId: MarkerId('sourceLocation'),
                  //   icon: BitmapDescriptor.defaultMarker,
                  //   position: googlePlex,
                  // ),
                  // const Marker(
                  //   markerId: MarkerId('destinationLocation'),
                  //   icon: BitmapDescriptor.defaultMarker,
                  //   position: mountainView,
                  // )
                },
                // polylines: Set<Polyline>.of(polylines.values),
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                  _addCustomMarker(currentPosition!, 45.0); // Add marker at a specific location with a direction of 45 degrees
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
                },
                polygons: _polygons,
              ),
      );

  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );

          // currentPosition = const LatLng(
          //   37.7749,
          //   -122.4194,
          // );
        });
      }
    });
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final polylinePoints = PolylinePoints();

    final result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyCbAq1UtzoUlVx4djUkuETaRur7X4TEel4",
      PointLatLng(googlePlex.latitude, googlePlex.longitude),
      PointLatLng(mountainView.latitude, mountainView.longitude),
    );

    if (result.points.isNotEmpty) {
      return result.points.map((point) => LatLng(point.latitude, point.longitude)).toList();
    } else {
      debugPrint(">> ${result.errorMessage}");
      return [];
    }
  }


  // Function to add a custom marker with a specific direction
  void _addCustomMarker(LatLng location, double direction) {
    // Load the custom arrow image
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      'assets/img/arrow.png',
    ).then((BitmapDescriptor icon) {
      // Create a marker
      marker = Marker(
        markerId: const MarkerId('custom_marker'),
        position: location,
        icon: icon,
        rotation: direction, // Set rotation angle for the marker icon
      );

      // Add the marker to the map
      // mapController.addMarker(marker);
    });
  }


  Future<void> generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    const id = PolylineId('polyline');

    final polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 5,
    );

    // setState(() => polylines[id] = polyline);
  }
}
