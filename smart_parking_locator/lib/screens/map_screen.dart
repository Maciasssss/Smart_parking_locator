// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking_locator/screens/parking_spot_details_screen.dart';
import '../providers/parking_spot_provider.dart';
import '../screens/login_screen.dart';
import '../models/parking_spot.dart';
import 'parking_spot_booking_screen.dart';
import 'dart:io';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  gmaps.GoogleMapController? _mapController;
  gmaps.LatLng _initialPosition = gmaps.LatLng(37.7749, -122.4194); // Default position
  Set<gmaps.Marker> _markers = {};
  bool _isLoading = true;
  ParkingSpot? _selectedParkingSpot; // Add this variable
  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAndGetCurrentLocation();
    _loadMarkers();
  }

  Future<void> _requestLocationPermissionAndGetCurrentLocation() async {
    LocationPermission permission;

    // Check if location services are enabled
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      // Location services are not enabled
      _showLocationServicesDialog();
      return;
    }

    // Check location permission status
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, show a message
      _showPermissionDeniedForeverDialog();
      return;
    }

    // When permission is granted, get the current location
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _initialPosition = gmaps.LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    // Center the map on the user's location
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        _initialPosition,
        14.0,
      ),
    );
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Denied'),
          content: Text('Location permission is denied. Please allow location access to use this feature.'),
          actions: [
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermissionAndGetCurrentLocation();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Denied Forever'),
          content: Text('Location permission is permanently denied. Please enable it in the app settings.'),
          actions: [
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _loadMarkers() async {
    ParkingSpotProvider provider = Provider.of<ParkingSpotProvider>(context, listen: false);
    await provider.loadParkingSpots();
    List<ParkingSpot> spots = provider.parkingSpots;

    Set<gmaps.Marker> markers = spots.map((spot) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(spot.id),
        position: gmaps.LatLng(spot.positionLat, spot.positionLng),
        onTap: () {
          _showParkingSpotInfo(spot);
        },
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  void _showParkingSpotInfo(ParkingSpot spot) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(spot.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            spot.imagePath != null
                ? Image.file(
                    File(spot.imagePath!),
                    fit: BoxFit.cover,
                  )
                : Text('No image available'),
            SizedBox(height: 8),
            Text('Localization: ${spot.localization}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to booking screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParkingSpotBookingScreen(markerId: spot.id),
                ),
              );
            },
            child: Text('Book'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to Read More screen
              _showParkingSpotDetails(spot);
            },
            child: Text('Read More'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}

void _showParkingSpotDetails(ParkingSpot spot) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ParkingSpotDetailsScreen(parkingSpot: spot),
    ),
  );
}

  void _goToLoginScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Locator'),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: _goToLoginScreen,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add the dropdown menu here
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildParkingSpotDropdown(),
                ),
                Expanded(
                  child: gmaps.GoogleMap(
                    initialCameraPosition: gmaps.CameraPosition(target: _initialPosition, zoom: 14.0),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _mapController?.animateCamera(
                        gmaps.CameraUpdate.newLatLngZoom(
                          _initialPosition,
                          14.0,
                        ),
                      );
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildParkingSpotDropdown() {
    ParkingSpotProvider provider = Provider.of<ParkingSpotProvider>(context);
    List<ParkingSpot> spots = provider.parkingSpots;

    if (spots.isEmpty) {
      return Text('No parking spots available');
    }

    return DropdownButton<ParkingSpot>(
      hint: Text('Select a Parking Spot'),
      value: _selectedParkingSpot,
      isExpanded: true,
      onChanged: (ParkingSpot? newValue) {
        setState(() {
          _selectedParkingSpot = newValue!;
          // Center the map on the selected parking spot
          _mapController?.animateCamera(
            gmaps.CameraUpdate.newLatLngZoom(
              gmaps.LatLng(newValue.positionLat, newValue.positionLng),
              16.0,
            ),
          );
          // Show parking spot info
          _showParkingSpotInfo(newValue);
        });
      },
      items: spots.map<DropdownMenuItem<ParkingSpot>>((ParkingSpot spot) {
        return DropdownMenuItem<ParkingSpot>(
          value: spot,
          child: Text('${spot.name}, ${spot.localization}'),
        );
      }).toList(),
    );
  }
}
