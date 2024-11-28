// lib/screens/parking_reservation_creation_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking_locator/models/parking_spot.dart';
import 'dart:io';

import 'package:smart_parking_locator/providers/parking_spot_provider.dart';

class ParkingReservationCreationScreen extends StatefulWidget {
  final String markerId;

  ParkingReservationCreationScreen({required this.markerId});

  @override
  _ParkingReservationCreationScreenState createState() => _ParkingReservationCreationScreenState();
}

class _ParkingReservationCreationScreenState extends State<ParkingReservationCreationScreen> {
  List<Offset> _carPositions = []; // Store car positions as screen offsets
  ParkingSpot? _parkingSpot; // Store the parking spot

  @override
  void initState() {
    super.initState();
    _loadParkingSpot();
  }

  Future<void> _loadParkingSpot() async {
    // Fetch the parking spot from the provider
    ParkingSpotProvider provider = Provider.of<ParkingSpotProvider>(context, listen: false);
    ParkingSpot? spot = await provider.getParkingSpotById(widget.markerId);

    if (spot != null) {
      setState(() {
        _parkingSpot = spot;
        _carPositions = spot.carPositions.map((posString) {
          try {
            List<String> xy = posString.split(',');
            if (xy.length != 2) {
              throw FormatException('Invalid position format: $posString');
            }
            double dx = double.parse(xy[0]);
            double dy = double.parse(xy[1]);
            return Offset(dx, dy);
          } catch (e) {
            print('Error parsing position: $e');
            return null; // Skip this position if there's an error
          }
        }).where((pos) => pos != null).cast<Offset>().toList();
      });
    } else {
      // Initialize a new parking spot if it doesn't exist
      _parkingSpot = ParkingSpot(
        id: widget.markerId,
        name: 'Parking Area ${widget.markerId}',
        positionLat: 0.0, // Not used in this context
        positionLng: 0.0, // Not used in this context
        carPositions: [],
        bookedPositions: [],
        imagePath: null, // Initialize with null
      );
    }
  }

  void _addCarIcon() {
    setState(() {
      // Adding a car icon at a default position (e.g., center of the screen)
      _carPositions.add(Offset(100, 100)); // Adjust the default position as needed
    });
  }

  Future<void> _saveParkingSpot() async {
  if (_parkingSpot != null) {
    // Update carPositions
    _parkingSpot!.carPositions = _carPositions.map((pos) => '${pos.dx},${pos.dy}').toList();

    // Use the provider to save (update) the parking spot
    await Provider.of<ParkingSpotProvider>(context, listen: false).saveParkingSpot(_parkingSpot!);

    // Show a snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Parking spot saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );

    // Wait for the snackbar to be visible before navigating back
    await Future.delayed(Duration(seconds: 2));

    // Navigate back after saving
    Navigator.pop(context);
  } else {
    // Handle the case where _parkingSpot is null if necessary
    // You can show an error message or handle it appropriately
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Parking Cars'),
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
              // Display the parking area image if available
              if (_parkingSpot?.imagePath != null)
                Positioned.fill(
                  child: Image.file(
                    File(_parkingSpot!.imagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              // Display the car icons using Positioned widgets
              ..._carPositions.asMap().entries.map((entry) {
                int index = entry.key;
                Offset position = entry.value;

                return Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // Update the position of the car icon while dragging
                      setState(() {
                        _carPositions[index] = _carPositions[index] + details.delta;
                      });
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
