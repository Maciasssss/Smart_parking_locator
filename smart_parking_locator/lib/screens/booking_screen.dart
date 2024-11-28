// lib/screens/booking_screen.dart

import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import 'dart:io';

class BookingScreen extends StatelessWidget {
  final ParkingSpot parkingSpot;

  BookingScreen({required this.parkingSpot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Parking Spot'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              parkingSpot.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            parkingSpot.imagePath != null
                ? Image.file(
                    File(parkingSpot.imagePath!),
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: 100),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement booking logic here
                // For example, show a confirmation dialog
                _showBookingConfirmation(context);
              },
              child: Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking Confirmed'),
          content: Text('You have successfully booked ${parkingSpot.name}.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
            ),
          ],
        );
      },
    );
  }
}
