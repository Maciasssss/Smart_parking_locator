// lib/helpers/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/parking_spot.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  static const int _dbVersion = 5; // Ensure the version is incremented

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'parking_spots.db');
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE parking_spots (
      id TEXT PRIMARY KEY,
      name TEXT,
      position_lat REAL,
      position_lng REAL,
      car_positions TEXT,
      booked_positions TEXT,
      image_path TEXT,
      localization TEXT,
      description TEXT, -- New field
      features TEXT -- New field
    )
  ''');
}

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE parking_spots ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE parking_spots ADD COLUMN booked_positions TEXT');
    }
    if (oldVersion < 4) {
      // Ensure columns are added if they don't exist
      List<String> existingColumns = await _getExistingColumns(db, 'parking_spots');
      if (!existingColumns.contains('image_path')) {
        await db.execute('ALTER TABLE parking_spots ADD COLUMN image_path TEXT');
      }
      if (!existingColumns.contains('booked_positions')) {
        await db.execute('ALTER TABLE parking_spots ADD COLUMN booked_positions TEXT');
      }
    }
    if (oldVersion < 5) {
    // Add the localization column
    await db.execute('ALTER TABLE parking_spots ADD COLUMN localization TEXT');
    await db.execute('ALTER TABLE parking_spots ADD COLUMN description TEXT');
    await db.execute('ALTER TABLE parking_spots ADD COLUMN features TEXT');
  }
  }

  Future<List<String>> _getExistingColumns(Database db, String tableName) async {
    var result = await db.rawQuery('PRAGMA table_info($tableName)');
    List<String> columns = [];
    for (var row in result) {
      columns.add(row['name'] as String);
    }
    return columns;
  }

  Future<void> saveParkingSpot(ParkingSpot spot) async {
    final db = await database;
    await db.insert(
      'parking_spots',
      spot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateParkingSpot(ParkingSpot spot) async {
    final db = await database;
    await db.update(
      'parking_spots',
      spot.toMap(),
      where: 'id = ?',
      whereArgs: [spot.id],
    );
  }

  Future<void> deleteParkingSpot(String id) async {
    final db = await database;
    await db.delete(
      'parking_spots',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ParkingSpot>> fetchParkingSpots() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('parking_spots');

    return List.generate(maps.length, (i) {
      return ParkingSpot.fromMap(maps[i]);
    });
  }

  Future<ParkingSpot?> getParkingSpotById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parking_spots',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ParkingSpot.fromMap(maps.first);
    }

    return null;
  }
}
