import 'package:sqflite/sqflite.dart';
import '../models/jour_repas.dart';
import 'database_service.dart';
import 'package:logging/logging.dart';
import '../models/repas.dart';
import '../models/aliment.dart';
import 'repas_service.dart';
import 'aliment_service.dart';

class JourRepasService {
  static final JourRepasService _instance = JourRepasService._internal();
  final _logger = Logger('JourRepasService');
  final _databaseService = DatabaseService();
  final _repasService = RepasService();
  final _alimentService = AlimentService();

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

  Future<Map<String, double>> verifierStockDisponible(String repasId) async {
    final repas = (await _repasService.getRepas())
        .firstWhere((r) => r.id == repasId);
    
    final aliments = await _alimentService.getAllAliments();
    final Map<String, double> stockManquant = {};
    
    for (var repasAliment in repas.aliments) {
      final aliment = aliments.firstWhere((a) => a.id == repasAliment.alimentId);
      
      if (aliment.gestionStock) {
        double quantiteNecessaire;
        if (aliment.unitePortionLabel != null && aliment.poidsUnitaire != null) {
          quantiteNecessaire = repasAliment.quantite / aliment.poidsUnitaire!;
        } else {
          quantiteNecessaire = repasAliment.quantite;
        }
        
        if (aliment.quantiteStock < quantiteNecessaire) {
          stockManquant[aliment.nom] = quantiteNecessaire - aliment.quantiteStock;
        }
      }
    }
    
    return stockManquant;
  }

  Future<void> sauvegarderJourRepas(JourRepas jourRepas) async {
    final db = await _databaseService.database;
    
    // Récupérer les données nécessaires avant la transaction
    final repas = (await _repasService.getRepas())
        .firstWhere((r) => r.id == jourRepas.repasId);
    final aliments = await _alimentService.getAllAliments();
    
    // Vérifier le stock disponible
    final stockManquant = await verifierStockDisponible(jourRepas.repasId);
    if (stockManquant.isNotEmpty) {
      final message = stockManquant.entries
          .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
          .join(', ');
      throw Exception('Stock insuffisant pour les aliments suivants : $message');
    }

    // Préparer les mises à jour de stock
    final stockUpdates = <String, double>{};
    for (var repasAliment in repas.aliments) {
      final aliment = aliments.firstWhere((a) => a.id == repasAliment.alimentId);
      if (aliment.gestionStock) {
        if (aliment.unitePortionLabel != null && aliment.poidsUnitaire != null) {
          final portions = repasAliment.quantite / aliment.poidsUnitaire!;
          stockUpdates[aliment.id] = -portions;
        } else {
          stockUpdates[aliment.id] = -repasAliment.quantite;
        }
      }
    }
    
    // Exécuter toutes les opérations dans une seule transaction optimisée
    await db.transaction((txn) async {
      // 1. Mettre à jour le stock de tous les aliments en une seule requête
      if (stockUpdates.isNotEmpty) {
        final batch = txn.batch();
        for (var entry in stockUpdates.entries) {
          batch.rawUpdate(
            'UPDATE aliments SET quantiteStock = quantiteStock + ? WHERE id = ? AND gestionStock = 1',
            [entry.value, entry.key]
          );
        }
        await batch.commit(noResult: true);
      }
      
      // 2. Sauvegarder le jour_repas
      await txn.insert(
        'jours_repas',
        jourRepas.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

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
    
    // Récupérer les données nécessaires avant la transaction
    final List<Map<String, dynamic>> jourRepasRows = await db.query(
      'jours_repas',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (jourRepasRows.isEmpty) {
      _logger.warning('JourRepas non trouvé: $id');
      return;
    }
    
    final jourRepas = JourRepas.fromMap(jourRepasRows.first);
    final repas = (await _repasService.getRepas())
        .firstWhere((r) => r.id == jourRepas.repasId);
    final aliments = await _alimentService.getAllAliments();
    
    // Préparer les mises à jour de stock
    final stockUpdates = <String, double>{};
    for (var repasAliment in repas.aliments) {
      final aliment = aliments.firstWhere((a) => a.id == repasAliment.alimentId);
      if (aliment.gestionStock) {
        if (aliment.unitePortionLabel != null && aliment.poidsUnitaire != null) {
          final portions = repasAliment.quantite / aliment.poidsUnitaire!;
          stockUpdates[aliment.id] = portions;
        } else {
          stockUpdates[aliment.id] = repasAliment.quantite;
        }
      }
    }
    
    // Exécuter toutes les opérations dans une seule transaction optimisée
    await db.transaction((txn) async {
      // 1. Mettre à jour le stock de tous les aliments en une seule requête
      if (stockUpdates.isNotEmpty) {
        final batch = txn.batch();
        for (var entry in stockUpdates.entries) {
          batch.rawUpdate(
            'UPDATE aliments SET quantiteStock = quantiteStock + ? WHERE id = ? AND gestionStock = 1',
            [entry.value, entry.key]
          );
        }
        await batch.commit(noResult: true);
      }
      
      // 2. Supprimer le jour_repas
      await txn.delete(
        'jours_repas',
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    _logger.info('JourRepas supprimé: $id');
  }

  Future<void> supprimerJoursRepasParRepasId(String repasId) async {
    final db = await _databaseService.database;
    
    await db.transaction((txn) async {
      // Récupérer tous les jours_repas associés à ce repas
      final List<Map<String, dynamic>> joursRepasRows = await txn.query(
        'jours_repas',
        where: 'repasId = ?',
        whereArgs: [repasId],
      );
      
      if (joursRepasRows.isEmpty) {
        _logger.info('Aucun JourRepas trouvé pour le repas: $repasId');
        return;
      }
      
      // Récupérer le repas et ses aliments
      final repas = (await _repasService.getRepas())
          .firstWhere((r) => r.id == repasId);
      
      final aliments = await _alimentService.getAllAliments();
      
      // Pour chaque jour_repas, réincrémenter le stock des aliments
      for (var jourRepasRow in joursRepasRows) {
        for (var repasAliment in repas.aliments) {
          final aliment = aliments.firstWhere((a) => a.id == repasAliment.alimentId);
          
          if (aliment.gestionStock) {
            // Si l'aliment est géré par portions et a un poids unitaire
            if (aliment.unitePortionLabel != null && aliment.poidsUnitaire != null) {
              final portions = repasAliment.quantite / aliment.poidsUnitaire!;
              await _alimentService.updateStock(aliment.id, portions, txn);
            } else {
              // Sinon, réincrémenter directement la quantité en grammes/ml
              await _alimentService.updateStock(aliment.id, repasAliment.quantite, txn);
            }
          }
        }
      }
      
      // Supprimer tous les jours_repas
      await txn.delete(
        'jours_repas',
        where: 'repasId = ?',
        whereArgs: [repasId],
      );
    });

    _logger.info('JoursRepas supprimés pour le repas: $repasId');
  }
} 