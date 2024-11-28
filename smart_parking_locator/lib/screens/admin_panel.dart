// lib/screens/admin_panel.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_parking_locator/screens/parking_reservation_screen.dart';
import 'dart:io';

import '../models/parking_spot.dart';
import '../providers/parking_spot_provider.dart';
import '../services/location_service.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _markers = {};
  LocationService _locationService = LocationService();
  gmaps.LatLng _initialPosition = gmaps.LatLng(37.7749, -122.4194); // Default position
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePositionAndMoveMap();
    _loadParkingSpots();
  }

  Future<void> _determinePositionAndMoveMap() async {
    bool permissionGranted = await _locationService.requestLocationPermission();

    if (permissionGranted) {
      var position = await _locationService.getCurrentLocation();
      if (position != null) {
        await _locationService.saveLastKnownLocation(position);

        setState(() {
          _initialPosition = gmaps.LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        _mapController?.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(
            _initialPosition,
            14.0,
          ),
        );
      }
    } else {
      await _moveToLastKnownLocation();
    }
  }

  Future<void> _moveToLastKnownLocation() async {
    var lastPosition = await _locationService.getLastKnownLocation();
    if (lastPosition != null) {
      setState(() {
        _initialPosition = gmaps.LatLng(lastPosition.latitude, lastPosition.longitude);
        _isLoading = false;
      });

      _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          _initialPosition,
          14.0,
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      _showLocationErrorDialog();
    }
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission'),
          content: Text(
              'Location permission is denied and no last known location is available. Please enable location services or select a default location.'),
          actions: [
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                // Open app settings
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addMarker(gmaps.LatLng position) {
    String markerId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _markers.add(gmaps.Marker(
        markerId: gmaps.MarkerId(markerId),
        position: position,
        infoWindow: gmaps.InfoWindow(
          title: 'New Parking Spot',
          snippet: 'Tap to configure',
          onTap: () {
            _configureNewParkingSpot(markerId, position);
          },
        ),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue),
      ));
    });
  }

  void _configureNewParkingSpot(String markerId, gmaps.LatLng position) async {
    String? name = await _showNameInputDialog();
    if (name == null || name.isEmpty) {
      return;
    }

    String? imagePath = await _pickImage();
    if (imagePath == null) {
      return;
    }

    // Create a ParkingSpot object
    ParkingSpot newSpot = ParkingSpot(
      id: markerId,
      name: name,
      positionLat: position.latitude,
      positionLng: position.longitude,
      bookedPositions: [],
      carPositions: [], // Will be set in reservation screen
      imagePath: imagePath,
    );

    // Save the parking spot
    await Provider.of<ParkingSpotProvider>(context, listen: false).saveParkingSpot(newSpot);

    // Navigate to the reservation creation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingReservationCreationScreen(markerId: markerId),
      ),
    );
  }

  Future<String?> _showNameInputDialog() async {
    String? name;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String tempName = '';
        return AlertDialog(
          title: Text('Enter Parking Spot Name'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Parking Spot Name',
            ),
            onChanged: (value) {
              tempName = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                name = tempName;
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
    return name;
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return pickedFile.path;
      }
    } catch (e) {
      print('Error picking image: $e');
      _showImagePickErrorDialog();
    }
    return null;
  }

  void _showImagePickErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Image Picker Error'),
          content: Text('An error occurred while picking the image. Please try again.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


void _loadParkingSpots() async {
  ParkingSpotProvider provider = Provider.of<ParkingSpotProvider>(context, listen: false);
  await provider.loadParkingSpots(); // Ensure spots are loaded
  List<ParkingSpot> spots = provider.parkingSpots;

  Set<gmaps.Marker> loadedMarkers = spots.map((spot) {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(spot.id),
      position: gmaps.LatLng(spot.positionLat, spot.positionLng),
      // Remove the InfoWindow's onTap callback
      infoWindow: gmaps.InfoWindow(
        title: spot.name,
        snippet: 'Tap marker to view image',
      ),
      onTap: () {
        // Show a dialog with the parking spot image
        _showParkingSpotImageDialog(spot);
      },
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue),
    );
  }).toSet();

  setState(() {
    _markers.addAll(loadedMarkers);
  });
}
void _showParkingSpotImageDialog(ParkingSpot spot) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(spot.name),
        content: spot.imagePath != null
            ? Image.file(
                File(spot.imagePath!),
                fit: BoxFit.cover,
              )
            : Text('No image available'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              // Navigate to reservation editing screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParkingReservationCreationScreen(markerId: spot.id),
                ),
              );
            },
            child: Text('Edit'),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: _initialPosition,
                zoom: 14.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController?.animateCamera(
                  gmaps.CameraUpdate.newLatLngZoom(
                    _initialPosition,
                    14.0,
                  ),
                );
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (position) {
                _addMarker(position);
              },
            ),
    );
  }
}
