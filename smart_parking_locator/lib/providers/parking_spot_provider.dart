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

    // Clean up expired bookings
    for (var spot in _parkingSpots) {
      _cleanupExpiredBookings(spot);
    }

    notifyListeners();
  }

  /// Cleans up expired bookings for a parking spot.
  void _cleanupExpiredBookings(ParkingSpot spot) {
    DateTime now = DateTime.now();
    spot.bookedPositions.removeWhere((bookedPosition) {
      DateTime endTime = bookedPosition.startTime.add(Duration(hours: bookedPosition.durationHours));
      return now.isAfter(endTime);
    });
    // After cleanup, update the spot in the database
    _dbHelper.updateParkingSpot(spot);
  }

  /// Saves a parking spot to the database.
  Future<void> saveParkingSpot(ParkingSpot spot) async {
    await _dbHelper.saveParkingSpot(spot);
    await loadParkingSpots(); // Reload to update the list
  }

  /// Retrieves a parking spot by its ID.
  Future<ParkingSpot?> getParkingSpotById(String id) async {
    ParkingSpot? spot = await _dbHelper.getParkingSpotById(id);
    if (spot != null) {
      // Clean up expired bookings
      _cleanupExpiredBookings(spot);
    }
    return spot;
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
  Future<void> bookParkingSpot(String spotId, BookedPosition bookedPosition) async {
    ParkingSpot? spot = await getParkingSpotById(spotId);
    if (spot != null) {
      spot.bookedPositions.add(bookedPosition);
      await updateParkingSpot(spot);
    }
  }

  /// Checks if a position in a parking spot is booked.
  bool isPositionBooked(String spotId, String position) {
    try {
      ParkingSpot spot = _parkingSpots.firstWhere((s) => s.id == spotId);
      DateTime now = DateTime.now();
      for (var bookedPosition in spot.bookedPositions) {
        if (bookedPosition.position == position) {
          DateTime endTime = bookedPosition.startTime.add(Duration(hours: bookedPosition.durationHours));
          if (now.isBefore(endTime)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      // No matching spot found
      return false;
    }
  }
}
