import 'dart:convert';

import 'package:mf_tracker/models/fund_details.dart';
import 'package:mf_tracker/models/portfolio_item.dart';
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

    await db.execute('''
      CREATE TABLE portfolio_funds (
        schemeCode INTEGER PRIMARY KEY,
        schemeName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schemeCode INTEGER NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        nav REAL NOT NULL,
        units REAL NOT NULL,
        FOREIGN KEY (schemeCode) REFERENCES portfolio_funds (schemeCode) ON DELETE CASCADE
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

  Future<void> addInvestment({
    required int schemeCode,
    required String schemeName,
    required double amount,
    required double currentNav,
  }) async {
    final db = await instance.database;

    await db.insert('portfolio_funds', {
      'schemeCode': schemeCode,
      'schemeName': schemeName,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final double units = amount / currentNav;

    await db.insert('transactions', {
      'schemeCode': schemeCode,
      'date': DateTime.now().toIso8601String(),
      'amount': amount,
      'nav': currentNav,
      'units': units,
    });

    print(
      'SUCCESS: Invested ₹$amount in $schemeName for $units units at NAV $currentNav',
    );
  }

  Future<List<PortfolioItem>> getPortfolioSummary() async {
    final db = await instance.database;

    // This is the magic of Relational Databases
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        p.schemeCode, 
        p.schemeName, 
        SUM(t.amount) as totalInvested, 
        SUM(t.units) as totalUnits
      FROM portfolio_funds p
      JOIN transactions t ON p.schemeCode = t.schemeCode
      GROUP BY p.schemeCode, p.schemeName
    ''');

    return result.map((map) => PortfolioItem.fromMap(map)).toList();
  }
}
