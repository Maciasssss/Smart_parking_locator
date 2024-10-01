import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supercluster/supercluster.dart';
import 'package:smart_parking_locator/models/parking_spot.dart';
import 'package:smart_parking_locator/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  gmaps.GoogleMapController? _mapController;

  gmaps.LatLng _currentPosition = gmaps.LatLng(37.7749, -122.4194);

  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Polyline> _polylines = {};
  List<gmaps.LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  List<ParkingSpot> parkingSpots = [
    ParkingSpot(id: '1', position: gmaps.LatLng(37.7750, -122.4183), isAvailable: true),
    ParkingSpot(id: '2', position: gmaps.LatLng(37.7760, -122.4172), isAvailable: true),
    ParkingSpot(id: '3', position: gmaps.LatLng(37.7740, -122.4200), isAvailable: true),
    // Add more spots as needed
  ];

  late NotificationService _notificationService;

  // Supercluster instance
  late SuperclusterMutable<ParkingSpot> _supercluster;
  double _currentZoom = 14.0;

  final Uuid uuid = Uuid();

  String generateUuid() {
    return uuid.v4();
  }

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _initializeSupercluster();
    _getCurrentLocation();
  }

  void _initializeSupercluster() {
    _supercluster = SuperclusterMutable<ParkingSpot>(
      getX: (spot) => spot.position.longitude,
      getY: (spot) => spot.position.latitude,
      minZoom: 0,
      maxZoom: 19,
      radius: 60,
      generateUuid: generateUuid, // Provide the generateUuid function
    )..load(parkingSpots);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDisabledDialog();
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedSnackbar();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedForeverDialog();
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = gmaps.LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_currentPosition, _currentZoom),
    );

    _updateMarkers();
  }

  Future<void> _updateMarkers() async {
  if (_mapController == null) return;

  final zoom = _currentZoom.toInt();
  final bounds = await _mapController!.getVisibleRegion();
  final clusters = _supercluster.search(
    bounds.southwest.longitude,
    bounds.southwest.latitude,
    bounds.northeast.longitude,
    bounds.northeast.latitude,
    zoom,
  );

  Set<gmaps.Marker> markers = Set();

  for (var cluster in clusters) {
    if (cluster is LayerCluster<ParkingSpot>) {
  final layerCluster = cluster as LayerCluster<ParkingSpot>;

  final String clusterId = 'cluster_${layerCluster.uuid}';
  final int clusterSize = layerCluster.childPointCount;

  markers.add(
    gmaps.Marker(
      markerId: gmaps.MarkerId(clusterId),
      position: gmaps.LatLng(layerCluster.y, layerCluster.x),
      icon: await _getClusterIcon(clusterSize),
      infoWindow: gmaps.InfoWindow(title: '$clusterSize Spots'),
      onTap: () {
        _mapController?.animateCamera(
          gmaps.CameraUpdate.zoomTo(_currentZoom + 2),
        );
      },
    ),
  );
}
 else if (cluster is LayerPoint<ParkingSpot>) {
      // It's an individual point
      final layerPoint = cluster as LayerPoint<ParkingSpot>;
      final spot = layerPoint.originalPoint;

      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(spot.id),
          position: spot.position,
          icon: spot.isAvailable
              ? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen)
              : gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
          infoWindow: gmaps.InfoWindow(title: spot.isAvailable ? "Available Spot" : "Occupied"),
          onTap: () {
            if (spot.isAvailable) {
              _showReserveDialog(spot);
            } else {
              _showFreeDialog(spot);
            }
          },
        ),
      );
    } else {
      // Handle unexpected types
      print('Unknown cluster type: ${cluster.runtimeType}');
    }
  }

  setState(() {
    _markers = markers;
  });
}






  Future<gmaps.BitmapDescriptor> _getClusterIcon(int clusterSize) async {
    // Customize the cluster icon based on the cluster size
    // For simplicity, we'll return a default marker here
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueOrange);
  }

  void _onCameraMove(gmaps.CameraPosition position) {
    _currentZoom = position.zoom;
  }

  void _onCameraIdle() {
    _updateMarkers();
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    _mapController = controller;
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_currentPosition, _currentZoom),
    );
    _updateMarkers();
  }

  Future<void> _scheduleNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notificationService.scheduleNotification(
      notificationId: notificationId,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this app.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location permissions are denied.')),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permissions Permanently Denied'),
          content: Text('Please enable location permissions from settings to use this app.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showReserveDialog(ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reserve Parking Spot'),
          content: Text('Do you want to reserve this parking spot?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _reserveParkingSpot(spot);
                Navigator.of(context).pop();
              },
              child: Text('Reserve'),
            ),
          ],
        );
      },
    );
  }

  void _showFreeDialog(ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Free Parking Spot'),
          content: Text('Do you want to free this parking spot?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _freeParkingSpot(spot);
                Navigator.of(context).pop();
              },
              child: Text('Free'),
            ),
          ],
        );
      },
    );
  }

  void _reserveParkingSpot(ParkingSpot spot) {
    setState(() {
      spot.isAvailable = false;
      _supercluster.remove(spot);
      _supercluster.insert(spot);
      _updateMarkers();
    });

    int notificationId = int.tryParse(spot.id) ?? DateTime.now().millisecondsSinceEpoch;
    _scheduleNotification(
      notificationId: notificationId,
      title: 'Parking Time Alert',
      body: 'Your parking time for spot ${spot.id} is about to expire.',
      scheduledTime: DateTime.now().add(Duration(hours: 2)),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Parking spot reserved. Notification scheduled in 2 hours.')),
    );
  }

  void _freeParkingSpot(ParkingSpot spot) {
    setState(() {
      spot.isAvailable = true;
      _supercluster.remove(spot);
      _supercluster.insert(spot);
      _updateMarkers();
    });

    int notificationId = int.tryParse(spot.id) ?? DateTime.now().millisecondsSinceEpoch;
    _notificationService.cancelNotification(notificationId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Parking spot freed. Notification canceled.')),
    );
  }

  Future<void> _drawRoute(gmaps.LatLng destination) async {
    String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Maps API Key is missing')),
      );
      return;
    }

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      apiKey,
      PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates.clear();
      for (var point in result.points) {
        polylineCoordinates.add(gmaps.LatLng(point.latitude, point.longitude));
      }
    }

    setState(() {
      _polylines.add(
        gmaps.Polyline(
          polylineId: gmaps.PolylineId("route"),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ),
      );
    });
  }

  void _addMarker(gmaps.LatLng position, String info, {gmaps.BitmapDescriptor? icon}) {
    setState(() {
      _markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(position.toString()),
          position: position,
          infoWindow: gmaps.InfoWindow(title: info),
          icon: icon ?? gmaps.BitmapDescriptor.defaultMarker,
          onTap: () {},
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Parking Locator'),
      ),
      body: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: _currentPosition,
          zoom: _currentZoom,
        ),
        myLocationEnabled: true,
        markers: _markers,
        polylines: _polylines,
        onMapCreated: _onMapCreated,
        onCameraMove: _onCameraMove,
        onCameraIdle: _onCameraIdle,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.directions),
        onPressed: () {
          gmaps.LatLng destination = gmaps.LatLng(37.7849, -122.4094);
          _drawRoute(destination);
          _addMarker(destination, "Destination");
        },
      ),
    );
  }
}
