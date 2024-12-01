// lib/screens/admin_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/parking_spot.dart';
import '../providers/parking_spot_provider.dart';
import '../services/location_service.dart';
import 'parking_reservation_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final MapController _mapController = MapController();
  final GlobalKey _flutterMapKey = GlobalKey(); // Add a key for FlutterMap
  final List<Marker> _markers = [];
  final LocationService _locationService = LocationService();
  latLng.LatLng _initialPosition = const latLng.LatLng(37.7749, -122.4194);
  bool _isLoading = true;
  bool _isMapReady = false; 

  @override
  void initState() {
    super.initState();
    _loadParkingSpots();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isMapReady = true; 
      });
      _initializeLocation(); 
    });
  }
//Move to current localization 
Future<void> _initializeLocation() async {
  try {
    bool permissionGranted = await _locationService.requestLocationPermission();

    if (!permissionGranted) {
      print("Location permission not granted");
      await _moveToLastKnownLocation();
      return;
    }

    var position = await _locationService.getCurrentLocation();
    if (position != null) {
      print("Current position: ${position.latitude}, ${position.longitude}");
      await _locationService.saveLastKnownLocation(position);

      setState(() {
        _initialPosition = latLng.LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Delay the map movement until FlutterMap is fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isMapReady) {
          print("Moving map to current location");
          _mapController.move(_initialPosition, 14.0);
        }
      });
    } else {
      print("No current position found, moving to last known location");
      await _moveToLastKnownLocation();
    }
  } catch (e) {
    print("Error in _initializeLocation: $e");
    _showLocationErrorDialog();
  }
}




  Future<void> _moveToLastKnownLocation() async {
    var lastPosition = await _locationService.getLastKnownLocation();
    if (lastPosition != null) {
      setState(() {
        _initialPosition = latLng.LatLng(lastPosition.latitude, lastPosition.longitude);
        _isLoading = false;
      });

      if (_isMapReady) {
        _mapController.move(_initialPosition, 14.0); 
      }
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
          title: const Text('Location Permission'),
          content: const Text(
              'Location permission is denied and no last known location is available. Please enable location services or select a default location.'),
          actions: [
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

 void _addMarker(latLng.LatLng position) {
    String markerId = DateTime.now().millisecondsSinceEpoch.toString();

    Marker newMarker = Marker(
      point: position,
      child: GestureDetector(
        onTap: () {
          _configureNewParkingSpot(markerId, position);
        },
        child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
      ),
      width: 40,
      height: 40,
    );

    setState(() {
      _markers.add(newMarker);
    });
  }

  Future<void> _configureNewParkingSpot(String markerId, latLng.LatLng position) async {
    Map<String, dynamic>? details = await _showParkingSpotDetailsInputDialog();
    if (details == null) {
      return;
    }
    String name = details['name'];
    String localization = details['localization'];
    String description = details['description'];
    List<String> features = List<String>.from(details['features']);

    String? imagePath = await _pickImage();
    if (imagePath == null) {
      return;
    }

    ParkingSpot newSpot = ParkingSpot(
      id: markerId,
      name: name,
      positionLat: position.latitude,
      positionLng: position.longitude,
      bookedPositions: [],
      carPositions: [],
      imagePath: imagePath,
      localization: localization,
      description: description,
      features: features,
    );

    await Provider.of<ParkingSpotProvider>(context, listen: false).saveParkingSpot(newSpot);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParkingReservationCreationScreen(markerId: markerId),
      ),
    );
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return pickedFile.path;
      }
    } catch (e) {
      _showImagePickErrorDialog();
    }
    return null;
  }

  void _showImagePickErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Picker Error'),
          content: const Text('An error occurred while picking the image. Please try again.'),
          actions: [
            TextButton(
              child: const Text('OK'),
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
    await provider.loadParkingSpots(); 
    List<ParkingSpot> spots = provider.parkingSpots;

    List<Marker> loadedMarkers = spots.map<Marker>((spot) {
      return Marker(
        point: latLng.LatLng(spot.positionLat, spot.positionLng),
        child: GestureDetector(
          onTap: () {
            _showParkingSpotImageDialog(spot);
          },
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        ),
        width: 40,
        height: 40,
      );
    }).toList();

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
              : const Text('No image available'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParkingReservationCreationScreen(markerId: spot.id),
                  ),
                );
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showParkingSpotDetailsInputDialog() async {
    String? name;
    String? localization;
    String? description;
    List<String> features = [];

    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String tempName = '';
        String tempLocalization = '';
        String tempDescription = '';
        String tempFeature = '';
        List<String> tempFeatures = [];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Parking Spot Details'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Parking Spot Name',
                        ),
                        onChanged: (value) {
                          tempName = value;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Localization (e.g., City)',
                        ),
                        onChanged: (value) {
                          tempLocalization = value;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Description',
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          tempDescription = value;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Add Feature',
                        ),
                        onChanged: (value) {
                          tempFeature = value;
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (tempFeature.isNotEmpty) {
                            setState(() {
                              tempFeatures.add(tempFeature);
                              tempFeature = '';
                            });
                          }
                        },
                        child: const Text('Add Feature'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 100, 
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: tempFeatures.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(tempFeatures[index]),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    tempFeatures.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); 
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    if (tempName.isNotEmpty && tempLocalization.isNotEmpty) {
                      name = tempName;
                      localization = tempLocalization;
                      description = tempDescription;
                      features = tempFeatures;
                      Navigator.of(context).pop(); 
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (name != null && localization != null && description != null) {
      return {
        'name': name!,
        'localization': localization!,
        'description': description!,
        'features': features,
      };
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              key: _flutterMapKey, 
              mapController: _mapController,
              options: MapOptions(
                onTap: (tapPosition, point) {
                  _addMarker(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: const FMTCStore('mapStore').getTileProvider(), // Retain if using caching
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
    );
  }
}