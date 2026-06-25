import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/supplier.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'waste_glass.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collection_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            supplier_id TEXT NOT NULL,
            clear_kg REAL NOT NULL,
            coloured_kg REAL NOT NULL,
            condition TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE trip_meta (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time TEXT NOT NULL,
            end_time TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveCollection(CollectionRecord record) async {
    final db = await database;
    await db.insert(
      'collection_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CollectionRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('collection_records');
    return maps.map((m) => CollectionRecord.fromMap(m)).toList();
  }

  Future<List<CollectionRecord>> getUnsyncedRecords() async {
    final db = await database;
    final maps = await db.query(
      'collection_records',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps.map((m) => CollectionRecord.fromMap(m)).toList();
  }

  Future<CollectionRecord?> getRecordForSupplier(String supplierId) async {
    final db = await database;
    final maps = await db.query(
      'collection_records',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
    );
    if (maps.isEmpty) return null;
    return CollectionRecord.fromMap(maps.first);
  }

  Future<void> markAllSynced() async {
    final db = await database;
    await db.update('collection_records', {'synced': 1});
  }

  Future<void> saveTripStart(DateTime startTime) async {
    final db = await database;
    await db.delete('trip_meta');
    await db.insert('trip_meta', {'start_time': startTime.toIso8601String()});
  }

  Future<DateTime?> getTripStartTime() async {
    final db = await database;
    final maps = await db.query('trip_meta', orderBy: 'id DESC', limit: 1);
    if (maps.isEmpty) return null;
    return DateTime.parse(maps.first['start_time'] as String);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('collection_records');
    await db.delete('trip_meta');
  }
}
