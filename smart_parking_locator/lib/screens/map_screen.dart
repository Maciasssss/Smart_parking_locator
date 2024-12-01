import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_parking_locator/screens/parking_spot_booking_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/parking_spot_provider.dart';
import '../models/parking_spot.dart';
import '../screens/login_screen.dart';
import 'parking_spot_details_screen.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _initialPosition = const LatLng(37.7749, -122.4194); // Default position
  bool _isLoading = true;
  final MapController _mapController = MapController();
  StreamSubscription? _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  List<Marker> _markers = [];
  ParkingSpot? _selectedParkingSpot;
  List<LatLng> _routePoints = [];

@override
void initState() {
  super.initState();
  _initializeLocation();
  _loadMarkers();

  _checkInitialConnectivity();

  _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
  (List<ConnectivityResult> results) {
    for (var result in results) {
      _checkAndUpdateConnectivity(result); // Process each ConnectivityResult
    }
  },
  onError: (error) {
    setState(() {
      _isOnline = false;
    });
  },
);

}

// Check initial connectivity
Future<void> _checkInitialConnectivity() async {
  try {
    var results = await _connectivity.checkConnectivity() as List<ConnectivityResult>;
    for (var result in results) {
      _checkAndUpdateConnectivity(result);
    }
  } catch (error) {
    setState(() {
      _isOnline = false;
    });
  }
}

// Check and update connectivity status
void _checkAndUpdateConnectivity(ConnectivityResult result) async {
  // Determine if there’s any active network connection
  bool hasNetworkConnection = result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet;

  bool hasInternet = false;

  // Further verify internet connectivity
  if (hasNetworkConnection) {
    hasInternet = await _checkInternetConnectivity();
  }

  setState(() {
    _isOnline = hasInternet;
  });

}

// Method to check actual internet connectivity
Future<bool> _checkInternetConnectivity() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}

Future<bool> _isConnected() async {
  List<ConnectivityResult> result = await _connectivity.checkConnectivity();
  return result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet;
}

// Dispose connectivity subscription
@override
void dispose() {
  _connectivitySubscription?.cancel();
  super.dispose();
}


  Future<void> _initializeLocation() async {
  LocationPermission permission;

  bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isLocationServiceEnabled) {
    _showLocationServicesDialog();
    return;
  }

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      _showPermissionDeniedDialog();
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    _showPermissionDeniedForeverDialog();
    return;
  }

  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  setState(() {
    _initialPosition = LatLng(position.latitude, position.longitude);
    _isLoading = false;

    // Add a marker for the user's location
    _addUserLocationMarker(_initialPosition);
  });

  // Move the map to the user's location
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _mapController.move(_initialPosition, 14.0);
  });
}
void _addUserLocationMarker(LatLng position) {
  Marker userMarker = Marker(
    point: position,
    child: const Icon(
      Icons.person_pin_circle,
      color: Colors.blue,
      size: 40,
    ),
    width: 40,
    height: 40,
  );

  setState(() {
    _markers.add(userMarker);
  });
}
  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.of(context).pop();
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
          title: const Text('Permission Denied'),
          content: const Text('Location permission is denied. Please allow location access to use this feature.'),
          actions: [
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeLocation();
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
          title: const Text('Permission Denied Forever'),
          content: const Text('Location permission is permanently denied. Please enable it in the app settings.'),
          actions: [
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadMarkers() async {
    ParkingSpotProvider provider = Provider.of<ParkingSpotProvider>(context, listen: false);
    await provider.loadParkingSpots();
    List<ParkingSpot> spots = provider.parkingSpots;

    List<Marker> markers = spots.map<Marker>((spot) {
      return Marker(
        point: LatLng(spot.positionLat, spot.positionLng),
        child: GestureDetector(
          onTap: () {
            _showParkingSpotInfo(spot);
          },
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
        width: 40,
        height: 40,
      );
    }).toList();

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
            if (spot.imagePath != null)
              Flexible(
                child: SizedBox(
                  height: 200,
                  child: Image.file(
                    File(spot.imagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              const Text('No image available'),
          ],
        ),
        actions: [
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isOnline
                    ? () => _launchGoogleMaps(LatLng(spot.positionLat, spot.positionLng))
                    : null,
                icon: const Icon(Icons.directions),
                label: const Text('Navigate via GPS'),
              ),
              ElevatedButton.icon(
                onPressed: _isOnline ? () => _downloadRoute(spot) : null,
                icon: const Icon(Icons.download),
                label: const Text('Download Route'),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateFromLocalStorage(spot),
                icon: const Icon(Icons.storage),
                label: const Text('Navigate from Local Storage'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ParkingSpotDetailsScreen(parkingSpot: spot),
                    ),
                  );
                },
                icon: const Icon(Icons.info),
                label: const Text('Details'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParkingSpotBookingScreen(markerId: spot.id),
                    ),
                  );
                },
                icon: const Icon(Icons.book_online),
                label: const Text('Book'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ],
          ),
        ],
      );
    },
  );
}



Future<void> _navigateFromLocalStorage(ParkingSpot spot) async {
  List<LatLng>? cachedRoute = await _loadRouteFromLocal(spot.id);

  if (cachedRoute != null) {
    Navigator.of(context).pop(); // Close the marker info dialog

    setState(() {
      _routePoints = cachedRoute;
    });

    // Focus on the start of the cached route with the correct zoom level
    LatLng routeStart = cachedRoute.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(routeStart, 16.0); // Match "Locate Yourself" zoom level
    });

    fitMapToBounds(_mapController, cachedRoute);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating from local storage.')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No cached route found.')),
    );
  }
}


Future<void> _downloadRoute(ParkingSpot spot) async {
  if (!_isOnline) {
    // Inform the user and exit early if offline
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be online to download the route.')),
    );
    return;
  }

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng userLocation = LatLng(position.latitude, position.longitude);

    List<LatLng>? route = await _fetchRoute(userLocation, LatLng(spot.positionLat, spot.positionLng));

    if (route != null) {
      await _saveRouteLocally(spot.id, route);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route downloaded successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download the route.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error downloading the route: $e')),
    );
  }
}


  
void _launchGoogleMaps(LatLng destination) async {
  String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving';

  if (await canLaunch(googleMapsUrl)) {
    await launch(googleMapsUrl);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch Google Maps')),
    );
  }
}

  Future<void> _downloadRouteToSpot(ParkingSpot spot) async {
  bool connected = await _isConnected();
  if (connected) {
    // Launch Google Maps for navigation
    _launchGoogleMaps(LatLng(spot.positionLat, spot.positionLng));
  } else {
    // Offline navigation logic
    try {
      // Fetch the user's current position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      // Fetch route to the parking spot
      List<LatLng>? route = await _fetchRoute(userLocation, LatLng(spot.positionLat, spot.positionLng));

      if (route != null) {
        await _saveRouteLocally(spot.id, route);

        setState(() {
          _routePoints = route;
        });

        // Add a marker for the user's location and zoom to it
        _zoomToUserLocation();

        // Optionally fit bounds to include the route
        fitMapToBounds(_mapController, route);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch route')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch route or location: $e')),
      );
    }
  }
}


  Future<List<LatLng>?> _fetchRoute(LatLng origin, LatLng destination) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
      return route.map<LatLng>((point) => LatLng(point[1], point[0])).toList();
    } else {
      return null;
    }
  }

  Future<void> _saveRouteLocally(String spotId, List<LatLng> route) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/route_$spotId.json');
    List<List<double>> routeList = route.map((point) => [point.latitude, point.longitude]).toList();
    await file.writeAsString(json.encode(routeList));
  }

  Future<List<LatLng>?> _loadRouteFromLocal(String spotId) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/route_$spotId.json');

    if (await file.exists()) {
      String content = await file.readAsString();
      List<dynamic> routeList = json.decode(content);
      return routeList.map<LatLng>((point) => LatLng(point[0], point[1])).toList();
    } else {
      return null;
    }
  }


  void _goToLoginScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  // Manual Fit Bounds Function
  void fitMapToBounds(MapController mapController, List<LatLng> points) {
    if (points.isEmpty) return;

    LatLng center = calculateCenter(points);

    double maxDistance = calculateMaxDistance(points, center);

    double zoom = approximateZoom(maxDistance);

    mapController.move(center, zoom);
  }

  // Function to calculate center
  LatLng calculateCenter(List<LatLng> points) {
    double minLat = points.map((p) => p.latitude).reduce(min);
    double maxLat = points.map((p) => p.latitude).reduce(max);
    double minLng = points.map((p) => p.longitude).reduce(min);
    double maxLng = points.map((p) => p.longitude).reduce(max);

    double centerLat = (minLat + maxLat) / 2;
    double centerLng = (minLng + maxLng) / 2;

    return LatLng(centerLat, centerLng);
  }

  // Function to calculate maximum distance
  double calculateMaxDistance(List<LatLng> points, LatLng center) {
    const Distance distance = Distance();
    double maxDistance = 0.0;

    for (LatLng point in points) {
      double d = distance(center, point);
      if (d > maxDistance) {
        maxDistance = d;
      }
    }

    return maxDistance;
  }

  // Function to approximate zoom level based on distance
  double approximateZoom(double maxDistance) {
    if (maxDistance < 1) {
      return 16.0;
    } else if (maxDistance < 5) {
      return 14.0;
    } else if (maxDistance < 20) {
      return 12.0;
    } else if (maxDistance < 50) {
      return 10.0;
    } else {
      return 8.0;
    }
  }

Future<void> _zoomToUserLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng userLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      // Optional: Add a marker at the user's current location
      _markers.removeWhere((marker) => marker.point == userLocation); 
      _addUserLocationMarker(userLocation);
    });

    _mapController.move(userLocation, 16.0);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to fetch location: $e')),
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Parking Locator'),
      actions: [
        IconButton(
          icon: const Icon(Icons.admin_panel_settings),
          onPressed: _goToLoginScreen,
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildParkingSpotDropdown(),
              ),
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    onTap: (tapPosition, point) {},
                  ),
                  children: [
                    TileLayer(
                      tileProvider: const FMTCStore('mapStore').getTileProvider(),
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: _markers,
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: _zoomToUserLocation,
      child: const Icon(Icons.navigation),
    ),
  );
}



  Widget _buildParkingSpotDropdown() {
    ParkingSpotProvider provider = Provider.of<ParkingSpotProvider>(context);
    List<ParkingSpot> spots = provider.parkingSpots;

    if (spots.isEmpty) {
      return const Text('No parking spots available');
    }

    return DropdownButton<ParkingSpot>(
      hint: const Text('Select a Parking Spot'),
      value: _selectedParkingSpot,
      isExpanded: true,
      onChanged: (ParkingSpot? newValue) {
        if (newValue == null) return;
        setState(() {
          _selectedParkingSpot = newValue;
          _mapController.move(
            LatLng(newValue.positionLat, newValue.positionLng),
            16.0,
          );
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
