import 'package:sqflite/sqflite.dart';
import '../models/aliment.dart';
import 'database_service.dart';
import 'package:logging/logging.dart';

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

  Future<void> deleteAliment(String id) async {
    await _databaseService.deleteAliment(id);
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
        nouvelleQuantite = aliment.quantiteStock + quantite;
      } else {
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
} 