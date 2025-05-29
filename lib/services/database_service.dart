import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/aliment.dart';
import 'package:logging/logging.dart';
import 'aliment_service.dart';
import 'package:uuid/uuid.dart';
import 'repas_service.dart';
import 'jour_repas_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final _logger = Logger('DatabaseService');
  static bool _isInitializing = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Éviter les initialisations multiples
    while (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (_database != null) return _database!;
    
    _isInitializing = true;
    try {
      _database = await _initDatabase();
      return _database!;
    } finally {
      _isInitializing = false;
    }
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pigeon_nutrition.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        _logger.info('Création de la base de données v$version');
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        _logger.info('Migration de la base de données v$oldVersion -> v$newVersion');
        if (oldVersion == 1) {
          await _migrateV1ToV2(db);
        }
      },
    );
  }

  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'pigeon_nutrition.db');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> _createTables(Database db) async {
    // Créer toutes les tables dans une seule transaction
    await db.transaction((txn) async {
      // Table aliments
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS aliments (
          id TEXT PRIMARY KEY,
          nom TEXT NOT NULL,
          calories REAL,
          proteines REAL,
          lipides REAL,
          glucides REAL,
          fibres REAL,
          quantiteStock REAL,
          uniteBase TEXT,
          gestionStock INTEGER,
          seuilAlerte REAL,
          decrementationJournaliere REAL
        )
      ''');

      // Table repas
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS repas (
          id TEXT PRIMARY KEY,
          nom TEXT NOT NULL,
          description TEXT,
          ingredients TEXT NOT NULL
        )
      ''');

      // Table jours_repas
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS jours_repas (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          repasId TEXT NOT NULL,
          heure INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          FOREIGN KEY (repasId) REFERENCES repas (id) ON DELETE CASCADE
        )
      ''');
    });
  }

  Future<void> _migrateV1ToV2(Database db) async {
    await db.transaction((txn) async {
      // 1. Récupérer tous les repas existants
      final List<Map<String, dynamic>> oldRepas = await txn.query('repas');

      // 2. Créer la nouvelle table repas
      await txn.execute('''
        CREATE TABLE new_repas (
          id TEXT PRIMARY KEY,
          nom TEXT NOT NULL,
          nutrimentsCaches TEXT,
          createdAt TEXT
        )
      ''');

      // 3. Créer la table jours_repas
      await txn.execute('''
        CREATE TABLE jours_repas (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          repasId TEXT NOT NULL,
          heure INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          FOREIGN KEY (repasId) REFERENCES repas (id) ON DELETE CASCADE
        )
      ''');

      // 4. Migrer les données
      for (var repas in oldRepas) {
        final dateHeure = DateTime.parse(repas['dateHeure']);
        
        // Insérer dans la nouvelle table repas
        await txn.insert(
          'new_repas',
          {
            'id': repas['id'],
            'nom': repas['nom'],
            'nutrimentsCaches': repas['nutrimentsCaches'],
            'createdAt': dateHeure.toIso8601String(),
          },
        );

        // Créer l'entrée dans jours_repas
        await txn.insert(
          'jours_repas',
          {
            'id': const Uuid().v4(),
            'date': DateTime(dateHeure.year, dateHeure.month, dateHeure.day).toIso8601String(),
            'repasId': repas['id'],
            'heure': dateHeure.hour,
            'minute': dateHeure.minute,
          },
        );
      }

      // 5. Supprimer l'ancienne table et renommer la nouvelle
      await txn.execute('DROP TABLE repas');
      await txn.execute('ALTER TABLE new_repas RENAME TO repas');
    });

    _logger.info('Migration v1 -> v2 terminée');
  }

  Future<void> insertAliment(Aliment aliment) async {
    try {
      final db = await database;
      await db.insert(
        'aliments',
        aliment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.info('Aliment inséré avec succès');
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de l\'insertion de l\'aliment: $e');
      _logger.severe('Stack trace: $stackTrace');
      throw Exception('Erreur lors de l\'insertion: $e');
    }
  }

  Future<List<Aliment>> getAliments() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('aliments');
      return List.generate(maps.length, (i) => Aliment.fromMap(maps[i]));
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de la récupération des aliments: $e');
      _logger.severe('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  Future<void> _logTableStructure(Database db) async {
    try {
      _logger.info('Vérification de la structure de la table aliments...');
      final List<Map<String, dynamic>> tableInfo = await db.rawQuery("PRAGMA table_info('aliments')");
      _logger.info('Colonnes de la table aliments:');
      for (var column in tableInfo) {
        _logger.info('- ${column['name']} (${column['type']})');
      }
    } catch (e) {
      _logger.severe('Erreur lors de la vérification de la structure: $e');
    }
  }

  Future<void> updateAliment(Aliment aliment) async {
    try {
      final db = await database;
      await db.update(
        'aliments',
        aliment.toMap(),
        where: 'id = ?',
        whereArgs: [aliment.id],
      );
      _logger.info('Aliment mis à jour avec succès');
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de la mise à jour de l\'aliment: $e');
      _logger.severe('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> deleteAliment(String id) async {
    try {
      final db = await database;
      _logger.info('Tentative de suppression de l\'aliment avec l\'ID: $id');
      await db.delete(
        'aliments',
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Aliment supprimé avec succès');
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de la suppression de l\'aliment: $e');
      _logger.severe('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  Future<void> initializeDatabase() async {
    try {
      _logger.info('Initialisation de la base de données...');
      await database;
      _logger.info('Base de données initialisée avec succès');
    } catch (e) {
      _logger.severe('Erreur lors de l\'initialisation de la base de données: $e');
      rethrow;
    }
  }
} 