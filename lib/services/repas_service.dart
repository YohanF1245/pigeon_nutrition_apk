import 'package:sqflite/sqflite.dart';
import '../models/repas.dart';
import 'database_service.dart';
import 'aliment_service.dart';
import 'package:logging/logging.dart';

class RepasService {
  static final RepasService _instance = RepasService._internal();
  final _logger = Logger('RepasService');
  final _databaseService = DatabaseService();
  final _alimentService = AlimentService();

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
        dateHeure TEXT NOT NULL,
        nutrimentsCaches TEXT
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
          'dateHeure': repas.dateHeure.toIso8601String(),
          'nutrimentsCaches': repas.nutrimentsCaches != null 
              ? repas.nutrimentsCaches.toString() 
              : null,
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

        // Mise à jour du stock
        await _alimentService.updateStock(
          repasAliment.alimentId,
          -repasAliment.quantite,
          txn,
        );
      }
    });

    _logger.info('Repas sauvegardé: ${repas.id}');
  }

  Future<List<Repas>> getRepas({DateTime? date}) async {
    final db = await _databaseService.database;
    
    String whereClause = '';
    List<String> whereArgs = [];
    
    if (date != null) {
      final debut = DateTime(date.year, date.month, date.day);
      final fin = debut.add(const Duration(days: 1));
      whereClause = 'dateHeure BETWEEN ? AND ?';
      whereArgs = [debut.toIso8601String(), fin.toIso8601String()];
    }

    final List<Map<String, dynamic>> repasRows = await db.query(
      'repas',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
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
        dateHeure: DateTime.parse(repasRow['dateHeure']),
        aliments: aliments,
        nutrimentsCaches: repasRow['nutrimentsCaches'] != null
            ? Map<String, double>.from(
                Map<String, dynamic>.from(
                  repasRow['nutrimentsCaches'] as Map,
                ),
              )
            : null,
      ));
    }

    return repas;
  }

  Future<void> supprimerRepas(String id) async {
    final db = await _databaseService.database;
    
    await db.transaction((txn) async {
      // Récupère les aliments du repas pour mettre à jour le stock
      final List<Map<String, dynamic>> alimentsRows = await txn.query(
        'repas_aliments',
        where: 'repasId = ?',
        whereArgs: [id],
      );

      // Restitue les quantités au stock
      for (var row in alimentsRows) {
        await _alimentService.updateStock(
          row['alimentId'],
          row['quantite'],
          txn,
        );
      }

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