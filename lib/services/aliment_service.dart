import 'package:sqflite/sqflite.dart';
import '../models/aliment.dart';
import 'database_service.dart';
import 'package:logging/logging.dart';
import '../models/repas.dart';
import 'dart:convert';

class AlimentService {
  final _databaseService = DatabaseService();
  static final _logger = Logger('AlimentService');

  Future<void> insertAliment(Aliment aliment) async {
    await _databaseService.insertAliment(aliment);
  }

  Future<void> addAliment(Aliment aliment) => insertAliment(aliment);

  Future<List<Aliment>> getAliments() async {
    return await _databaseService.getAliments();
  }

  Future<List<Aliment>> getAllAliments() => getAliments();

  Future<void> updateAliment(Aliment aliment) async {
    await _databaseService.updateAliment(aliment);
  }

  Future<void> deleteAliment(String alimentId) async {
    try {
      final db = await _databaseService.database;
      
      // Récupérer d'abord les repas qui utilisent cet aliment
      final repasAffectes = await getRepasUtilisantAliment(alimentId);
      
      await db.transaction((txn) async {
        // Pour chaque repas affecté
        for (var repas in repasAffectes) {
          // Supprimer d'abord les jours_repas associés
          await txn.delete(
            'jours_repas',
            where: 'repasId = ?',
            whereArgs: [repas.id],
          );
          
          // Supprimer ensuite le repas et ses associations
          await txn.delete(
            'repas_aliments',
            where: 'repasId = ?',
            whereArgs: [repas.id],
          );
          
          await txn.delete(
            'repas',
            where: 'id = ?',
            whereArgs: [repas.id],
          );
        }
        
        // Enfin, supprimer l'aliment
        await txn.delete(
          'aliments',
          where: 'id = ?',
          whereArgs: [alimentId],
        );
      });
      
      _logger.info('Aliment et repas associés supprimés avec succès');
    } catch (e) {
      _logger.severe('Erreur lors de la suppression de l\'aliment: $e');
      rethrow;
    }
  }

  Future<void> ajusterStock(String id, double quantite) async {
    try {
      _logger.info('Ajustement du stock pour l\'aliment $id de $quantite');
      final db = await _databaseService.database;
      
      // Récupérer l'aliment actuel
      final List<Map<String, dynamic>> maps = await db.query(
        'aliments',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        throw Exception('Aliment non trouvé');
      }
      
      final aliment = Aliment.fromMap(maps.first);
      double nouvelleQuantite;
      
      // Si l'aliment a une unité de portion, ajuster en fonction du poids unitaire
      if (aliment.unitePortionLabel != null && aliment.poidsUnitaire != null) {
        // Pour les aliments gérés par portions, la quantité représente le nombre de portions
        nouvelleQuantite = aliment.quantiteStock + quantite;
      } else {
        // Pour les aliments gérés en grammes/ml, ajout direct
        nouvelleQuantite = aliment.quantiteStock + quantite;
      }
      
      if (nouvelleQuantite < 0) {
        throw Exception('Le stock ne peut pas être négatif');
      }
      
      // Mettre à jour directement dans la base de données
      await db.update(
        'aliments',
        {'quantiteStock': nouvelleQuantite},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      _logger.info('Stock ajusté avec succès. Nouveau stock: $nouvelleQuantite');
    } catch (e) {
      _logger.severe('Erreur lors de l\'ajustement du stock: $e');
      rethrow;
    }
  }

  Future<List<Aliment>> getAlimentsEnRupture() async {
    final aliments = await getAliments();
    return aliments.where((aliment) => 
      aliment.gestionStock && 
      aliment.seuilAlerte != null && 
      aliment.quantiteStock <= aliment.seuilAlerte!
    ).toList();
  }

  Future<List<Map<String, dynamic>>> getListeCourses() async {
    try {
      _logger.info('Récupération de la liste des courses...');
      final aliments = await getAlimentsEnRupture();
      
      return aliments.map((aliment) {
        final quantiteAchatParDefaut = aliment.quantiteAchatParDefaut;
        final prixUnitaire = aliment.prixUnitaire;
        final coutEstime = (quantiteAchatParDefaut * prixUnitaire).toStringAsFixed(2);
        
        return {
          'id': aliment.id,
          'nom': aliment.nom,
          'quantiteStock': aliment.quantiteStock.toStringAsFixed(2),
          'seuilAlerte': aliment.seuilAlerte?.toStringAsFixed(2) ?? '0.00',
          'quantiteAcheter': quantiteAchatParDefaut.toStringAsFixed(2),
          'unite': aliment.unite.symbole,
          'unitePortionLabel': aliment.unitePortionLabel,
          'coutEstime': coutEstime,
          'devise': aliment.devise,
        };
      }).toList();
    } catch (e) {
      _logger.severe('Erreur lors de la récupération de la liste des courses: $e');
      rethrow;
    }
  }

  Future<void> updateStock(String alimentId, double quantite, Transaction? transaction) async {
    try {
      final db = transaction ?? await _databaseService.database;
      
      // Récupérer d'abord l'aliment pour vérifier s'il est géré par portions
      final List<Map<String, dynamic>> maps = await db.query(
        'aliments',
        where: 'id = ?',
        whereArgs: [alimentId],
      );
      
      if (maps.isEmpty) {
        throw Exception('Aliment non trouvé');
      }
      
      final aliment = Aliment.fromMap(maps.first);
      double quantiteAjustee = quantite;
      
      // Si l'aliment est géré par portions, convertir la quantité en grammes en nombre de portions
      if (aliment.unitePortionLabel != null && aliment.poidsUnitaire != null && aliment.poidsUnitaire! > 0) {
        quantiteAjustee = quantite / aliment.poidsUnitaire!;
      }

      final query = '''
        UPDATE aliments 
        SET quantiteStock = quantiteStock + ? 
        WHERE id = ? AND gestionStock = 1
      ''';

      if (transaction != null) {
        await transaction.rawUpdate(query, [quantiteAjustee, alimentId]);
      } else {
        await db.rawUpdate(query, [quantiteAjustee, alimentId]);
      }

      _logger.info('Stock mis à jour pour l\'aliment $alimentId: $quantiteAjustee');
    } catch (e) {
      _logger.severe('Erreur lors de la mise à jour du stock: $e');
      rethrow;
    }
  }

  Future<List<Repas>> getRepasUtilisantAliment(String alimentId) async {
    final db = await DatabaseService().database;
    final repasAliments = await db.query(
      'repas_aliments',
      where: 'alimentId = ?',
      whereArgs: [alimentId],
    );

    if (repasAliments.isEmpty) {
      return [];
    }

    final repasIds = repasAliments.map((ra) => ra['repasId'] as String).toSet();
    final repas = await db.query(
      'repas',
      where: 'id IN (${List.filled(repasIds.length, '?').join(',')})',
      whereArgs: repasIds.toList(),
    );

    final List<Repas> resultat = [];
    
    for (var repasRow in repas) {
      // Récupérer tous les aliments pour ce repas
      final alimentsRows = await db.query(
        'repas_aliments',
        where: 'repasId = ?',
        whereArgs: [repasRow['id'] as String],
      );

      final aliments = alimentsRows.map((row) => RepasAliment(
        alimentId: row['alimentId'] as String,
        quantite: (row['quantite'] as num).toDouble(),
      )).toList();

      resultat.add(Repas(
        id: repasRow['id'] as String,
        nom: repasRow['nom'] as String,
        aliments: aliments,
        nutrimentsCaches: repasRow['nutrimentsCaches'] != null
            ? Map<String, double>.from(
                Map<String, dynamic>.from(
                  jsonDecode(repasRow['nutrimentsCaches'] as String),
                ),
              )
            : null,
        createdAt: repasRow['createdAt'] != null
            ? DateTime.parse(repasRow['createdAt'] as String)
            : null,
      ));
    }

    return resultat;
  }
} 