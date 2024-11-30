// lib/models/parking_spot.dart

import 'dart:convert';

class BookedPosition {
  final String position;
  final DateTime startTime;
  final int durationHours;

  BookedPosition({
    required this.position,
    required this.startTime,
    required this.durationHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'startTime': startTime.toIso8601String(),
      'durationHours': durationHours,
    };
  }

  factory BookedPosition.fromMap(Map<String, dynamic> map) {
    return BookedPosition(
      position: map['position'],
      startTime: DateTime.parse(map['startTime']),
      durationHours: map['durationHours'],
    );
  }
}

class ParkingSpot {
  final String id;
  String name;
  final double positionLat;
  final double positionLng;
  List<String> carPositions;
  List<BookedPosition> bookedPositions;
  String? imagePath;
  String localization;
  String description; // New field
  List<String> features; // New field

  ParkingSpot({
    required this.id,
    required this.name,
    required this.positionLat,
    required this.positionLng,
    required this.carPositions,
    required this.bookedPositions,
    this.imagePath,
    required this.localization,
    required this.description, // New field
    required this.features, // New field
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position_lat': positionLat,
      'position_lng': positionLng,
      'car_positions': jsonEncode(carPositions),
      'booked_positions': jsonEncode(bookedPositions.map((bp) => bp.toMap()).toList()),
      'image_path': imagePath,
      'localization': localization,
      'description': description, // New field
      'features': jsonEncode(features), // New field
    };
  }

  factory ParkingSpot.fromMap(Map<String, dynamic> map) {
    return ParkingSpot(
      id: map['id'],
      name: map['name'],
      positionLat: map['position_lat'],
      positionLng: map['position_lng'],
      carPositions: map['car_positions'] != null && map['car_positions'].isNotEmpty
          ? List<String>.from(jsonDecode(map['car_positions']))
          : [],
      bookedPositions: map['booked_positions'] != null && map['booked_positions'].isNotEmpty
          ? (jsonDecode(map['booked_positions']) as List)
              .map((bpMap) => BookedPosition.fromMap(bpMap))
              .toList()
          : [],
      imagePath: map['image_path'],
      localization: map['localization'] ?? '',
      description: map['description'] ?? '', // New field
      features: map['features'] != null && map['features'].isNotEmpty
          ? List<String>.from(jsonDecode(map['features']))
          : [], // New field
    );
  }
}