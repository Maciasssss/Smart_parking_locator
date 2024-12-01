import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class EditParkingMarkerScreen extends StatefulWidget {
  final String markerId;
  final latLng.LatLng position;

  const EditParkingMarkerScreen({super.key, required this.markerId, required this.position});

  @override
  _EditParkingMarkerScreenState createState() =>
      _EditParkingMarkerScreenState();
}

class _EditParkingMarkerScreenState extends State<EditParkingMarkerScreen> {
  final List<Marker> _carIcons = []; // Store placed car icons
  final MapController _mapController = MapController();
  bool _isMapReady = false; 

  @override
  void initState() {
    super.initState();

    // Ensure map initialization is deferred
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isMapReady = true;
      });

      _mapController.move(widget.position, 14.0);
    });
  }

  void _addCarIcon(latLng.LatLng position) {
    Marker carMarker = Marker(
      point: position,
      child: const Icon(Icons.directions_car, color: Colors.blue),
      width: 30,
      height: 30,
    );

    setState(() {
      _carIcons.add(carMarker); 
    });
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Parking Marker'),
      ),
      body: _isMapReady
          ? FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                onTap: (tapPosition, point) {
                  _addCarIcon(point);
                },
              ),
              children: [
                TileLayer(
                  tileProvider: const FMTCStore('mapStore').getTileProvider(),
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.position,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                      width: 40,
                      height: 40,
                    ),
                    ..._carIcons,
                  ],
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ), 
    );
  }
}
