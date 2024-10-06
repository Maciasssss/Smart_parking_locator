import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';
import 'package:smart_parking_locator/screens/parking_reservation_screen.dart';
import '../providers/parking_spot_provider.dart';
import '../models/parking_spot.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _markers = {}; // Store markers

  void _addMarker(gmaps.LatLng position) {
    String markerId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create a ParkingSpot object
    ParkingSpot newSpot = ParkingSpot(
      id: markerId,
      name: 'Parking Area $markerId',
      positionLat: position.latitude,
      positionLng: position.longitude,
      carPositions: [], // Initially empty
    );

    // Use the provider to save the parking spot
    Provider.of<ParkingSpotProvider>(context, listen: false).saveParkingSpot(newSpot);
    
    setState(() {
      _markers.add(gmaps.Marker(
        markerId: gmaps.MarkerId(markerId),
        position: position,
        infoWindow: gmaps.InfoWindow(
          title: 'Parking Area $markerId',
          onTap: () {
            // Navigate to the reservation screen when the marker is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ParkingReservationCreationScreen(markerId: markerId),
              ),
            );
          },
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(37.7749, -122.4194), // Example location
          zoom: 14.0,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers, // Display the markers on the map
        onTap: (position) {
          _addMarker(position); // Add a marker on map tap
        },
      ),
    );
  }
}
