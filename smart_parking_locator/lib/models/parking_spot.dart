// lib/models/parking_spot.dart

import 'dart:convert';

class ParkingSpot {
  final String id;
  final String name;
  final double positionLat;
  final double positionLng;
  List<String> carPositions;
  List<String> bookedPositions; // New field
  String? imagePath;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.positionLat,
    required this.positionLng,
    required this.carPositions,
    required this.bookedPositions,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position_lat': positionLat,
      'position_lng': positionLng,
      'car_positions': jsonEncode(carPositions),
      'booked_positions': jsonEncode(bookedPositions), // New field
      'image_path': imagePath,
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
          ? List<String>.from(jsonDecode(map['booked_positions']))
          : [],
      imagePath: map['image_path'],
    );
  }
}
