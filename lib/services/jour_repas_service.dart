import 'package:sqflite/sqflite.dart';
import '../models/jour_repas.dart';
import 'database_service.dart';
import 'package:logging/logging.dart';

class JourRepasService {
  static final JourRepasService _instance = JourRepasService._internal();
  final _logger = Logger('JourRepasService');
  final _databaseService = DatabaseService();

  factory JourRepasService() {
    return _instance;
  }

  JourRepasService._internal();

  Future<void> initialiserTable() async {
    final db = await _databaseService.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS jours_repas (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        repasId TEXT NOT NULL,
        heure INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        FOREIGN KEY (repasId) REFERENCES repas (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> sauvegarderJourRepas(JourRepas jourRepas) async {
    final db = await _databaseService.database;
    
    await db.insert(
      'jours_repas',
      jourRepas.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _logger.info('JourRepas sauvegardé: ${jourRepas.id}');
  }

  Future<List<JourRepas>> getJoursRepas({DateTime? date}) async {
    final db = await _databaseService.database;
    
    String whereClause = '';
    List<String> whereArgs = [];
    
    if (date != null) {
      final debut = DateTime(date.year, date.month, date.day);
      final fin = debut.add(const Duration(days: 1));
      whereClause = 'date BETWEEN ? AND ?';
      whereArgs = [debut.toIso8601String(), fin.toIso8601String()];
    }

    final List<Map<String, dynamic>> rows = await db.query(
      'jours_repas',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    return rows.map((row) => JourRepas.fromMap(row)).toList();
  }

  Future<void> supprimerJourRepas(String id) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'jours_repas',
      where: 'id = ?',
      whereArgs: [id],
    );

    _logger.info('JourRepas supprimé: $id');
  }

  Future<void> supprimerJoursRepasParRepasId(String repasId) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'jours_repas',
      where: 'repasId = ?',
      whereArgs: [repasId],
    );

    _logger.info('JoursRepas supprimés pour le repas: $repasId');
  }
} 