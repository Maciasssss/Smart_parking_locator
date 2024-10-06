import 'package:smart_parking_locator/models/parking_spot.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'parking.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE parking_spots(id TEXT PRIMARY KEY, name TEXT, position_lat REAL, position_lng REAL, car_positions TEXT)',
        );
      },
    );
  }

   Future<void> saveParkingSpot(ParkingSpot spot) async {
    final db = await database;

    await db.insert(
      'parking_spots',
      {
        'id': spot.id,
        'name': spot.name,
        'positionLat': spot.positionLat,
        'positionLng': spot.positionLng,
        'carPositions': spot.carPositions.join(';'), // Join list to save as a string
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if exists
    );
  }

  Future<List<ParkingSpot>> fetchParkingSpots() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('parking_spots');

    return List.generate(maps.length, (i) {
      return ParkingSpot.fromMap(maps[i]);
    });
  }
}
