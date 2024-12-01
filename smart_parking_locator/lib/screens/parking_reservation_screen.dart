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
  List<Offset> _carPositions = []; 
  ParkingSpot? _parkingSpot; 

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
    } else {
      // Initialize a new parking spot if it doesn't exist
      _parkingSpot = ParkingSpot(
        id: widget.markerId,
        name: 'Parking Area ${widget.markerId}',
        positionLat: 0.0,
        positionLng: 0.0,
        carPositions: [],
        bookedPositions: [],
        imagePath: null,
        localization: 'Unknown', 
        description: 'No description provided.',
        features: [], 
      );
    }
  }

  void _addCarIcon() {
    setState(() {
      // Adding a car icon at a default position (e.g., center of the screen)
      _carPositions.add(const Offset(100, 100)); 
    });
  }

  Future<void> _saveParkingSpot() async {
  if (_parkingSpot != null) {
    // Update carPositions
    _parkingSpot!.carPositions = _carPositions.map((pos) => '${pos.dx},${pos.dy}').toList();

    // Use the provider to save (update) the parking spot
    try {
      await Provider.of<ParkingSpotProvider>(context, listen: false).saveParkingSpot(_parkingSpot!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save parking spot. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Optionally show a snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parking spot saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  } else {
    // Handle the case where _parkingSpot is null
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parking spot not found. Cannot save changes.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}



Future<Map<String, dynamic>?> _showEditParkingSpotDialog(ParkingSpot spot) async {
  // Initialize controllers outside the StatefulBuilder
  TextEditingController nameController = TextEditingController(text: spot.name);
  TextEditingController localizationController = TextEditingController(text: spot.localization);
  TextEditingController descriptionController = TextEditingController(text: spot.description);
  TextEditingController featureController = TextEditingController();
  List<String> tempFeatures = List.from(spot.features);

  Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Parking Spot Details'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Parking Spot Name',
                      ),
                      controller: nameController,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Localization (e.g., City)',
                      ),
                      controller: localizationController,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Description',
                      ),
                      maxLines: 3,
                      controller: descriptionController,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Add Feature',
                      ),
                      controller: featureController,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (featureController.text.isNotEmpty) {
                          setState(() {
                            tempFeatures.add(featureController.text);
                            featureController.clear();
                          });
                        }
                      },
                      child: const Text('Add Feature'),
                    ),
                    const SizedBox(height: 10),
                    // Display the list of added features with bounded height
                    SizedBox(
                      height: 100, // Set a fixed height
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(), 
                        itemCount: tempFeatures.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(tempFeatures[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  tempFeatures.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); 
                },
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  Navigator.of(context).pop({
                    'name': nameController.text,
                    'localization': localizationController.text,
                    'description': descriptionController.text,
                    'features': tempFeatures,
                  }); 
                },
              ),
            ],
          );
        },
      );
    },
  );

  // Dispose of controllers after the dialog is closed
  nameController.dispose();
  localizationController.dispose();
  descriptionController.dispose();
  featureController.dispose();

  return result;
}


void _editParkingSpotDetails() async {
  if (_parkingSpot != null) {
    Map<String, dynamic>? updatedDetails = await _showEditParkingSpotDialog(_parkingSpot!);
    if (updatedDetails != null) {
      setState(() {
        _parkingSpot!.name = updatedDetails['name'];
        _parkingSpot!.localization = updatedDetails['localization'];
        _parkingSpot!.description = updatedDetails['description'];
        _parkingSpot!.features = updatedDetails['features'];
      });
      await _saveParkingSpot();
    }
  }
}
Future<bool> _onWillPop() async {
  // Check if there are unsaved changes
  bool hasUnsavedChanges = _checkForUnsavedChanges();

  if (hasUnsavedChanges) {
    // Prompt the user to save changes or discard them
    bool shouldLeave = await _showUnsavedChangesDialog();
    if (shouldLeave) {
      // Perform any necessary cleanup or saving
      await _saveParkingSpot();
      return true; 
    } else {
      return false; 
    }
  } else {
    return true; 
  }
}
bool _checkForUnsavedChanges() {
  if (_parkingSpot != null) {
    List<String> currentCarPositions = _carPositions.map((pos) => '${pos.dx},${pos.dy}').toList();
    if (currentCarPositions.toString() != _parkingSpot!.carPositions.toString()) {
      return true;
    }
  }
  return false;
}
Future<bool> _showUnsavedChangesDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); 
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); 
            },
            child: const Text('Leave without Saving'),
          ),
          TextButton(
            onPressed: () async {
              await _saveParkingSpot();
              Navigator.of(context).pop(true); 
            },
            child: const Text('Save and Leave'),
          ),
        ],
      );
    },
  ) ?? false;
}


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Parking Cars'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveParkingSpot, 
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editParkingSpotDetails, 
            ),
          ],
        ),
      body: GestureDetector(
        child: Container(
          color: Colors.white, 
          child: Stack(
            children: [
              if (_parkingSpot?.imagePath != null)
                Positioned.fill(
                  child: Image.file(
                    File(_parkingSpot!.imagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
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
                    child: const Icon(Icons.directions_car, color: Colors.blue, size: 30), 
                  ),
                );
              }).toList(),
              // Button to add new car icons
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: _addCarIcon, // Add a new car icon when pressed
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
