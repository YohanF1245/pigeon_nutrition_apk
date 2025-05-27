import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/aliment.dart';
import 'package:logging/logging.dart';
import 'aliment_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static final _logger = Logger('DatabaseService');

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final String path = join(await getDatabasesPath(), 'pigeon_nutrition.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final alimentService = AlimentService();
    await alimentService.createTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.info('Mise à jour de la base de données de la version $oldVersion vers $newVersion');
    if (oldVersion < 2) {
      // Sauvegarde des données existantes
      final List<Map<String, dynamic>> oldData = await db.query('aliments');
      
      // Suppression de l'ancienne table
      await db.execute('DROP TABLE IF EXISTS aliments');
      
      // Création de la nouvelle table
      await _onCreate(db, newVersion);
      
      // Restauration des données avec les valeurs par défaut pour les nouveaux champs
      for (var item in oldData) {
        item['description'] = '';
        item['gestionStock'] = 0;
        item['seuilAlerte'] = 0.0;
        item['uniteSecondaire'] = null;
        item['facteurConversion'] = null;
        item['quantiteAchatParDefaut'] = 0.0;
        item['decrementationJournaliere'] = null;
        item['calories'] = 0.0;
        item['eau'] = 0.0;
        item['prixUnitaire'] = 0.0;
        item['devise'] = 'EUR';
        
        await db.insert('aliments', item);
      }
    }
    _logger.info('Mise à jour terminée');
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

  Future<void> updateAliment(Aliment aliment) async {
    try {
      final db = await database;
      _logger.info('Tentative de mise à jour de l\'aliment: ${aliment.toMap()}');
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