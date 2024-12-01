import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parking_spot.dart';
import '../providers/parking_spot_provider.dart';
import 'dart:io';

class ParkingSpotBookingScreen extends StatefulWidget {
  final String markerId;

  ParkingSpotBookingScreen({required this.markerId});

  @override
  _ParkingSpotBookingScreenState createState() => _ParkingSpotBookingScreenState();
}

class _ParkingSpotBookingScreenState extends State<ParkingSpotBookingScreen> {
  List<Offset> _carPositions = [];
  ParkingSpot? _parkingSpot;
  Offset? _selectedSpot;

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
            return null; 
          }
        }).where((pos) => pos != null).cast<Offset>().toList();
      });
    }
  }


void _bookSpot() async {
  if (_selectedSpot != null && _parkingSpot != null) {
    // Show time selection dialog
    int? hours = await _showTimeSelectionDialog();
    if (hours != null) {
      // Create a BookedPosition object
      String positionString = '${_selectedSpot!.dx},${_selectedSpot!.dy}';
      BookedPosition bookedPosition = BookedPosition(
        position: positionString,
        startTime: DateTime.now(),
        durationHours: hours,
      );
      // Book the spot using the provider
      await Provider.of<ParkingSpotProvider>(context, listen: false)
          .bookParkingSpot(_parkingSpot!.id, bookedPosition);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Spot booked for $hours hour(s)!')),
      );

      Navigator.pop(context);
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a spot to book.')),
    );
  }
}


  Future<int?> _showTimeSelectionDialog() async {
    int selectedHours = 1;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Booking Duration'),
          content: DropdownButton<int>(
            value: selectedHours,
            items: List.generate(24, (index) => index + 1)
                .map((e) => DropdownMenuItem(value: e, child: Text('$e hour(s)')))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedHours = value ?? 1;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, selectedHours);
              },
              child: const Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  bool _isSpotBooked(Offset position) {
    String positionString = '${position.dx},${position.dy}';
    DateTime now = DateTime.now();
    for (var bookedPosition in _parkingSpot!.bookedPositions) {
      if (bookedPosition.position == positionString) {
        DateTime endTime = bookedPosition.startTime.add(Duration(hours: bookedPosition.durationHours));
        if (now.isBefore(endTime)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_parkingSpot == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Book Parking Spot'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Parking Spot'),
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Display the parking area image if available
            if (_parkingSpot!.imagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(_parkingSpot!.imagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            // Display the car icons using Positioned widgets
            ..._carPositions.map((position) {
              bool isBooked = _isSpotBooked(position);
              bool isSelected = _selectedSpot == position;

              return Positioned(
                left: position.dx,
                top: position.dy,
                child: GestureDetector(
                  onTap: () {
                    if (!isBooked) {
                      setState(() {
                        _selectedSpot = position;
                      });
                    }
                  },
                  child: Icon(
                    Icons.local_parking,
                    color: isBooked ? Colors.red : (isSelected ? Colors.green : Colors.blue),
                    size: 30,
                  ),
                ),
              );
            }).toList(),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _bookSpot,
                child: const Text('Book Selected Spot'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
