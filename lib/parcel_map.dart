import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// AIzaSyB1TDvuhR4D3wGte6WgAlhCOglbB-mh-cQ  API KEY
// AIzaSyAoxAmYdOyrhIvBmp-15uZhRrMRELNmcE8  API KEY


class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
    final locationController = Location();
  LatLng? currentPosition;
  static const googlePlex = LatLng(37.414350, -122.089364);
  static const mountainView = LatLng(37.3861, -122.0839);
    Map<PolylineId, Polyline> polylines = {};
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
    Set<Polygon> _polygons = {};
  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initializeMap());
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
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
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
      initialCameraPosition: const CameraPosition(
        target: googlePlex,
        zoom: 13,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('currentLocation'),
          icon: BitmapDescriptor.defaultMarker,
          position: currentPosition!,
        ),
        const Marker(
          markerId: MarkerId('sourceLocation'),
          icon: BitmapDescriptor.defaultMarker,
          position: googlePlex,
        ),
        const Marker(
          markerId: MarkerId('destinationLocation'),
          icon: BitmapDescriptor.defaultMarker,
          position: mountainView,
        )
      },
      polylines: Set<Polyline>.of(polylines.values),

      onMapCreated: (GoogleMapController controller) {
        setState(() {
          _polygons.add(
            Polygon(
              polygonId: const PolygonId("polygon_1"),
              points: const [
                LatLng(37.415817, -122.089571),
                LatLng(37.415964, -122.092781),
                LatLng(37.414534, -122.092596),
                LatLng(37.414350, -122.089364),
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
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          // currentPosition = LatLng(
          //   currentLocation.latitude!,
          //   currentLocation.longitude!,
          // );

          currentPosition = const LatLng(
            37.7749,
            -122.4194,
          );
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
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      debugPrint(">> ${result.errorMessage}");
      return [];
    }
  }

  Future<void> generatePolyLineFromPoints(
      List<LatLng> polylineCoordinates) async {
    const id = PolylineId('polyline');

    final polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 5,
    );

    setState(() => polylines[id] = polyline);
  }
}




