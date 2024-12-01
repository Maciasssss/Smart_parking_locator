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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( 
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
                      child: const Icon(Icons.image, size: 100),
                    ),
              const SizedBox(height: 16),
              Text(
                parkingSpot.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Localization: ${parkingSpot.localization}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                parkingSpot.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ...parkingSpot.features.map((feature) => ListTile(
                    leading: const Icon(Icons.check),
                    title: Text(feature),
                  )),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParkingSpotBookingScreen(markerId: parkingSpot.id),
                      ),
                    );
                  },
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
