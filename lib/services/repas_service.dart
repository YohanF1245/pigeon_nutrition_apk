import 'package:sqflite/sqflite.dart';
import '../models/repas.dart';
import 'database_service.dart';
import 'package:logging/logging.dart';

class RepasService {
  static final RepasService _instance = RepasService._internal();
  final _logger = Logger('RepasService');
  final _databaseService = DatabaseService();

  factory RepasService() {
    return _instance;
  }

  RepasService._internal();

  Future<void> initialiserTable() async {
    final db = await _databaseService.database;
    
    // Table des repas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS repas (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        nutrimentsCaches TEXT,
        createdAt TEXT
      )
    ''');

    // Table de liaison repas-aliments
    await db.execute('''
      CREATE TABLE IF NOT EXISTS repas_aliments (
        repasId TEXT,
        alimentId TEXT,
        quantite REAL NOT NULL,
        FOREIGN KEY (repasId) REFERENCES repas (id) ON DELETE CASCADE,
        FOREIGN KEY (alimentId) REFERENCES aliments (id) ON DELETE CASCADE,
        PRIMARY KEY (repasId, alimentId)
      )
    ''');
  }

  Future<void> sauvegarderRepas(Repas repas) async {
    final db = await _databaseService.database;
    
    await db.transaction((txn) async {
      // Sauvegarde du repas
      await txn.insert(
        'repas',
        {
          'id': repas.id,
          'nom': repas.nom,
          'nutrimentsCaches': repas.nutrimentsCaches != null 
              ? repas.nutrimentsCaches.toString() 
              : null,
          'createdAt': repas.createdAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Supprime les anciennes associations
      await txn.delete(
        'repas_aliments',
        where: 'repasId = ?',
        whereArgs: [repas.id],
      );

      // Ajoute les nouvelles associations
      for (var repasAliment in repas.aliments) {
        await txn.insert(
          'repas_aliments',
          {
            'repasId': repas.id,
            'alimentId': repasAliment.alimentId,
            'quantite': repasAliment.quantite,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    _logger.info('Repas sauvegardé: ${repas.id}');
  }

  Future<List<Repas>> getRepas() async {
    final db = await _databaseService.database;

    final List<Map<String, dynamic>> repasRows = await db.query('repas');
    final List<Repas> repas = [];

    for (var repasRow in repasRows) {
      final List<Map<String, dynamic>> alimentsRows = await db.query(
        'repas_aliments',
        where: 'repasId = ?',
        whereArgs: [repasRow['id']],
      );

      final aliments = alimentsRows.map((row) => RepasAliment(
        alimentId: row['alimentId'],
        quantite: row['quantite'],
      )).toList();

      repas.add(Repas(
        id: repasRow['id'],
        nom: repasRow['nom'],
        aliments: aliments,
        nutrimentsCaches: repasRow['nutrimentsCaches'] != null
            ? Map<String, double>.from(
                Map<String, dynamic>.from(
                  repasRow['nutrimentsCaches'] as Map,
                ),
              )
            : null,
        createdAt: repasRow['createdAt'] != null
            ? DateTime.parse(repasRow['createdAt'])
            : null,
      ));
    }

    return repas;
  }

  Future<List<Repas>> getRepasContainingAliment(String alimentId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> repasAlimentsRows = await db.query(
      'repas_aliments',
      where: 'alimentId = ?',
      whereArgs: [alimentId],
    );

    final repasIds = repasAlimentsRows.map((row) => row['repasId'] as String).toSet();
    
    if (repasIds.isEmpty) return [];

    final List<Map<String, dynamic>> repasRows = await db.query(
      'repas',
      where: 'id IN (${List.filled(repasIds.length, '?').join(',')})',
      whereArgs: repasIds.toList(),
    );

    final List<Repas> repas = [];

    for (var repasRow in repasRows) {
      final List<Map<String, dynamic>> alimentsRows = await db.query(
        'repas_aliments',
        where: 'repasId = ?',
        whereArgs: [repasRow['id']],
      );

      final aliments = alimentsRows.map((row) => RepasAliment(
        alimentId: row['alimentId'],
        quantite: row['quantite'],
      )).toList();

      repas.add(Repas(
        id: repasRow['id'],
        nom: repasRow['nom'],
        aliments: aliments,
        createdAt: repasRow['createdAt'] != null
            ? DateTime.parse(repasRow['createdAt'])
            : null,
      ));
    }

    return repas;
  }

  Future<void> supprimerRepas(String id) async {
    final db = await _databaseService.database;
    
    await db.transaction((txn) async {
      // Supprime le repas et ses associations (cascade)
      await txn.delete(
        'repas',
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    _logger.info('Repas supprimé: $id');
  }
} 