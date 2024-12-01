import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _latitudeKey = 'last_latitude';
  static const String _longitudeKey = 'last_longitude';

  // Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Save last known location
  Future<void> saveLastKnownLocation(Position position) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, position.latitude);
    await prefs.setDouble(_longitudeKey, position.longitude);
  }

  // Retrieve last known location
  Future<Position?> getLastKnownLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble(_latitudeKey);
    double? lng = prefs.getDouble(_longitudeKey);

    if (lat != null && lng != null) {
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,

      );
    }

    return null;
  }
}
