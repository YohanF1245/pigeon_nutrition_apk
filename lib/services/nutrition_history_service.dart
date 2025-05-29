import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import 'database_service.dart';

class NutritionHistoryService {
  final DatabaseService _databaseService;
  final Logger _logger = Logger('NutritionHistoryService');

  NutritionHistoryService(this._databaseService);

  Future<List<Map<String, dynamic>>> getNutritionHistory({int days = 7}) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();
      var startDate = now.subtract(Duration(days: days - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);

      _logger.info('Récupération des données nutritionnelles du ${startDate.toIso8601String()} au ${now.toIso8601String()}');

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT 
          jr.date as date,
          SUM(a.calories * ra.quantite / 100.0) as calories,
          SUM(a.proteines * ra.quantite / 100.0) as proteines,
          SUM(a.lipides * ra.quantite / 100.0) as lipides,
          SUM(a.glucides * ra.quantite / 100.0) as glucides
        FROM jours_repas jr
        JOIN repas r ON r.id = jr.repasId
        JOIN repas_aliments ra ON ra.repasId = r.id
        JOIN aliments a ON a.id = ra.alimentId
        WHERE jr.date >= ?
        GROUP BY jr.date
        ORDER BY jr.date ASC
      ''', [startDate.toIso8601String()]);

      _logger.info('Données brutes récupérées : $results');

      // Remplir les jours manquants avec des valeurs à 0
      final List<Map<String, dynamic>> completeHistory = [];
      
      // Générer toutes les dates de l'intervalle
      final List<DateTime> dates = [];
      var currentDate = startDate;
      final endDate = DateTime(now.year, now.month, now.day);
      
      while (!currentDate.isAfter(endDate)) {
        dates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Remplir l'historique
      for (var date in dates) {
        final dateStr = date.toIso8601String().split('T')[0];
        final existingData = results.firstWhere(
          (element) => element['date'].toString().split('T')[0] == dateStr,
          orElse: () => {
            'date': dateStr,
            'calories': 0.0,
            'proteines': 0.0,
            'lipides': 0.0,
            'glucides': 0.0,
          },
        );
        
        // S'assurer que toutes les valeurs sont des doubles
        final Map<String, dynamic> normalizedData = {
          'date': dateStr,
          'calories': (existingData['calories'] ?? 0).toDouble(),
          'proteines': (existingData['proteines'] ?? 0).toDouble(),
          'lipides': (existingData['lipides'] ?? 0).toDouble(),
          'glucides': (existingData['glucides'] ?? 0).toDouble(),
        };
        
        completeHistory.add(normalizedData);
      }

      _logger.info('Historique complet généré : $completeHistory');
      return completeHistory;
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de la récupération de l\'historique nutritionnel', e, stackTrace);
      return [];
    }
  }
} 