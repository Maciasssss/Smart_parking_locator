// lib/screens/parking_spot_details_screen.dart

import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import 'dart:io';
import 'parking_spot_booking_screen.dart';

class ParkingSpotDetailsScreen extends StatelessWidget {
  final ParkingSpot parkingSpot;

  ParkingSpotDetailsScreen({required this.parkingSpot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(parkingSpot.name),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Added SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              parkingSpot.imagePath != null
                  ? Image.file(
                      File(parkingSpot.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, size: 100),
                    ),
              SizedBox(height: 16),
              Text(
                parkingSpot.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Localization: ${parkingSpot.localization}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              Text(
                'Description:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                parkingSpot.description,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ...parkingSpot.features.map((feature) => ListTile(
                    leading: Icon(Icons.check),
                    title: Text(feature),
                  )),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to booking screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParkingSpotBookingScreen(markerId: parkingSpot.id),
                      ),
                    );
                  },
                  child: Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
