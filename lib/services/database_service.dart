import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/aliment.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'pigeon_nutrition.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE aliments(
            id TEXT PRIMARY KEY,
            nom TEXT NOT NULL,
            proteines REAL NOT NULL,
            lipides REAL NOT NULL,
            glucides REAL NOT NULL,
            fibres REAL NOT NULL,
            quantiteStock REAL NOT NULL,
            unite TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertAliment(Aliment aliment) async {
    final db = await database;
    await db.insert(
      'aliments',
      aliment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Aliment>> getAliments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('aliments');
    return List.generate(maps.length, (i) => Aliment.fromMap(maps[i]));
  }

  Future<void> updateAliment(Aliment aliment) async {
    final db = await database;
    await db.update(
      'aliments',
      aliment.toMap(),
      where: 'id = ?',
      whereArgs: [aliment.id],
    );
  }

  Future<void> deleteAliment(String id) async {
    final db = await database;
    await db.delete(
      'aliments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 