// lib/models/parking_spot.dart

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class ParkingSpot {
  final String id;
  final gmaps.LatLng position;
  bool isAvailable;

  ParkingSpot({
    required this.id,
    required this.position,
    this.isAvailable = true,
  });
}

