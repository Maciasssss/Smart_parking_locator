// models/parking_spot.dart

class ParkingSpot {
  final String id;
  final String name; // Name for the parking area
  final double positionLat;
  final double positionLng;
  List<String> carPositions; // List of car icon positions as strings

  ParkingSpot({
    required this.id,
    required this.name,
    required this.positionLat,
    required this.positionLng,
    required this.carPositions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position_lat': positionLat,
      'position_lng': positionLng,
      'car_positions': carPositions.join(','), // Convert list to string for storage
    };
  }

  factory ParkingSpot.fromMap(Map<String, dynamic> map) {
    return ParkingSpot(
      id: map['id'],
      name: map['name'],
      positionLat: map['position_lat'],
      positionLng: map['position_lng'],
      carPositions: (map['car_positions'] as String).split(',').toList(), // Convert string back to list
    );
  }
}
