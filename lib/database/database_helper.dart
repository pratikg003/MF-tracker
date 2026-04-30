import 'dart:convert';

import 'package:mf_tracker/models/fund_details.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fund_cache (
        schemeCode INTEGER PRIMARY KEY,
        fundHouse TEXT NOT NULL,
        schemeCategory TEXT NOT NULL,
        historicalData TEXT NOT NULL
      )
    ''');
  }

  Future<void> cacheFundDetails(
    int schemeCode,
    Map<String, dynamic> fundMap,
  ) async {
    final db = await instance.database;

    fundMap['schemeCode'] = schemeCode;

    await db.insert(
      'fund_cache',
      fundMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FundDetails?> getCachedFundDetails(int schemeCode) async {
    final db = await instance.database;

    final results = await db.query(
      'fund_cache',
      where: 'schemeCode = ?',
      whereArgs: [schemeCode],
    );

    if (results.isNotEmpty) {
      final data = results.first;

      final List<dynamic> decodedHistory = jsonDecode(
        data['historicalData'] as String,
      );

      return FundDetails(
        fundHouse: data['fundHouse'] as String,
        schemeCategory: data['schemeCategory'] as String,
        historicalData: decodedHistory
            .map((e) => NavPoint.fromJson(e))
            .toList(),
      );
    }

    return null;
  }
}
