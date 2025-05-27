import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/aliment.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AlimentService {
  static Database? _database;
  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    if (!kIsWeb) {
      // Pour Android et autres plateformes natives
      sqfliteFfiInit();
    }
    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialize();
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      // Configuration pour le web (développement uniquement)
      var factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        'aliments.db',
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // Configuration pour Android (production)
      String path = join(await getDatabasesPath(), 'aliments.db');
      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Création de la base de données...');
    await db.execute('''
      CREATE TABLE aliments(
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        description TEXT,
        gestionStock INTEGER NOT NULL DEFAULT 0,
        quantiteStock REAL NOT NULL,
        seuilAlerte REAL NOT NULL,
        unite TEXT NOT NULL,
        uniteSecondaire TEXT,
        facteurConversion REAL,
        quantiteAchatParDefaut REAL NOT NULL,
        decrementationJournaliere REAL,
        calories REAL NOT NULL,
        proteines REAL NOT NULL,
        lipides REAL NOT NULL,
        glucides REAL NOT NULL,
        fibres REAL NOT NULL,
        eau REAL NOT NULL,
        prixUnitaire REAL NOT NULL,
        devise TEXT NOT NULL
      )
    ''');
    print('Base de données créée avec succès');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Mise à jour de la base de données de la version $oldVersion vers $newVersion');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE aliments ADD COLUMN gestionStock INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE aliments ADD COLUMN decrementationJournaliere REAL');
    }
    print('Mise à jour terminée');
  }

  Future<void> insertAliment(Aliment aliment) async {
    try {
      final db = await database;
      print('Tentative d\'insertion de l\'aliment: ${aliment.toMap()}');
      await db.insert(
        'aliments',
        aliment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Aliment inséré avec succès');
    } catch (e, stackTrace) {
      print('Erreur lors de l\'insertion de l\'aliment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de l\'insertion: $e');
    }
  }

  Future<void> updateAliment(Aliment aliment) async {
    try {
      final db = await database;
      print('Tentative de mise à jour de l\'aliment: ${aliment.toMap()}');
      await db.update(
        'aliments',
        aliment.toMap(),
        where: 'id = ?',
        whereArgs: [aliment.id],
      );
      print('Aliment mis à jour avec succès');
    } catch (e, stackTrace) {
      print('Erreur lors de la mise à jour de l\'aliment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> deleteAliment(String id) async {
    try {
      final db = await database;
      print('Tentative de suppression de l\'aliment avec l\'ID: $id');
      await db.delete(
        'aliments',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Aliment supprimé avec succès');
    } catch (e, stackTrace) {
      print('Erreur lors de la suppression de l\'aliment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  Future<Aliment?> getAliment(String id) async {
    try {
      final db = await database;
      print('Recherche de l\'aliment avec l\'ID: $id');
      final List<Map<String, dynamic>> maps = await db.query(
        'aliments',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        print('Aucun aliment trouvé avec l\'ID: $id');
        return null;
      }
      print('Aliment trouvé: ${maps.first}');
      return Aliment.fromMap(maps.first);
    } catch (e, stackTrace) {
      print('Erreur lors de la recherche de l\'aliment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  Future<List<Aliment>> getAllAliments() async {
    try {
      final db = await database;
      print('Récupération de tous les aliments');
      final List<Map<String, dynamic>> maps = await db.query('aliments');
      print('Nombre d\'aliments trouvés: ${maps.length}');
      return List.generate(maps.length, (i) {
        print('Aliment ${i + 1}: ${maps[i]}');
        return Aliment.fromMap(maps[i]);
      });
    } catch (e, stackTrace) {
      print('Erreur lors de la récupération des aliments: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  Future<List<Aliment>> getAlimentsEnRupture() async {
    try {
      final db = await database;
      print('Recherche des aliments en rupture de stock');
      final List<Map<String, dynamic>> maps = await db.query(
        'aliments',
        where: 'quantiteStock <= seuilAlerte',
      );
      print('Nombre d\'aliments en rupture: ${maps.length}');
      return List.generate(maps.length, (i) {
        print('Aliment en rupture ${i + 1}: ${maps[i]}');
        return Aliment.fromMap(maps[i]);
      });
    } catch (e, stackTrace) {
      print('Erreur lors de la recherche des aliments en rupture: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  Future<void> ajusterStock(String id, double quantite) async {
    try {
      final db = await database;
      print('Ajustement du stock pour l\'aliment $id de $quantite');
      final aliment = await getAliment(id);
      if (aliment != null) {
        aliment.quantiteStock += quantite;
        if (aliment.quantiteStock < 0) aliment.quantiteStock = 0;
        await updateAliment(aliment);
        print('Stock ajusté avec succès');
      } else {
        print('Aliment non trouvé pour l\'ajustement du stock');
      }
    } catch (e, stackTrace) {
      print('Erreur lors de l\'ajustement du stock: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de l\'ajustement du stock: $e');
    }
  }
} 