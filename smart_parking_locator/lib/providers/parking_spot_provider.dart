// providers/parking_spot_provider.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/parking_spot.dart'; // Ensure you're importing the right model

class ParkingSpotProvider with ChangeNotifier {
  Database? _database;

  // Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'parking_spots.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE parking_spots('
          'id TEXT PRIMARY KEY, '
          'name TEXT, '
          'position_lat REAL, '
          'position_lng REAL, '
          'car_positions TEXT)', // Include car_positions in the table schema
        );
      },
      version: 1,
    );
  }

  // Method to save a parking spot
  Future<void> saveParkingSpot(ParkingSpot spot) async {
    final db = await database;
    await db.insert(
      'parking_spots',
      spot.toMap(), // Convert the ParkingSpot model to a map for storage
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners(); // Notify listeners about the change
  }

  // Method to fetch all parking spots
  Future<List<ParkingSpot>> fetchParkingAreas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('parking_spots');

    return List.generate(maps.length, (i) {
      return ParkingSpot(
        id: maps[i]['id'],
        name: maps[i]['name'],
        positionLat: maps[i]['position_lat'],
        positionLng: maps[i]['position_lng'],
        carPositions: (maps[i]['car_positions'] as String).split(',').toList(), // Convert string back to list
      );
    });
  }

  // Method to save reservation details
  Future<void> saveReservation(String markerId, int carSpots) async {
    final db = await database;
    await db.insert(
      'reservations',
      {
        'markerId': markerId,
        'carSpots': carSpots,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners(); // Notify listeners about the change
  }
}
