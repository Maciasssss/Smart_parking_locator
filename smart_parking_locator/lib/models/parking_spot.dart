import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

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
      'startTime': Timestamp.fromDate(startTime),
      'durationHours': durationHours,
    };
  }

  factory BookedPosition.fromMap(Map<String, dynamic> map) {
    return BookedPosition(
      position: map['position'],
      startTime: (map['startTime'] as Timestamp).toDate(),
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
  String description;
  List<String> features;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.positionLat,
    required this.positionLng,
    required this.carPositions,
    required this.bookedPositions,
    this.imagePath,
    required this.localization,
    required this.description,
    required this.features,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'positionLat': positionLat,
      'positionLng': positionLng,
      'carPositions': carPositions,
      'bookedPositions':
          bookedPositions.map((bp) => bp.toMap()).toList(),
      'imagePath': imagePath,
      'localization': localization,
      'description': description,
      'features': features,
    };
  }

  factory ParkingSpot.fromMap(Map<String, dynamic> map) {
    return ParkingSpot(
      id: map['id'],
      name: map['name'],
      positionLat: map['positionLat'],
      positionLng: map['positionLng'],
      carPositions: List<String>.from(map['carPositions'] ?? []),
      bookedPositions: (map['bookedPositions'] as List<dynamic>? ?? [])
          .map((bpMap) =>
              BookedPosition.fromMap(bpMap as Map<String, dynamic>))
          .toList(),
      imagePath: map['imagePath'],
      localization: map['localization'] ?? '',
      description: map['description'] ?? '',
      features: List<String>.from(map['features'] ?? []),
    );
  }
}
