import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class EditParkingMarkerScreen extends StatefulWidget {
  final String markerId;
  final gmaps.LatLng position;

  EditParkingMarkerScreen({required this.markerId, required this.position});

  @override
  _EditParkingMarkerScreenState createState() => _EditParkingMarkerScreenState();
}

class _EditParkingMarkerScreenState extends State<EditParkingMarkerScreen> {
  List<gmaps.Marker> _carIcons = []; // Store placed car icons

  void _addCarIcon(gmaps.LatLng position) {
    String carId = DateTime.now().millisecondsSinceEpoch.toString();
    gmaps.Marker carMarker = gmaps.Marker(
      markerId: gmaps.MarkerId(carId),
      position: position,
      infoWindow: gmaps.InfoWindow(title: 'Car'),
    );

    setState(() {
      _carIcons.add(carMarker); // Add the car icon to the list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Parking Marker'),
      ),
      body: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: widget.position,
          zoom: 14.0,
        ),
        markers: {..._carIcons, gmaps.Marker(
          markerId: gmaps.MarkerId(widget.markerId),
          position: widget.position,
          infoWindow: gmaps.InfoWindow(title: 'Parking Spot'),
        )}, // Include the parking marker
        onTap: (position) {
          _addCarIcon(position); // Add a car icon on tap
        },
      ),
    );
  }
}
