import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

class DrawPolygon extends StatefulWidget {
  List<LatLng> polygonsPoints;
  LocationData? currentLocation;

  DrawPolygon(this.currentLocation, this.polygonsPoints);

  @override
  _DrawPolygonState createState() => _DrawPolygonState();
}

class _DrawPolygonState extends State<DrawPolygon> {
  GoogleMapController? mapController;
  List<LatLng> polygonLatLngs = [];
  Set<Polygon> polygons = {};

  @override
  void initState() {
    // polygonLatLngs = widget.polygonsPoints;
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

  }

  void _onTap(LatLng latLng) {
    setState(() {
      polygonLatLngs.add(latLng);
      if (polygonLatLngs.length >= 3) {
        polygons.add(
          Polygon(
            polygonId: const PolygonId('polygon_1'),
            points: polygonLatLngs,
            strokeWidth: 2,
            strokeColor: Colors.red,
            fillColor: Colors.red.withOpacity(0.15),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Draw Parcel on Map')),
        body: Stack(children: [

          GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                  target: LatLng(widget.currentLocation!.latitude ?? 0.0, widget.currentLocation!.longitude ?? 0.0),
                  // San Francisco coordinates
                  zoom: 19),
              onTap: _onTap,
              polygons: polygons),

          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    polygonLatLngs.clear();
                    polygons.clear();
                  });
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.clear)),
          ),

          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              heroTag: "btn1",
              backgroundColor: Colors.green,
              onPressed: () async {
                Navigator.pop(context,polygonLatLngs);

                // Navigate to the second screen..
                // if(result!=null){
                //   _polygonsPoints.clear();
                //   _polygonsPoints.addAll(result);
                // }
                // Scaffold.of(context).showSnackBar(SnackBar(content: Text("$result"),duration: const Duration(seconds: 3),));
              },
              child: const Icon(Icons.done),
            ),
          ),

        ]));
    // var result = await Navigator.push(context, MaterialPageRoute(builder: (context) => DrawPolygon(_currentLocation,_polygonsPoints)));
  }
}
