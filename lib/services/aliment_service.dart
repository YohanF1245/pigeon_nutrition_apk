import 'package:sqflite/sqflite.dart';
import '../models/aliment.dart';
import 'database_service.dart';
import 'package:logging/logging.dart';

class AlimentService {
  final _databaseService = DatabaseService();
  static final _logger = Logger('AlimentService');

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS aliments (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        unite TEXT NOT NULL,
        uniteSecondaire TEXT,
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
        facteurConversion REAL
      )
    ''');
  }

  Future<void> insertAliment(Aliment aliment) async {
    final db = await _databaseService.database;
    await db.insert(
      'aliments',
      aliment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addAliment(Aliment aliment) => insertAliment(aliment);

  Future<List<Aliment>> getAliments() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('aliments');
    return List.generate(maps.length, (i) => Aliment.fromMap(maps[i]));
  }

  Future<List<Aliment>> getAllAliments() => getAliments();

  Future<void> updateAliment(Aliment aliment) async {
    final db = await _databaseService.database;
    await db.update(
      'aliments',
      aliment.toMap(),
      where: 'id = ?',
      whereArgs: [aliment.id],
    );
  }

  Future<void> deleteAliment(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'aliments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> ajusterStock(String id, double quantite) async {
    final db = await _databaseService.database;
    final aliment = Aliment.fromMap(
      (await db.query('aliments', where: 'id = ?', whereArgs: [id])).first,
    );
    aliment.ajusterStock(quantite);
    await updateAliment(aliment);
  }

  Future<List<Aliment>> getAlimentsEnRupture() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aliments',
      where: 'gestionStock = 1 AND seuilAlerte IS NOT NULL AND quantiteStock <= seuilAlerte',
    );
    return List.generate(maps.length, (i) => Aliment.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getListeCourses() async {
    try {
      _logger.info('Récupération de la liste des courses...');
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'aliments',
        where: 'gestionStock = 1 AND seuilAlerte IS NOT NULL AND quantiteStock <= seuilAlerte',
        columns: ['id', 'nom', 'quantiteStock', 'seuilAlerte', 'quantiteAchatParDefaut', 'unite', 'uniteSecondaire', 'prixUnitaire', 'devise']
      );
      
      return maps.map((aliment) {
        final quantiteAchatParDefaut = aliment['quantiteAchatParDefaut'] as double? ?? 0.0;
        final prixUnitaire = aliment['prixUnitaire'] as double? ?? 0.0;
        final coutEstime = (quantiteAchatParDefaut * prixUnitaire).toStringAsFixed(2);
        
        return {
          'id': aliment['id'] ?? '',
          'nom': aliment['nom'] ?? 'Sans nom',
          'quantiteStock': (aliment['quantiteStock'] as double?)?.toStringAsFixed(2) ?? '0.00',
          'seuilAlerte': (aliment['seuilAlerte'] as double?)?.toStringAsFixed(2) ?? '0.00',
          'quantiteAcheter': quantiteAchatParDefaut.toStringAsFixed(2),
          'unite': aliment['unite'] ?? 'unité',
          'uniteSecondaire': aliment['uniteSecondaire'],
          'coutEstime': coutEstime,
          'devise': aliment['devise'] ?? 'EUR',
        };
      }).toList();
    } catch (e) {
      _logger.severe('Erreur lors de la récupération de la liste des courses: $e');
      rethrow;
    }
  }
} 