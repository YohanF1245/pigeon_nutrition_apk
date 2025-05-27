import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/aliment.dart';
import 'package:logging/logging.dart';
import 'aliment_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final _logger = Logger('DatabaseService');

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pigeon_nutrition.db');

    return await openDatabase(
      path,
      version: 2, // Incrémentation de la version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS aliments (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        unite TEXT NOT NULL,
        prixUnitaire REAL NOT NULL,
        devise TEXT NOT NULL,
        gestionStock INTEGER NOT NULL,
        quantiteStock REAL NOT NULL,
        seuilAlerte REAL,
        decrementationJournaliere REAL,
        quantiteAchatParDefaut REAL NOT NULL,
        calories REAL NOT NULL,
        proteines REAL NOT NULL,
        lipides REAL NOT NULL,
        glucides REAL NOT NULL,
        poidsUnitaire REAL,
        unitePortionLabel TEXT,
        nombreUniteParLot INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.info('Migration de la base de données de la version $oldVersion vers $newVersion');
    
    if (oldVersion < 2) {
      _logger.info('Début de la migration vers la version 2');
      
      // Sauvegarde des données existantes
      _logger.info('Sauvegarde des données existantes');
      final List<Map<String, dynamic>> oldData = await db.query('aliments');
      _logger.info('Nombre d\'enregistrements à migrer: ${oldData.length}');

      // Suppression de l'ancienne table
      _logger.info('Suppression de l\'ancienne table');
      await db.execute('DROP TABLE IF EXISTS aliments');

      // Création de la nouvelle table
      _logger.info('Création de la nouvelle table avec la nouvelle structure');
      await _onCreate(db, newVersion);

      // Restauration des données
      _logger.info('Restauration des données dans la nouvelle structure');
      for (var item in oldData) {
        try {
          await db.insert('aliments', {
            'id': item['id'],
            'nom': item['nom'],
            'unite': item['unite'],
            'prixUnitaire': item['prixUnitaire'],
            'devise': item['devise'],
            'gestionStock': item['gestionStock'],
            'quantiteStock': item['quantiteStock'],
            'seuilAlerte': item['seuilAlerte'],
            'decrementationJournaliere': item['decrementationJournaliere'],
            'quantiteAchatParDefaut': item['quantiteAchatParDefaut'],
            'calories': item['calories'],
            'proteines': item['proteines'],
            'lipides': item['lipides'],
            'glucides': item['glucides'],
            'poidsUnitaire': null,
            'unitePortionLabel': null,
            'nombreUniteParLot': null,
          });
          _logger.info('Migré avec succès: ${item['nom']}');
        } catch (e) {
          _logger.severe('Erreur lors de la migration de ${item['nom']}: $e');
        }
      }
      _logger.info('Migration vers la version 2 terminée');
    }
  }

  Future<void> insertAliment(Aliment aliment) async {
    try {
      final db = await database;
      _logger.info('Tentative d\'insertion de l\'aliment: ${aliment.toMap()}');
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
      _logger.info('Récupération de tous les aliments');
      final List<Map<String, dynamic>> maps = await db.query('aliments');
      _logger.info('Nombre d\'aliments trouvés: ${maps.length}');
      return List.generate(maps.length, (i) {
        _logger.info('Aliment ${i + 1}: ${maps[i]}');
        return Aliment.fromMap(maps[i]);
      });
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
      await _logTableStructure(db);

      _logger.info('Début de la mise à jour de l\'aliment: ${aliment.id}');
      final Map<String, dynamic> data = aliment.toMap();
      _logger.info('Données à mettre à jour: $data');

      // Vérifions d'abord si l'aliment existe
      final List<Map<String, dynamic>> existing = await db.query(
        'aliments',
        where: 'id = ?',
        whereArgs: [aliment.id],
      );
      _logger.info('Aliment existant trouvé: ${existing.isNotEmpty}');

      if (existing.isEmpty) {
        _logger.info('L\'aliment n\'existe pas, tentative d\'insertion...');
        await insertAliment(aliment);
        return;
      }

      // Mise à jour avec rawUpdate pour plus de contrôle
      final result = await db.rawUpdate(
        '''
        UPDATE aliments 
        SET nom = ?, 
            unite = ?,
            prixUnitaire = ?,
            devise = ?,
            gestionStock = ?,
            quantiteStock = ?,
            seuilAlerte = ?,
            decrementationJournaliere = ?,
            quantiteAchatParDefaut = ?,
            calories = ?,
            proteines = ?,
            lipides = ?,
            glucides = ?,
            poidsUnitaire = ?,
            unitePortionLabel = ?,
            nombreUniteParLot = ?
        WHERE id = ?
        ''',
        [
          data['nom'],
          data['unite'],
          data['prixUnitaire'],
          data['devise'],
          data['gestionStock'],
          data['quantiteStock'],
          data['seuilAlerte'],
          data['decrementationJournaliere'],
          data['quantiteAchatParDefaut'],
          data['calories'],
          data['proteines'],
          data['lipides'],
          data['glucides'],
          data['poidsUnitaire'],
          data['unitePortionLabel'],
          data['nombreUniteParLot'],
          data['id'],
        ],
      );

      _logger.info('Nombre de lignes mises à jour: $result');

      // Vérifions que la mise à jour a bien été effectuée
      final updated = await db.query(
        'aliments',
        where: 'id = ?',
        whereArgs: [aliment.id],
      );
      _logger.info('Données après mise à jour: ${updated.first}');

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