import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/parking_spot_provider.dart'; // Ensure correct import
import '../screens/login_screen.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  gmaps.GoogleMapController? _mapController;
  gmaps.LatLng _currentPosition = gmaps.LatLng(37.7749, -122.4194);
  Set<gmaps.Marker> _markers = {};
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMarkers();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = gmaps.LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(_currentPosition, 14.0));
    });
  }

  Future<void> _loadMarkers() async {
    final parkingAreas = await Provider.of<ParkingSpotProvider>(context, listen: false).fetchParkingAreas();
    
    // Update to use the model correctly
    Set<gmaps.Marker> markers = parkingAreas.map((area) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(area.id),
        position: gmaps.LatLng(area.positionLat, area.positionLng), // Ensure the right position attributes
        icon: gmaps.BitmapDescriptor.defaultMarker,
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Locator'),
        actions: [
          if (_isAdmin == false) // Show login button for non-admins
            IconButton(
              icon: Icon(Icons.login),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
        ],
      ),
      body: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(target: _currentPosition, zoom: 14.0),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
