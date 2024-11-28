// lib/providers/parking_spot_provider.dart

import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/parking_spot.dart';

class ParkingSpotProvider with ChangeNotifier {
  List<ParkingSpot> _parkingSpots = [];

  List<ParkingSpot> get parkingSpots => _parkingSpots;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  ParkingSpotProvider() {
    loadParkingSpots();
  }

  /// Loads all parking spots from the database.
  Future<void> loadParkingSpots() async {
    _parkingSpots = await _dbHelper.fetchParkingSpots();
    notifyListeners();
  }

  /// Saves a parking spot to the database.
  Future<void> saveParkingSpot(ParkingSpot spot) async {
    await _dbHelper.saveParkingSpot(spot);
    await loadParkingSpots(); // Reload to update the list
  }

  /// Retrieves a parking spot by its ID.
  Future<ParkingSpot?> getParkingSpotById(String id) async {
    return await _dbHelper.getParkingSpotById(id);
  }

  /// Updates an existing parking spot.
  Future<void> updateParkingSpot(ParkingSpot spot) async {
    await _dbHelper.updateParkingSpot(spot);
    await loadParkingSpots();
  }

  /// Deletes a parking spot by its ID.
  Future<void> deleteParkingSpot(String id) async {
    await _dbHelper.deleteParkingSpot(id);
    await loadParkingSpots();
  }

  /// Books a parking spot by adding a booked position.
  Future<void> bookParkingSpot(String spotId, String position) async {
    ParkingSpot? spot = await getParkingSpotById(spotId);
    if (spot != null) {
      spot.bookedPositions.add(position);
      await updateParkingSpot(spot);
    }
  }

  /// Checks if a position in a parking spot is booked.
 bool isPositionBooked(String spotId, String position) {
  try {
    ParkingSpot spot = _parkingSpots.firstWhere((s) => s.id == spotId);
    return spot.bookedPositions.contains(position);
  } catch (e) {
    // No matching spot found
    return false;
  }
}
}
