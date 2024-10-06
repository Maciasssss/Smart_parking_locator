import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:smart_parking_locator/helpers/database_helper.dart';
import 'package:smart_parking_locator/models/parking_spot.dart';

class ParkingReservationCreationScreen extends StatefulWidget {
  final String markerId; // Add this to receive the marker ID

  ParkingReservationCreationScreen({required this.markerId}); // Constructor to accept markerId

  @override
  _ParkingReservationCreationScreenState createState() => _ParkingReservationCreationScreenState();
}

class _ParkingReservationCreationScreenState extends State<ParkingReservationCreationScreen> {
  List<gmaps.LatLng> _carPositions = []; // Store car positions as LatLng

  void _addCarIcon() {
    setState(() {
      // Adding a car icon at a default position (can be customized)
      _carPositions.add(gmaps.LatLng(37.7749, -122.4194)); // Example default position
    });
  }

  void _moveCarIcon(int index, gmaps.LatLng newPosition) {
    setState(() {
      _carPositions[index] = newPosition; // Update the position of the car icon
    });
  }

  Future<void> _saveParkingSpot() async {
  // Create a new ParkingSpot object with the updated data
  ParkingSpot newSpot = ParkingSpot(
    id: widget.markerId, // Use the marker ID passed to the screen
    name: 'Parking Area ${widget.markerId}', // Example name
    positionLat: 37.7749, // Set the appropriate latitude for the parking area
    positionLng: -122.4194, // Set the appropriate longitude for the parking area
    carPositions: _carPositions.map((pos) => '${pos.latitude},${pos.longitude}').toList(), // Save car positions
  );

  // Save the parking spot to the database
  await DatabaseHelper().saveParkingSpot(newSpot);
  
  // Navigate back after saving
  Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Parking Reservation'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveParkingSpot, // Save the parking spot
          ),
        ],
      ),
      body: GestureDetector(
        child: Container(
          color: Colors.white, // White background for the editing area
          child: Stack(
            children: [
              // Add a placeholder for the reservation board (like a cinema layout)
              Positioned.fill(
                child: Container(
                  color: Colors.grey[200], // Light grey background for the reservation board
                ),
              ),
              // Display the car icons using a Positioned widget
              ..._carPositions.asMap().entries.map((entry) {
                int index = entry.key;
                gmaps.LatLng position = entry.value;

                return Positioned(
                  left: (position.longitude + 122.4194) * (MediaQuery.of(context).size.width / 0.1), // Calculate left position
                  top: (37.7749 - position.latitude) * (MediaQuery.of(context).size.height / 0.01), // Calculate top position
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // Update the position of the car icon while dragging
                      double newLat = position.latitude - (details.delta.dy / MediaQuery.of(context).size.height) * 0.01 * 2; // Increase the multiplier for faster drag
                      double newLng = position.longitude + (details.delta.dx / MediaQuery.of(context).size.width) * 0.01 * 5; // Increase the multiplier for faster drag
                      _moveCarIcon(index, gmaps.LatLng(newLat, newLng));
                    },
                    child: Icon(Icons.directions_car, color: Colors.blue, size: 30), // Car icon representation
                  ),
                );
              }).toList(),
              // Button to add new car icons
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: _addCarIcon, // Add a new car icon when pressed
                  child: Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
