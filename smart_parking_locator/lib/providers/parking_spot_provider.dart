import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/parking_spot.dart';

class ParkingSpotProvider with ChangeNotifier {
  List<ParkingSpot> _parkingSpots = [];

  List<ParkingSpot> get parkingSpots => _parkingSpots;

  final FirestoreHelper _firestoreHelper = FirestoreHelper();

  ParkingSpotProvider() {
    loadParkingSpots();
  }

  Future<void> loadParkingSpots() async {
    _parkingSpots = await _firestoreHelper.fetchParkingSpots();

    for (var spot in _parkingSpots) {
      _cleanupExpiredBookings(spot);
    }

    notifyListeners();
  }

  void _cleanupExpiredBookings(ParkingSpot spot) async {
    DateTime now = DateTime.now();
    spot.bookedPositions.removeWhere((bookedPosition) {
      DateTime endTime = bookedPosition.startTime
          .add(Duration(hours: bookedPosition.durationHours));
      return now.isAfter(endTime);
    });
    await _firestoreHelper.updateParkingSpot(spot);
  }

  Future<void> saveParkingSpot(ParkingSpot spot) async {
    await _firestoreHelper.saveParkingSpot(spot);
    await loadParkingSpots();
  }

  Future<ParkingSpot?> getParkingSpotById(String id) async {
    ParkingSpot? spot = await _firestoreHelper.getParkingSpotById(id);
    if (spot != null) {
      _cleanupExpiredBookings(spot);
    }
    return spot;
  }

  Future<void> updateParkingSpot(ParkingSpot spot) async {
    await _firestoreHelper.updateParkingSpot(spot);
    await loadParkingSpots();
  }

  Future<void> deleteParkingSpot(String id) async {
    await _firestoreHelper.deleteParkingSpot(id);
    await loadParkingSpots();
  }

  Future<void> bookParkingSpot(
      String spotId, BookedPosition bookedPosition) async {
    ParkingSpot? spot = await getParkingSpotById(spotId);
    if (spot != null) {
      spot.bookedPositions.add(bookedPosition);
      await updateParkingSpot(spot);
    }
  }

  bool isPositionBooked(String spotId, String position) {
    try {
      ParkingSpot spot =
          _parkingSpots.firstWhere((s) => s.id == spotId);
      DateTime now = DateTime.now();
      for (var bookedPosition in spot.bookedPositions) {
        if (bookedPosition.position == position) {
          DateTime endTime = bookedPosition.startTime
              .add(Duration(hours: bookedPosition.durationHours));
          if (now.isBefore(endTime)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
